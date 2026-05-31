package capstone.ai_meal_assistant_backend.domain.ingredient.entity;

import capstone.ai_meal_assistant_backend.global.entity.BaseEntity;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "ingredient_kamis_prices")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class IngredientKamisPrice extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "kamis_item_code", nullable = false)
    private String kamisItemCode;

    @Column(name = "kamis_item_name", nullable = false)
    private String kamisItemName;

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

    private Integer prevDayPrice;
    private Integer prevWeekPrice;
    private Integer prevMonthPrice;
}
