package capstone.ai_meal_assistant_backend.domain.ingredient.entity;

import capstone.ai_meal_assistant_backend.global.entity.BaseEntity;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "ingredient_kamis_mappings")
@Getter
@NoArgsConstructor
public class IngredientKamisMapping extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "ingredient_id", nullable = false)
    private Long ingredientId;

    @Column(name = "ingredient_name", nullable = false)
    private String ingredientName;

    @Column(name = "kamis_item_code", nullable = false)
    private String kamisItemCode;

    @Column(name = "kamis_item_name")
    private String kamisItemName;

    @Column(name = "kamis_item_category_code")
    private String kamisItemCategoryCode;

    @Column(name = "kind_code")
    private String kindCode;

    @Column(name = "product_rank_code")
    private String productRankCode;

    @Column(name = "country_code")
    private String countryCode;

    @Column(name = "convert_kg_yn")
    private String convertKgYn;

    @Column(name = "auto_score")
    private Double autoScore;

    @Column(nullable = false)
    private boolean confirmed;

    public void confirm() {
        this.confirmed = true;
    }

    public void updateKamisInfo(String kamisItemCode, String kamisItemName) {
        if (kamisItemCode != null && !kamisItemCode.isBlank()) {
            this.kamisItemCode = kamisItemCode;
        }
        if (kamisItemName != null) {
            this.kamisItemName = kamisItemName;
        }
    }
}
