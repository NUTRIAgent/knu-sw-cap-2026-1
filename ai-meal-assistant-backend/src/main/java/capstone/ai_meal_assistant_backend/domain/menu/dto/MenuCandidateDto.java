package capstone.ai_meal_assistant_backend.domain.menu.dto;

import capstone.ai_meal_assistant_backend.domain.menu.entity.Menu;
import lombok.Getter;

import java.util.List;

@Getter
public class MenuCandidateDto {

    private final Long id;
    private final String name;
    private final String category;
    private final String cookingMethod;
    private final Double calories;
    private final Double protein;
    private final Double fat;
    private final Double carbs;
    private final Double sodium;
    private final Integer basePrice;
    private final String mainImageUrl;
    private final String healthTip;
    private final String ingredientsText;
    private final List<StepDto> steps;
    private final List<IngredientCost> ingredientCosts;
    private final Integer totalEstimatedCost;
    private final int missingCount;

    private MenuCandidateDto(Menu menu, String ingredientsText, List<StepDto> steps,
                             List<IngredientCost> ingredientCosts) {
        this.id              = menu.getId();
        this.name            = menu.getName();
        this.category        = menu.getCategory();
        this.cookingMethod   = menu.getCookingMethod();
        this.calories        = menu.getCalories();
        this.protein         = menu.getProtein();
        this.fat             = menu.getFat();
        this.carbs           = menu.getCarbs();
        this.sodium          = menu.getSodium();
        this.basePrice       = menu.getBasePrice();
        this.mainImageUrl    = menu.getMainImageUrl();
        this.healthTip       = menu.getHealthTip();
        this.ingredientsText = ingredientsText;
        this.steps           = steps;
        this.ingredientCosts = ingredientCosts;

        int total = 0, missing = 0;
        for (IngredientCost c : ingredientCosts) {
            if (c.getCost() != null) total += c.getCost();
            else missing++;
        }
        this.totalEstimatedCost = total;
        this.missingCount       = missing;
    }

    public static MenuCandidateDto from(Menu menu, String ingredientsText, List<StepDto> steps,
                                        List<IngredientCost> ingredientCosts) {
        return new MenuCandidateDto(menu, ingredientsText, steps, ingredientCosts);
    }

    @Getter
    public static class StepDto {
        private final int stepNo;
        private final String content;
        private final String imageUrl;

        public StepDto(int stepNo, String content, String imageUrl) {
            this.stepNo  = stepNo;
            this.content = content;
            this.imageUrl = imageUrl;
        }
    }

    @Getter
    public static class IngredientCost {
        private final String name;
        private final double requiredWeight;   // g
        private final Double pricePerGram;      // 가격 미보유 시 null
        private final Integer cost;             // requiredWeight × pricePerGram, 미보유 시 null
        private final boolean priceAvailable;

        public IngredientCost(String name, double requiredWeight,
                              Double pricePerGram, Integer cost, boolean priceAvailable) {
            this.name           = name;
            this.requiredWeight = requiredWeight;
            this.pricePerGram   = pricePerGram;
            this.cost           = cost;
            this.priceAvailable = priceAvailable;
        }
    }
}
