package capstone.ai_meal_assistant_backend.domain.ingredient.repository;

import capstone.ai_meal_assistant_backend.domain.ingredient.entity.IngredientKamisMapping;
import capstone.ai_meal_assistant_backend.domain.ingredient.entity.IngredientKamisPrice;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface IngredientKamisPriceRepository extends JpaRepository<IngredientKamisPrice, Long> {

    @Query("""
            SELECT kp FROM IngredientKamisPrice kp
            WHERE kp.id IN (
                SELECT MAX(kp2.id) FROM IngredientKamisPrice kp2
                GROUP BY kp2.kamisItemCode
            )
            ORDER BY kp.kamisItemName ASC
            """)
    List<IngredientKamisPrice> findAllLatest();

    /**
     * 최신 KAMIS 가격 + ingredient_id 조인.
     * row = [IngredientKamisPrice, ingredientId(Long or null)]
     * ingredient_kamis_mappings에 매핑이 없는 항목은 ingredientId=null.
     */
    @Query("""
            SELECT kp, m.ingredientId
            FROM IngredientKamisPrice kp
            LEFT JOIN IngredientKamisMapping m ON m.kamisItemCode = kp.kamisItemCode AND m.confirmed = true
            WHERE kp.id IN (
                SELECT MAX(kp2.id) FROM IngredientKamisPrice kp2
                GROUP BY kp2.kamisItemCode
            )
            ORDER BY kp.kamisItemName ASC
            """)
    List<Object[]> findAllLatestWithIngredientId();
}
