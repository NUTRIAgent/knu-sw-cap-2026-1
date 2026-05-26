package capstone.ai_meal_assistant_backend.domain.ingredient.entity;

import capstone.ai_meal_assistant_backend.global.entity.BaseEntity;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "ingredient_prices")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class IngredientPrice extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "ingredient_id", nullable = false)
    private Ingredient ingredient;

    @Column(nullable = false)
    private Double pricePerGram;

    @Column(nullable = false)
    private String sourceApi;

    private Integer originalPrice;
    private String originalUnit;
    private String marketName;
    private String marketType;

    @Column(nullable = false)
    private LocalDateTime baseDate;
}
