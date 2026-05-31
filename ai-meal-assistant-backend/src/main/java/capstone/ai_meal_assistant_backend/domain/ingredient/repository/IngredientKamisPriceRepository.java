package capstone.ai_meal_assistant_backend.domain.ingredient.repository;

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
}
