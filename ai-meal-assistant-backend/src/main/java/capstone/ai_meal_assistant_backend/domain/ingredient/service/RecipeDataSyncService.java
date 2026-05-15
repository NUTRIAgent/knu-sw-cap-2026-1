package capstone.ai_meal_assistant_backend.domain.ingredient.service;

import capstone.ai_meal_assistant_backend.domain.etl.FoodSafetyApiFetcher;
import capstone.ai_meal_assistant_backend.domain.etl.parser.RecipeDataParser;
import capstone.ai_meal_assistant_backend.domain.ingredient.dto.IngredientDto;
import capstone.ai_meal_assistant_backend.domain.ingredient.entity.Ingredient;
import capstone.ai_meal_assistant_backend.domain.ingredient.repository.IngredientRepository;
import capstone.ai_meal_assistant_backend.domain.menu.entity.Menu;
import capstone.ai_meal_assistant_backend.domain.menu.entity.MenuIngredient;
import capstone.ai_meal_assistant_backend.domain.menu.repository.MenuIngredientRepository;
import capstone.ai_meal_assistant_backend.domain.menu.repository.MenuRepository;
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
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class RecipeDataSyncService {

    private final FoodSafetyApiFetcher apiFetcher;
    private final MenuRepository menuRepository;
    private final IngredientRepository ingredientRepository;
    private final MenuIngredientRepository menuIngredientRepository;
    private final ObjectMapper objectMapper;

    @Transactional
    public void syncAllDataFromApi(){
        try{
            // 1. 로컬에 저장한 정제된 JSON 파일을 읽어옵니다.
            ClassPathResource resource = new ClassPathResource("cleaned_recipe_data.json");
            String rawJson = new String(Files.readAllBytes(Paths.get(resource.getURI())), StandardCharsets.UTF_8);

            JsonNode rootNode = objectMapper.readTree(rawJson);
            JsonNode recipeArray = rootNode.isArray() ? rootNode : rootNode.path("COOKRCP01").path("row");

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
                String foodCode = recipeNode.path("RCP_SEQ").asText();  // 일련번호

                // 캐시에 없는 새로운 레시피만 골라냅니다.
                if (!menuCache.containsKey(foodCode)) {
                    Menu newMenu = Menu.builder()
                            .foodCode(foodCode)                                                // 일련번호
                            .name(recipeNode.path("RCP_NM").asText())                       // 메뉴명
                            .category(recipeNode.path("RCP_PAT2").asText())                 // 카테고리
                            .cookingMethod(recipeNode.path("RCP_WAY2").asText())            // 조리법
                            .mainImageUrl(recipeNode.path("ATT_FILE_NO_MAIN").asText())     // 메인 이미지
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
            // =========================================================================
            List<MenuIngredient> menuIngredientsToSave = new ArrayList<>();

            for (JsonNode recipeNode : recipeArray) {
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

        } catch (Exception e){
            log.error("API 데이터 동기화 중 에러 발생: ", e);
        }
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