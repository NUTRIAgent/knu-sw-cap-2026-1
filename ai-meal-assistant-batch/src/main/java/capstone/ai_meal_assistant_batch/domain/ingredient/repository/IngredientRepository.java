package capstone.ai_meal_assistant_batch.domain.ingredient.repository;


import capstone.ai_meal_assistant_batch.domain.ingredient.entity.Ingredient;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.Optional;

// 식재료
public interface IngredientRepository extends JpaRepository<Ingredient, Long> {

    Optional<Ingredient> findByName(String name); // 파이프라인에서 중복 저장 방지용

    @Query("SELECT i FROM Ingredient i WHERE i.id NOT IN (SELECT DISTINCT ip.ingredient.id FROM IngredientPrice ip)")
    List<Ingredient> findIngredientsWithoutAnyPrice();
}
