package capstone.ai_meal_assistant_batch.domain.ingredient.entity;

import capstone.ai_meal_assistant_batch.global.entity.BaseEntity;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "ingredient_kamis_mappings")
@Getter
@Builder
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor(access = AccessLevel.PRIVATE)
public class IngredientKamisMapping extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "ingredient_id", nullable = false)
    private Ingredient ingredient;

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

    @Builder.Default
    @Column(nullable = false)
    private boolean confirmed = false;
}
