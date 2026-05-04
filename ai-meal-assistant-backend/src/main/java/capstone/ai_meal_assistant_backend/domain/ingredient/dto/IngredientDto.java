package capstone.ai_meal_assistant_backend.domain.ingredient.dto;

import lombok.Getter;

@Getter
public class IngredientDto {

    private String name; // 재료명 (예: 고구마, 설탕)
    private String originalAmount; // 원본 텍스트 (예: "100g(2/3개)")
    private Double parsedWeight;   // 추출된 순수 숫자 (예: 100.0)
    private String subCategory; // 재료가 어디 소속인지


    public IngredientDto(String name, String originalAmount, Double parsedWeight, String subCategory) {
        this.name = name;
        this.originalAmount = originalAmount;
        this.parsedWeight = parsedWeight;
        this.subCategory = subCategory;
    }

//    toString은 결과 확인용
    @Override
    public String toString() {
        return "IngredientDto{" + "name='" + name + '\'' +
                ", originalAmount='" + originalAmount + '\'' +
                ", parsedWeight='" + parsedWeight + '\'' + '}' +
                ", subCategory='" + subCategory + '\'' + '}';
    }

}
