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

    private MenuCandidateDto(Menu menu, String ingredientsText, List<StepDto> steps) {
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
    }

    public static MenuCandidateDto from(Menu menu, String ingredientsText, List<StepDto> steps) {
        return new MenuCandidateDto(menu, ingredientsText, steps);
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
}
