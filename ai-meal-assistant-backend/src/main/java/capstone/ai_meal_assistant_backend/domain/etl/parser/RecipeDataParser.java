package capstone.ai_meal_assistant_backend.domain.etl.parser;

import capstone.ai_meal_assistant_backend.domain.ingredient.dto.IngredientDto;

import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class RecipeDataParser {

    public static List<IngredientDto> parseIngredients(String rcpPartsDtls) {
        List<IngredientDto> ingredientList = new ArrayList<>();

        // 1. 먼저 쉼표(,)를 기준으로 전체 문자열을 조각냅니다.
        String[] parts = rcpPartsDtls.split(",");

        // 2. 정규표현식 패턴: (문자열 부분) + 공백 + (숫자로 시작하는 부분)
        // ^(.*?): 처음부터 숫자 나오기 전까지의 문자 (재료명)
        // \s+: 중간에 띄어쓰기 1개 이상
        // ([0-9]+.*)$: 숫자로 시작해서 끝까지 (수량과 단위)
        Pattern pattern = Pattern.compile("^(.*?)\\s+([0-9]+.*)$");

        for (String part : parts) {
            part = part.trim(); // " 물 200ml" 처럼 앞에 묻은 공백 제거

            Matcher matcher = pattern.matcher(part);
            if (matcher.find()) {
                // 정규식에 맞게 분리된 경우
                String name = matcher.group(1).trim();   // 재료명
                String amount = matcher.group(2).trim(); // 수량

                ingredientList.add(new IngredientDto(name, amount));
            } else {
                // 패턴에 안 맞는 이상한 데이터가 들어올 경우의 안전장치
                // (예: 수량이 안 적혀있고 "소금 약간" 이라고만 적힌 경우)
                ingredientList.add(new IngredientDto(part, "적당량"));
            }
        }
        return ingredientList;
    }

    // 테스트 실행
    public static void main(String[] args) {
        String rawData = "고구마죽 고구마 100g(2/3개), 설탕 2g(1/3작은술), 찹쌀가루 3g(2/3작은술),물 200ml(1컵), 잣 8g(8알)";

        List<IngredientDto> result = parseIngredients(rawData);

        for (IngredientDto dto : result) {
            System.out.println(dto.toString());
        }
    }
}
