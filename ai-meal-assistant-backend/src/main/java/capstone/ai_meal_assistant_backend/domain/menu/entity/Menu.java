package capstone.ai_meal_assistant_backend.domain.menu.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "menus")
public class Menu {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    private String category;
    private Integer calories;
    private Double protein;
    private Double fat;
    private Double carbs;
    private Integer basePrice;
}
