package capstone.ai_meal_assistant_backend.domain.history.service;

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
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class RecipeDataSyncService {

    private final FoodSafetyApiFetcher apiFetcher;    // api 가져오기
    private final MenuRepository menuRepository;    // 파싱 데이터 저장
    private final IngredientRepository ingredientRepository;    // 파싱 데이터 저장
    private final MenuIngredientRepository menuIngredientRepository;    // 파싱 데이터 저장
    private final ObjectMapper objectMapper;                    // JSON 파싱용 스프링 기본 객체


    @Transactional
    public void syncAllDataFromApi(){
        try{
//            [Extract] 식약처 API에서 JSON 문자열을 가져옴
            String rawJson = apiFetcher.fetchRecipeData();

//            [Transform - JSON] 문자열을 다루기 쉽게 JsonNode 트리로 바꿈
            JsonNode rootNode = objectMapper.readTree(rawJson);
            JsonNode recipeArray = rootNode.path("COOKRCP01").path("row");

//            배열을 돌면서 하나씩 처리
            for (JsonNode recipeNode : recipeArray) {
//                일련번호, 메뉴명, 제료정보
                String foodCode = recipeNode.path("RCP_SEQ").asText();
                String recipeName = recipeNode.path("RCP_NM").asText();
                String partsDetails = recipeNode.path("RCP_PARTS_DTLS").asText();

//                요리종류, 조리방법, 이미지경로(소), 저감 조리법 TIP
                String category = recipeNode.path("RCP_PAT2").asText();
                String cookingMethod = recipeNode.path("RCP_WAY2").asText();
                String mainImageUrl = recipeNode.path("ATT_FILE_NO_MAIN").asText();
                String healthTip = recipeNode.path("RCP_NA_TIP").asText();

//                열량, 단백질, 지방, 탄수화물, 나트륨
                Double calories = parseDoubleSafe(recipeNode.path("INFO_ENG").asText());
                Double protein = parseDoubleSafe(recipeNode.path("INFO_PRO").asText());
                Double fat = parseDoubleSafe(recipeNode.path("INFO_FAT").asText());
                Double carbs = parseDoubleSafe(recipeNode.path("INFO_CAR").asText());
                Double sodium = parseDoubleSafe(recipeNode.path("INFO_NA").asText());

//                [Menu 저장] 이미 있는 요리면 가져오고, 없으면 새로 생성
                Menu menu = menuRepository.findByFoodCode(foodCode)
                        .orElseGet(() -> {
                            Menu newMenu = Menu.builder()
                                    .foodCode(foodCode)
                                    .name(recipeName)
                                    .category(category)             // 카테고리 매핑
                                    .cookingMethod(cookingMethod)   // 조리법 매핑
                                    .mainImageUrl(mainImageUrl)     // 메인 이미지 매핑
                                    .healthTip(healthTip)           // 팁 매핑
                                    .calories(calories)             // 열량 매핑
                                    .protein(protein)               // 단백질 매핑
                                    .fat(fat)                       // 지방 매핑
                                    .carbs(carbs)                   // 탄수화물 매핑
                                    .sodium(sodium)                 // 나트륨 매핑
                                    .build();
                            return menuRepository.save(newMenu);
                        });

//                [Transform - parsing] 파서로 문자열 분리
                List<IngredientDto> dtoList = RecipeDataParser.parseIngredients(partsDetails, recipeName);

//                [Load] [Ingredient 저장 & 맵핑]
                for (IngredientDto dto : dtoList) {
//                  재료가 DB에 없으면 새로 생성 (기존 로직)
                    Ingredient ingredient = ingredientRepository.findByName(dto.getName())
                            .orElseGet(() -> {
                                Ingredient newIngredient = Ingredient.builder()
                                        .name(dto.getName())
                                        .build();
                                return ingredientRepository.save(newIngredient);
                            });

                    // [MenuIngredient 맵핑 테이블 저장] 요리, 재료, 카테고리, 변환된 '무게'를 연결
                    MenuIngredient menuIngredient = MenuIngredient.builder()
                            .menu(menu)
                            .ingredient(ingredient)
                            .subCategory(dto.getSubCategory())
                            .requiredWeight(dto.getParsedWeight()) // 추출된 Double 값 적재
                            .build();

                    menuIngredientRepository.save(menuIngredient);
                }
                log.info("메뉴 및 식재료 매핑 완료: {}", recipeName);
            }
        }
        catch (Exception e){
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
