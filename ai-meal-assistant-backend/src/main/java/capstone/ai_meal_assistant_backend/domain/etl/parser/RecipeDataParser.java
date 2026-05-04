package capstone.ai_meal_assistant_backend.domain.etl.parser;

import capstone.ai_meal_assistant_backend.domain.ingredient.dto.IngredientDto;

import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class RecipeDataParser {

    public static List<IngredientDto> parseIngredients(String rcpPartsDtls, String recipeName) {
        List<IngredientDto> ingredientList = new ArrayList<>();
        if(rcpPartsDtls == null || rcpPartsDtls.isEmpty()) return ingredientList;

//         줄바꿈을 쉼표로 바꿔서 잉렬로 만든다
        String cleaned = rcpPartsDtls
                .replace("\\n", ",")
                .replace("\\r", ",")
                .replaceAll("\\r\\n|\\r|\\n", ",");
//        치환하다 생긴 연속된 쉼표(,,,)를 하나로 정리
        cleaned = cleaned.replaceAll(",+", ",");

//        쉼표(,)를 기준으로 전체 문자열을 조각
        String[] parts = cleaned.split(",");
//         정규표현식 패턴: (문자열 부분) + 공백 + (숫자로 시작하는 부분)
//         ^(.*?): 처음부터 숫자 나오기 전까지의 문자 (재료명)
//         \s+: 중간에 띄어쓰기 1개 이상
//         ([0-9]+.*)$: 숫자로 시작해서 끝까지 (수량과 단위)
        Pattern pattern = Pattern.compile("^(.*?)\\s+([0-9]+.*)$");

//      현재 파싱 중인 재료들의 소속을 기억하는 변수 (기본값: "메인")
        String currentSubCategory = "메인";

        for (int i=0; i<parts.length; i++) {
            String part = parts[i].trim(); // " 물 200ml" 처럼 앞에 묻은 공백 제거
            if (part.isEmpty()) continue;

            // 서브 카테고리 추출 (예: "●순두부사과 소스 :")
            if (part.contains(":")) {
                int colonIndex = part.indexOf(":");
                String categoryPart = part.substring(0, colonIndex);
                currentSubCategory = categoryPart.replaceAll("[●■▶\\-\\[\\]]", "").trim();

                // 콜론 뒷부분(실제 재료)을 다시 part에 넣고 계속 진행
                part = part.substring(colonIndex + 1).trim();
                if (part.isEmpty()) continue;
            }
            // "북엇국" 처럼 기호나 콜론 없이 덜렁 카테고리 이름만 있는 경우 방어
            else if (!part.matches(".*[0-9]+.*") && !part.contains(" ") && part.length() > 1) {
                // 숫자도 없고 띄어쓰기도 없으면 카테고리명으로 간주하고 넘어감
                currentSubCategory = part.replaceAll("[●■▶\\-\\[\\]]", "").trim();
                continue;
            }

//            재료명과 무게 분리
            Matcher matcher = pattern.matcher(part);
            if (matcher.find()) {
                // 정규식에 맞게 분리된 경우
                String name = matcher.group(1).trim();   // 재료명
                String amount = matcher.group(2).trim(); // 수량

//                첫번째 재료 (i==0) 일 때만 요리 이름 지우기
//                고구마죽 고구마 100g -> 고구마죽만 분리
                if(i==0 && recipeName != null){
//                    예: name(고구마죽 고구마)에서 recipeName(고구마죽)이라는 글자만 ""(빈칸)으로 바꿈
                    name = name.replace(recipeName, "").trim();
                }

                Double parsedWeight = extractWeight(amount);

                ingredientList.add(new IngredientDto(name, amount, parsedWeight, currentSubCategory));
            } else {
                // 패턴에 안 맞는 이상한 데이터가 들어올 경우의 안전장치
                // (예: 수량이 안 적혀있고 "소금 약간" 이라고만 적힌 경우)
                ingredientList.add(new IngredientDto(part, "적당량", 0.0, currentSubCategory));
            }
        }
        return ingredientList;
    }

//    문자열에서 g, ml 단위의 숫자만 추출하는 로직
    public static Double extractWeight(String amountStr){
        if(amountStr == null || amountStr.isBlank()) return 0.0;

//        정규식: 숫자와 소수점만 찾기 (예: "1.5kg", "100g" -> "1.5", "100"
        Pattern pattern = Pattern.compile("([0-9]+\\.?[0-9]*)");
        Matcher matcher = pattern.matcher(amountStr);

        if(matcher.find()){
            try{
                double value = Double.parseDouble(matcher.group(1));
                String lowerAmount = amountStr.toLowerCase();

//                단위 변환 (kg, L 등이 들어가 있으면 1000을 곱해서 g/ml로 통일)
                if (lowerAmount.contains("kg") || (lowerAmount.contains("l") && !lowerAmount.contains("ml"))) {
                    return value * 1000.0;
                }
                return value;
            }
            catch (NumberFormatException e){
                return 0.0;
            }
        }

//        "약간", "적당량" 등 숫자가 아에 없는 부재료는 일단 0.0으로 처리
        return 0.0;

    }
}
