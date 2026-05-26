package capstone.ai_meal_assistant_batch.domain.ingredient.repository;

import capstone.ai_meal_assistant_batch.domain.ingredient.entity.IngredientKamisMapping;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface IngredientKamisMappingRepository extends JpaRepository<IngredientKamisMapping, Long> {

    List<IngredientKamisMapping> findAllByConfirmedTrue();

    boolean existsByIngredientIdAndConfirmedTrue(Long ingredientId);

    boolean existsByIngredientIdAndKamisItemCode(Long ingredientId, String kamisItemCode);
}
