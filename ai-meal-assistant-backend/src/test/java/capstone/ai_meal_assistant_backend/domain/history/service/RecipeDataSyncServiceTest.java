package capstone.ai_meal_assistant_backend.domain.history.service;

import capstone.ai_meal_assistant_backend.domain.etl.FoodSafetyApiFetcher;
import capstone.ai_meal_assistant_backend.domain.etl.parser.RecipeDataParser;
import capstone.ai_meal_assistant_backend.domain.ingredient.dto.IngredientDto;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.web.reactive.function.client.WebClient;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

class RecipeDataSyncServiceTest {

    FoodSafetyApiFetcher apiFetcher = new FoodSafetyApiFetcher(WebClient.builder());
    ObjectMapper objectMapper = new ObjectMapper();

    @Test
    @DisplayName("DB 저장 없이 API 호출 및 파싱 결과만 콘솔에 출력하여 확안")
    void printParsedDataTest() throws Exception {

//        실제 API 호출
        System.out.println("식약처 API 호출 중 . . .");
        String rawJson = apiFetcher.fetchRecipeData();

//        JSON 파싱
        JsonNode rootNode = objectMapper.readTree(rawJson);
        JsonNode recipeArray = rootNode.path("COOKRCP01").path("row");

        System.out.println("\n==================================================");
        System.out.println("             [ 데이터 파싱 결과 확인 ]              ");
        System.out.println("==================================================");

//        배열을 돌며 결과 출력
        for (JsonNode recipeNode : recipeArray) {
            String recipeName = recipeNode.path("RCP_NM").asText();
            String partsDetails = recipeNode.path("RCP_PARTS_DTLS").asText();

            System.out.println("\n 요리명: " + recipeName);
            System.out.println("   원본 문자열: " + partsDetails);
            System.out.println("   --- [ 추출된 재료 및 무게 ] ---");

            // 파서를 이용해 재료 문자열 분리 및 무게 추출
            List<IngredientDto> dtoList = RecipeDataParser.parseIngredients(partsDetails, recipeName);

            // 쪼개진 재료들 예쁘게 출력
            for (IngredientDto dto : dtoList) {
                // RecipeDataSyncServiceTest.java 의 출력 부분만 수정
                System.out.printf("   [%-10s] 재료명: %-8s | 추출된 무게: %-5.1f | 원본단위: %s\n",
                        dto.getSubCategory(), // 추가된 카테고리
                        dto.getName(),
                        dto.getParsedWeight(),
                        dto.getOriginalAmount());
            }
        }
        System.out.println("\n==================================================");
        System.out.println("               [ 테스트 종료 ]                ");
        System.out.println("==================================================");
    }
}