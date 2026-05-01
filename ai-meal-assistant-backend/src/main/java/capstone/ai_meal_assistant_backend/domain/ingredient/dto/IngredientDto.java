package capstone.ai_meal_assistant_backend.domain.ingredient.dto;


public class IngredientDto {

    private String name; // 재료명 (예: 고구마, 설탕)
    private String amount; // 수량 (예: 100g(2/3개), 2g(1/3작은술))

    public IngredientDto(String name, String amount) {
        this.name = name;
        this.amount = amount;
    }

//    toString은 결과 확인용
    @Override
    public String toString() {
        return "IngredientDto{" + "name='" + name + '\'' + ", amount='" + amount + '\'' + '}';
    }

}
