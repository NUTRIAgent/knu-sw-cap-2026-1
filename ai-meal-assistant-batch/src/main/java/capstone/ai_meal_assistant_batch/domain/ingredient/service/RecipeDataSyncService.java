package capstone.ai_meal_assistant_batch.domain.ingredient.service;

import capstone.ai_meal_assistant_batch.domain.etl.FoodSafetyApiFetcher;
import capstone.ai_meal_assistant_batch.domain.etl.parser.RecipeDataParser;
import capstone.ai_meal_assistant_batch.domain.ingredient.dto.IngredientDto;
import capstone.ai_meal_assistant_batch.domain.ingredient.entity.Ingredient;
import capstone.ai_meal_assistant_batch.domain.ingredient.repository.IngredientRepository;
import capstone.ai_meal_assistant_batch.domain.menu.entity.Allergy;
import capstone.ai_meal_assistant_batch.domain.menu.entity.Menu;
import capstone.ai_meal_assistant_batch.domain.menu.entity.MenuAllergy;
import capstone.ai_meal_assistant_batch.domain.menu.entity.MenuIngredient;
import capstone.ai_meal_assistant_batch.domain.menu.entity.MenuStep;
import capstone.ai_meal_assistant_batch.domain.menu.repository.AllergyRepository;
import capstone.ai_meal_assistant_batch.domain.menu.repository.MenuAllergyRepository;
import capstone.ai_meal_assistant_batch.domain.menu.repository.MenuIngredientRepository;
import capstone.ai_meal_assistant_batch.domain.menu.repository.MenuRepository;
import capstone.ai_meal_assistant_batch.domain.menu.repository.MenuStepRepository;
import capstone.ai_meal_assistant_batch.global.s3.S3ImageUploadService;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class RecipeDataSyncService {

    private final FoodSafetyApiFetcher apiFetcher;
    private final MenuRepository menuRepository;
    private final IngredientRepository ingredientRepository;
    private final MenuIngredientRepository menuIngredientRepository;
    private final MenuStepRepository menuStepRepository;
    private final AllergyRepository allergyRepository;
    private final MenuAllergyRepository menuAllergyRepository;
    private final ObjectMapper objectMapper;
    private final S3ImageUploadService s3ImageUploadService;

    /** 이미지 복구 시 변경분을 끊어 저장하는 청크 크기. */
    private static final int RECOVERY_SAVE_CHUNK = 100;

    @Transactional
    public void syncAllDataFromApi(){
        try{
            // 1. 로컬에 저장한 정제된 JSON 파일을 읽어옵니다.
            ClassPathResource resource = new ClassPathResource("cleaned_recipe_data.json");
            String rawJson = new String(Files.readAllBytes(Paths.get(resource.getURI())), StandardCharsets.UTF_8);

            JsonNode rootNode = objectMapper.readTree(rawJson);
            JsonNode recipeArray = rootNode.isArray() ? rootNode : rootNode.path("COOKRCP01").path("row");

            // 이전에 잘못 삽입된 '후식' 데이터 정리 (멱등 보장)
            List<Menu> dessertMenus = menuRepository.findAllByCategory("후식");
            if (!dessertMenus.isEmpty()) {
                menuRepository.deleteAll(dessertMenus); // CascadeType.ALL → menu_ingredients 자동 삭제
                log.info("기존 '후식' 메뉴 {}개 및 연관 재료 삭제", dessertMenus.size());
            }

            // [캐시 준비] DB에 있는 데이터들을 메모리로 한 번에 다 가져옵니다. (SELECT 딱 2번 발생!)
            Map<String, Ingredient> ingredientCache = ingredientRepository.findAll().stream()
                    .collect(Collectors.toMap(Ingredient::getName, i -> i));

            Map<String, Menu> menuCache = menuRepository.findAll().stream()
                    .collect(Collectors.toMap(Menu::getFoodCode, m -> m));


            // =========================================================================
            // STEP 1: [메뉴 추출 및 Bulk Insert]
            // =========================================================================
            List<Menu> newMenusToSave = new ArrayList<>();

            for (JsonNode recipeNode : recipeArray) {
                if ("후식".equals(recipeNode.path("RCP_PAT2").asText())) continue;

                String foodCode = recipeNode.path("RCP_SEQ").asText();  // 일련번호

                // 캐시에 없는 새로운 레시피만 골라냅니다.
                if (!menuCache.containsKey(foodCode)) {
                    String originalImageUrl = recipeNode.path("ATT_FILE_NO_MAIN").asText();
                    String mainImageUrl = s3ImageUploadService.uploadFromUrl(originalImageUrl);

                    Menu newMenu = Menu.builder()
                            .foodCode(foodCode)                                                // 일련번호
                            .name(recipeNode.path("RCP_NM").asText())                       // 메뉴명
                            .category(recipeNode.path("RCP_PAT2").asText())                 // 카테고리
                            .cookingMethod(recipeNode.path("RCP_WAY2").asText())            // 조리법
                            .mainImageUrl(mainImageUrl)                                      // S3 업로드 후 URL (실패 시 원본)
                            .healthTip(recipeNode.path("RCP_NA_TIP").asText())              // 팁
                            .calories(parseDoubleSafe(recipeNode.path("INFO_ENG").asText()))// 열량
                            .protein(parseDoubleSafe(recipeNode.path("INFO_PRO").asText())) // 단백질
                            .fat(parseDoubleSafe(recipeNode.path("INFO_FAT").asText()))     // 지방
                            .carbs(parseDoubleSafe(recipeNode.path("INFO_CAR").asText()))   // 탄수화물
                            .sodium(parseDoubleSafe(recipeNode.path("INFO_NA").asText()))   // 나트륨
                            .build();

                    newMenusToSave.add(newMenu);
                    menuCache.put(foodCode, newMenu); // 중복 추가 방지를 위해 임시로 캐시에 꽂아둡니다.
                }
            }

            // 새로운 메뉴들을 한 방에 DB에 꽂아넣고, 영속화(ID가 발급된) 상태로 캐시를 최신화합니다.
            if (!newMenusToSave.isEmpty()) {
                List<Menu> savedMenus = menuRepository.saveAll(newMenusToSave);
                for (Menu savedMenu : savedMenus) {
                    menuCache.put(savedMenu.getFoodCode(), savedMenu);
                }
                log.info("새로운 메뉴 {}개 Bulk Insert 완료!", savedMenus.size());
            }


            // =========================================================================
            // STEP 2: [식재료 파싱 및 매핑 테이블 Bulk Insert]
            // 기존 menu_ingredients 삭제 후 재삽입해 멱등성 보장
            // =========================================================================
            Set<Long> step2MenuIds = menuCache.values().stream()
                    .filter(m -> m.getId() != null)
                    .map(Menu::getId)
                    .collect(Collectors.toSet());
            if (!step2MenuIds.isEmpty()) {
                menuIngredientRepository.deleteAllByMenuIds(step2MenuIds);
                log.info("[STEP 2] 기존 menu_ingredients 삭제 완료 ({}개 메뉴)", step2MenuIds.size());
            }

            List<MenuIngredient> menuIngredientsToSave = new ArrayList<>();

            for (JsonNode recipeNode : recipeArray) {
                if ("후식".equals(recipeNode.path("RCP_PAT2").asText())) continue;

                String foodCode = recipeNode.path("RCP_SEQ").asText();
                String recipeName = recipeNode.path("RCP_NM").asText();
                String partsDetails = recipeNode.path("RCP_PARTS_DTLS").asText();

                // DB 조회 없이 캐시(메모리)에서 메뉴 엔티티를 즉시 꺼내옵니다. (초고속!)
                Menu menu = menuCache.get(foodCode);

                // 파서로 문자열 분리
                List<IngredientDto> dtoList = RecipeDataParser.parseIngredients(partsDetails, recipeName);

                for (IngredientDto dto : dtoList) {
                    String ingName = dto.getName();

                    // 캐시에서 재료 확인
                    Ingredient ingredient = ingredientCache.get(ingName);

                    // 새로운 재료라면 즉시 저장하고 캐시에 추가
                    if (ingredient == null) {
                        ingredient = Ingredient.builder().name(ingName).build();
                        ingredient = ingredientRepository.save(ingredient);
                        ingredientCache.put(ingName, ingredient);
                    }

                    // 매핑 데이터를 모아둡니다.
                    menuIngredientsToSave.add(MenuIngredient.builder()
                            .menu(menu)
                            .ingredient(ingredient)
                            .subCategory(dto.getSubCategory())
                            .requiredWeight(dto.getParsedWeight())
                            .amountText(dto.getOriginalAmount())
                            .build());
                }
            }

            // 모든 매핑 데이터를 한 방에 DB에 꽂아 넣습니다!
            menuIngredientRepository.saveAll(menuIngredientsToSave);

            log.info("데이터 동기화 완전 성공! 총 저장된 식재료 매핑 수: {}", menuIngredientsToSave.size());


            // =========================================================================
            // STEP 3: [조리단계 파싱 및 저장]
            // 식약처 API MANUAL01~MANUAL20 / MANUAL_IMG01~MANUAL_IMG20 필드 저장
            // 기존 steps를 먼저 삭제하고 재삽입해 멱등성 보장
            // =========================================================================
            Set<Long> batchMenuIds = new HashSet<>();
            for (JsonNode recipeNode : recipeArray) {
                if ("후식".equals(recipeNode.path("RCP_PAT2").asText())) continue;
                Menu cachedMenu = menuCache.get(recipeNode.path("RCP_SEQ").asText());
                if (cachedMenu != null && cachedMenu.getId() != null) {
                    batchMenuIds.add(cachedMenu.getId());
                }
            }
            if (!batchMenuIds.isEmpty()) {
                menuStepRepository.deleteAllByMenuIds(batchMenuIds);
            }

            List<MenuStep> menuStepsToSave = new ArrayList<>();

            for (JsonNode recipeNode : recipeArray) {
                if ("후식".equals(recipeNode.path("RCP_PAT2").asText())) continue;

                String stepFoodCode = recipeNode.path("RCP_SEQ").asText();
                Menu stepMenu = menuCache.get(stepFoodCode);
                if (stepMenu == null) continue;

                int stepOrder = 0;
                for (int fieldNo = 1; fieldNo <= 20; fieldNo++) {
                    String content = recipeNode.path(String.format("MANUAL%02d", fieldNo)).asText("").trim();
                    if (content.isEmpty()) continue;

                    stepOrder++;
                    String imageUrl = recipeNode.path(String.format("MANUAL_IMG%02d", fieldNo)).asText("").trim();
                    menuStepsToSave.add(MenuStep.builder()
                            .menu(stepMenu)
                            .stepOrder(stepOrder)
                            .description(content)
                            .imageUrl(imageUrl.isEmpty() ? null : imageUrl)
                            .build());
                }
            }

            menuStepRepository.saveAll(menuStepsToSave);
            log.info("[STEP 3] 조리단계 저장 완료: {}건", menuStepsToSave.size());


            // =========================================================================
            // STEP 4: [기존 메뉴 이미지 S3 마이그레이션]
            // 원본 URL(foodsafetykorea)을 가진 기존 메뉴를 S3 URL로 업데이트합니다.
            // =========================================================================
            List<Menu> menusToMigrate = menuRepository.findAll().stream()
                    .filter(m -> m.getMainImageUrl() != null
                            && !m.getMainImageUrl().isBlank()
                            && !s3ImageUploadService.isOurStorageUrl(m.getMainImageUrl()))
                    .collect(Collectors.toList());

            if (!menusToMigrate.isEmpty()) {
                log.info("S3 마이그레이션 대상 메뉴: {}개", menusToMigrate.size());
                int successCount = 0;
                for (Menu menu : menusToMigrate) {
                    String newUrl = s3ImageUploadService.uploadFromUrl(menu.getMainImageUrl());
                    if (s3ImageUploadService.isOurStorageUrl(newUrl)) {
                        menu.updateMainImageUrl(newUrl);
                        successCount++;
                    }
                }
                menuRepository.saveAll(menusToMigrate);
                log.info("S3 마이그레이션 완료: {}개 성공 / {}개 대상", successCount, menusToMigrate.size());
            } else {
                log.info("S3 마이그레이션 대상 없음 (이미 모두 스토리지 URL)");
            }

        } catch (Exception e){
            log.error("API 데이터 동기화 중 에러 발생: ", e);
        }
    }

    /**
     * 메뉴 이미지 URL을 점검·정리한다.
     * - amazonaws.com URL인 메뉴를 대상으로:
     *   - S3 객체가 정상이면 URL을 CloudFront(또는 설정된 도메인)로 단순 치환.
     *   - S3 객체가 손상이면 cleaned_recipe_data.json의 원본 URL로 재업로드.
     * - 멱등하고 반복 호출 가능.
     *
     * <p>메뉴 수만큼 네트워크 I/O(S3 HEAD/PUT, 원본 이미지 다운로드)를 수행하므로
     * 메서드 전체를 하나의 트랜잭션으로 묶지 않는다 — 그러면 DB 커넥션을 수십 분간
     * 점유해 HikariCP 고갈/트랜잭션 타임아웃을 유발한다. 변경분은
     * {@link #RECOVERY_SAVE_CHUNK}개 단위로 끊어 각자의 짧은 트랜잭션으로 저장한다.
     */
    public void recoverCorruptedImages() {
        log.info("[복구] 이미지 URL 점검/복구 시작");

        Map<String, String> codeToOriginalUrl;
        try {
            codeToOriginalUrl = loadOriginalImageUrlMap();
        } catch (Exception e) {
            log.error("[복구] cleaned_recipe_data.json 로드 실패", e);
            return;
        }
        log.info("[복구] 원본 URL 맵 로드 완료: {}건", codeToOriginalUrl.size());

        // 우리 스토리지(S3 직링크 + CloudFront 도메인)에 올라간 메뉴를 모두 검사 대상으로.
        // amazonaws.com 만 보면 CloudFront 전환 이후 후보가 0개가 되어 재검증이 불가능하다.
        List<Menu> candidates = menuRepository.findAll().stream()
                .filter(m -> s3ImageUploadService.isOurStorageUrl(m.getMainImageUrl()))
                .collect(Collectors.toList());
        log.info("[복구] 검사 대상(S3/CloudFront URL) 메뉴: {}개", candidates.size());

        int normalized = 0, corrupt = 0, recovered = 0, missingOrigin = 0, failed = 0;
        List<Menu> buffer = new ArrayList<>();
        for (Menu menu : candidates) {
            if (s3ImageUploadService.isS3UrlValid(menu.getMainImageUrl())) {
                String cfUrl = s3ImageUploadService.toCloudFrontUrl(menu.getMainImageUrl());
                if (!cfUrl.equals(menu.getMainImageUrl())) {
                    menu.updateMainImageUrl(cfUrl);
                    buffer.add(menu);
                    normalized++;
                }
                flushIfFull(buffer);
                continue;
            }
            corrupt++;

            String originalUrl = codeToOriginalUrl.get(menu.getFoodCode());
            if (originalUrl == null || originalUrl.isBlank()) {
                log.warn("[복구] 원본 URL 없음, 스킵: foodCode={}, name={}", menu.getFoodCode(), menu.getName());
                missingOrigin++;
                continue;
            }

            String newUrl = s3ImageUploadService.uploadFromUrl(originalUrl);
            if (s3ImageUploadService.isOurStorageUrl(newUrl)) {
                menu.updateMainImageUrl(newUrl);
                buffer.add(menu);
                recovered++;
            } else {
                log.warn("[복구] 재업로드 실패: foodCode={}, originalUrl={}", menu.getFoodCode(), originalUrl);
                failed++;
            }
            flushIfFull(buffer);
        }

        if (!buffer.isEmpty()) {
            menuRepository.saveAll(buffer);
        }
        log.info("[복구] 완료 — URL변경={}, 손상={}, 복구성공={}, 원본URL없음={}, 재업로드실패={}",
                normalized, corrupt, recovered, missingOrigin, failed);
    }

    /** 변경 버퍼가 청크 크기에 도달하면 즉시 저장(각자 짧은 트랜잭션)해 커넥션·메모리 부담을 줄인다. */
    private void flushIfFull(List<Menu> buffer) {
        if (buffer.size() >= RECOVERY_SAVE_CHUNK) {
            menuRepository.saveAll(buffer);
            buffer.clear();
        }
    }

    private Map<String, String> loadOriginalImageUrlMap() throws Exception {
        ClassPathResource resource = new ClassPathResource("cleaned_recipe_data.json");
        String rawJson = new String(Files.readAllBytes(Paths.get(resource.getURI())), StandardCharsets.UTF_8);
        JsonNode rootNode = objectMapper.readTree(rawJson);
        JsonNode recipeArray = rootNode.isArray() ? rootNode : rootNode.path("COOKRCP01").path("row");

        Map<String, String> map = new HashMap<>();
        for (JsonNode recipeNode : recipeArray) {
            String foodCode = recipeNode.path("RCP_SEQ").asText();
            String url = recipeNode.path("ATT_FILE_NO_MAIN").asText();
            if (foodCode != null && !foodCode.isBlank() && url != null && !url.isBlank()) {
                map.put(foodCode, url);
            }
        }
        return map;
    }

    /**
     * 재료(menu_ingredients)만 단독으로 재적재한다.
     * 파싱 로직 수정 후 기존 데이터를 교정하거나, S3 업로드 없이 빠르게 재적재할 때 사용한다.
     * 기존 menu_ingredients를 삭제 후 재삽입해 멱등성을 보장한다.
     */
    @Transactional
    public void syncIngredientsOnly() {
        log.info("[STEP 2 단독] 재료 재적재 시작");
        try {
            ClassPathResource resource = new ClassPathResource("cleaned_recipe_data.json");
            String rawJson = new String(Files.readAllBytes(Paths.get(resource.getURI())), StandardCharsets.UTF_8);
            JsonNode rootNode = objectMapper.readTree(rawJson);
            JsonNode recipeArray = rootNode.isArray() ? rootNode : rootNode.path("COOKRCP01").path("row");

            Map<String, Menu> menuCache = menuRepository.findAll().stream()
                    .collect(Collectors.toMap(Menu::getFoodCode, m -> m));
            Map<String, Ingredient> ingredientCache = ingredientRepository.findAll().stream()
                    .collect(Collectors.toMap(Ingredient::getName, i -> i));

            Set<Long> menuIds = menuCache.values().stream()
                    .filter(m -> m.getId() != null)
                    .map(Menu::getId)
                    .collect(Collectors.toSet());
            if (!menuIds.isEmpty()) {
                menuIngredientRepository.deleteAllByMenuIds(menuIds);
                log.info("[STEP 2 단독] 기존 menu_ingredients 삭제 완료 ({}개 메뉴)", menuIds.size());
            }

            List<MenuIngredient> menuIngredientsToSave = new ArrayList<>();
            for (JsonNode recipeNode : recipeArray) {
                if ("후식".equals(recipeNode.path("RCP_PAT2").asText())) continue;

                String foodCode = recipeNode.path("RCP_SEQ").asText();
                String recipeName = recipeNode.path("RCP_NM").asText();
                String partsDetails = recipeNode.path("RCP_PARTS_DTLS").asText();
                Menu menu = menuCache.get(foodCode);
                if (menu == null) continue;

                List<IngredientDto> dtoList = RecipeDataParser.parseIngredients(partsDetails, recipeName);
                for (IngredientDto dto : dtoList) {
                    String ingName = dto.getName();
                    Ingredient ingredient = ingredientCache.get(ingName);
                    if (ingredient == null) {
                        ingredient = ingredientRepository.save(Ingredient.builder().name(ingName).build());
                        ingredientCache.put(ingName, ingredient);
                    }
                    menuIngredientsToSave.add(MenuIngredient.builder()
                            .menu(menu)
                            .ingredient(ingredient)
                            .subCategory(dto.getSubCategory())
                            .requiredWeight(dto.getParsedWeight())
                            .amountText(dto.getOriginalAmount())
                            .build());
                }
            }

            menuIngredientRepository.saveAll(menuIngredientsToSave);
            log.info("[STEP 2 단독] 재료 재적재 완료: {}건", menuIngredientsToSave.size());
        } catch (Exception e) {
            log.error("[STEP 2 단독] 재료 재적재 중 오류 발생", e);
            throw new RuntimeException(e);
        }
    }

    /**
     * 조리단계(menu_steps)만 단독으로 재적재한다.
     * syncAllDataFromApi()의 STEP 3과 동일한 로직이며, S3 업로드 없이 빠르게 실행 가능.
     * menu_steps가 비어 있거나 잘못 저장된 경우 단독으로 호출한다.
     */
    @Transactional
    public void syncStepsOnly() {
        log.info("[STEP 3 단독] 조리단계 적재 시작");
        try {
            ClassPathResource resource = new ClassPathResource("cleaned_recipe_data.json");
            String rawJson = new String(Files.readAllBytes(Paths.get(resource.getURI())), StandardCharsets.UTF_8);
            JsonNode rootNode = objectMapper.readTree(rawJson);
            JsonNode recipeArray = rootNode.isArray() ? rootNode : rootNode.path("COOKRCP01").path("row");

            Map<String, Menu> menuCache = menuRepository.findAll().stream()
                    .collect(Collectors.toMap(Menu::getFoodCode, m -> m));

            Set<Long> batchMenuIds = new HashSet<>();
            for (JsonNode recipeNode : recipeArray) {
                if ("후식".equals(recipeNode.path("RCP_PAT2").asText())) continue;
                Menu menu = menuCache.get(recipeNode.path("RCP_SEQ").asText());
                if (menu != null && menu.getId() != null) batchMenuIds.add(menu.getId());
            }
            if (!batchMenuIds.isEmpty()) {
                menuStepRepository.deleteAllByMenuIds(batchMenuIds);
                log.info("[STEP 3 단독] 기존 steps {}개 메뉴 분 삭제 완료", batchMenuIds.size());
            }

            List<MenuStep> menuStepsToSave = new ArrayList<>();
            for (JsonNode recipeNode : recipeArray) {
                if ("후식".equals(recipeNode.path("RCP_PAT2").asText())) continue;
                Menu menu = menuCache.get(recipeNode.path("RCP_SEQ").asText());
                if (menu == null) continue;

                int stepOrder = 0;
                for (int fieldNo = 1; fieldNo <= 20; fieldNo++) {
                    String content = recipeNode.path(String.format("MANUAL%02d", fieldNo)).asText("").trim();
                    if (content.isEmpty()) continue;
                    stepOrder++;
                    String imageUrl = recipeNode.path(String.format("MANUAL_IMG%02d", fieldNo)).asText("").trim();
                    menuStepsToSave.add(MenuStep.builder()
                            .menu(menu)
                            .stepOrder(stepOrder)
                            .description(content)
                            .imageUrl(imageUrl.isEmpty() ? null : imageUrl)
                            .build());
                }
            }

            menuStepRepository.saveAll(menuStepsToSave);
            log.info("[STEP 3 단독] 조리단계 적재 완료: {}건", menuStepsToSave.size());
        } catch (Exception e) {
            log.error("[STEP 3 단독] 조리단계 적재 중 오류 발생", e);
            throw new RuntimeException(e);
        }
    }

    /**
     * STEP 5: 메뉴-알레르기 자동 매핑
     * menu_ingredients 재료명 키워드 기반으로 menu_allergies 테이블을 채웁니다.
     * syncAllDataFromApi()와 독립 실행 가능 — menu_ingredients가 채워진 상태라면 언제든 호출 가능.
     * 멱등: 이미 존재하는 (menu_id, allergy_id) 쌍은 skip.
     */
    @Transactional
    public void syncAllergyMappings() {
        log.info("[STEP 5] 메뉴-알레르기 자동 매핑 시작");

        // 4-1. 키워드 → 알레르기명 맵
        Map<String, String> keywordToAllergy = buildKeywordToAllergyMap();

        // 4-0. 정리: menu_allergies 전체 삭제 후 새로 채움 (멱등 보장)
        // allergies 테이블은 user_allergies FK가 있어 배치에서 직접 삭제하지 않음
        menuAllergyRepository.deleteAll();
        log.info("[STEP 5] 기존 menu_allergies 전체 삭제 완료");

        // 4-2. allergies 테이블 seed: 없는 항목만 INSERT
        Map<String, Allergy> allergyCache = allergyRepository.findAll().stream()
                .collect(Collectors.toMap(Allergy::getName, a -> a));

        Set<String> requiredAllergyNames = new HashSet<>(keywordToAllergy.values());
        for (String allergyName : requiredAllergyNames) {
            allergyCache.computeIfAbsent(allergyName, name -> {
                Allergy newAllergy = Allergy.builder().name(name).build();
                return allergyRepository.save(newAllergy);
            });
        }
        log.info("[STEP 5] allergies 테이블: {}종 준비 완료", allergyCache.size());

        // 4-3. 기존 매핑 캐시 로드 (멱등 보장)
        Set<String> existingKeys = menuAllergyRepository.findAllKeys();

        // 4-4. menu_ingredients 전체 순회 → 키워드 매칭 → menu_allergies 생성
        List<MenuIngredient> allMenuIngredients = menuIngredientRepository.findAllWithMenuAndIngredient();
        if (allMenuIngredients.isEmpty()) {
            log.warn("[STEP 5] menu_ingredients 데이터 없음 — syncAllDataFromApi() 먼저 실행 필요");
            return;
        }

        List<MenuAllergy> menuAllergiesToSave = new ArrayList<>();
        for (MenuIngredient mi : allMenuIngredients) {
            String ingName = mi.getIngredient().getName();
            String allergyName = matchAllergy(ingName, keywordToAllergy);
            if (allergyName == null) continue;

            Allergy allergy = allergyCache.get(allergyName);
            if (allergy == null) continue;

            String key = mi.getMenu().getId() + "_" + allergy.getId();
            if (existingKeys.contains(key)) continue;

            menuAllergiesToSave.add(MenuAllergy.builder()
                    .menu(mi.getMenu())
                    .allergy(allergy)
                    .build());
            existingKeys.add(key); // 같은 배치 내 중복 방지
        }

        menuAllergyRepository.saveAll(menuAllergiesToSave);
        log.info("[STEP 5] 메뉴-알레르기 매핑 완료: {}건 INSERT (총 재료 {}건 처리)", menuAllergiesToSave.size(), allMenuIngredients.size());
    }

    /**
     * 재료명에서 알레르기 키워드 매칭 (포함 검사)
     * 예: "땅콩버터" → "땅콩" 키워드 포함 → "땅콩" 알레르기 반환
     */
    private String matchAllergy(String ingredientName, Map<String, String> keywordToAllergy) {
        for (Map.Entry<String, String> entry : keywordToAllergy.entrySet()) {
            if (ingredientName.contains(entry.getKey())) {
                return entry.getValue();
            }
        }
        return null;
    }

    /**
     * 키워드 → 알레르기명 매핑 테이블
     * 한국 식품위생법 알레르기 표시 의무 22종 기준
     */
    private Map<String, String> buildKeywordToAllergyMap() {
        Map<String, String> map = new HashMap<>();
        // 우유
        for (String kw : List.of("우유", "치즈", "버터", "크림", "요구르트", "요거트")) map.put(kw, "우유");
        // 계란
        for (String kw : List.of("계란", "달걀")) map.put(kw, "계란");
        // 밀가루
        for (String kw : List.of("밀가루", "빵가루", "글루텐")) map.put(kw, "밀가루");
        // 대두
        for (String kw : List.of("두부", "된장", "청국장", "두유")) map.put(kw, "대두");
        // 땅콩
        map.put("땅콩", "땅콩");
        // 견과류
        for (String kw : List.of("호두", "아몬드", "잣", "캐슈", "피스타치오", "마카다미아")) map.put(kw, "견과류");
        // 갑각류
        for (String kw : List.of("새우", "랍스터")) map.put(kw, "갑각류");
        // 게 (단독 키워드 — "게살", "꽃게" 등 포함)
        map.put("게", "갑각류");
        // 생선
        for (String kw : List.of("고등어", "연어", "참치", "명태", "대구", "멸치", "가자미", "조기", "갈치", "삼치")) map.put(kw, "생선");
        return map;
    }

//    공공데이터의 빈 문자열이나 이상한 값을 안전하게 0.0으로 변환해 주는 메서드
    private Double parseDoubleSafe(String value){
        if(value == null || value.trim().isEmpty()){
            return 0.0;
        }
        try{
            return Double.parseDouble(value);
        }
        catch (NumberFormatException e){
            log.warn("숫자 변환 실패. 기본값 0.0 처리 - 입력값: {}", value);
            return 0.0;
        }
    }
}