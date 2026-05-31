package capstone.ai_meal_assistant_batch.domain.ingredient.entity;

import capstone.ai_meal_assistant_batch.global.entity.BaseEntity;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "ingredient_kamis_prices", indexes = {
        @Index(name = "idx_kamis_price_code_date", columnList = "kamis_item_code, base_date DESC")
})
@Getter
@Builder
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor(access = AccessLevel.PRIVATE)
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

    @Column(name = "last_sync_at")
    private LocalDateTime lastSyncAt;

    private Integer prevDayPrice;
    private Integer prevWeekPrice;
    private Integer prevMonthPrice;

    public void updatePrice(double pricePerGram, Integer originalPrice, String originalUnit,
                            Integer prevDayPrice, Integer prevWeekPrice, Integer prevMonthPrice) {
        this.pricePerGram = pricePerGram;
        this.originalPrice = originalPrice;
        this.originalUnit = originalUnit;
        this.prevDayPrice = prevDayPrice;
        this.prevWeekPrice = prevWeekPrice;
        this.prevMonthPrice = prevMonthPrice;
        this.lastSyncAt = LocalDateTime.now();
    }
}
