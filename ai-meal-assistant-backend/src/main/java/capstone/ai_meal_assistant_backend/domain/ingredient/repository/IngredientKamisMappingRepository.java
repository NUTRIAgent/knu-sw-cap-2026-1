package capstone.ai_meal_assistant_backend.domain.ingredient.repository;

import capstone.ai_meal_assistant_backend.domain.ingredient.entity.IngredientKamisMapping;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface IngredientKamisMappingRepository extends JpaRepository<IngredientKamisMapping, Long> {

    List<IngredientKamisMapping> findAllByConfirmedFalse();

    List<IngredientKamisMapping> findAllByIngredientIdAndConfirmedFalseAndIdNot(Long ingredientId, Long excludeId);
}
