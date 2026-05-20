package capstone.ai_meal_assistant_backend.domain.menu.dto;

import capstone.ai_meal_assistant_backend.domain.menu.entity.Menu;
import lombok.Getter;

@Getter
public class MenuCandidateDto {

    private final Long id;
    private final String name;
    private final String category;
    private final Integer calories;
    private final Double protein;
    private final Double fat;
    private final Double carbs;
    private final Integer basePrice;

    private MenuCandidateDto(Menu menu) {
        this.id        = menu.getId();
        this.name      = menu.getName();
        this.category  = menu.getCategory();
        this.calories  = menu.getCalories();
        this.protein   = menu.getProtein();
        this.fat       = menu.getFat();
        this.carbs     = menu.getCarbs();
        this.basePrice = menu.getBasePrice();
    }

    public static MenuCandidateDto from(Menu menu) {
        return new MenuCandidateDto(menu);
    }
}
