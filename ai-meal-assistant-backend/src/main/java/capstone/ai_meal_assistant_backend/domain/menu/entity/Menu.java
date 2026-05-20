package capstone.ai_meal_assistant_backend.domain.menu.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "menus")
@Getter
@NoArgsConstructor
public class Menu {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String foodCode;

    @Column(nullable = false)
    private String name;

    private String category;
    private String cookingMethod;
    private Double calories;
    private Double protein;
    private Double fat;
    private Double carbs;
    private Double sodium;
    private Integer basePrice;

    @Column(length = 500)
    private String mainImageUrl;

    @Column(length = 1000)
    private String healthTip;
}