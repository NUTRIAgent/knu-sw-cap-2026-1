package capstone.ai_meal_assistant_backend.domain.ingredient.repository;


import capstone.ai_meal_assistant_backend.domain.ingredient.entity.Ingredient;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

// 식재료
public interface IngredientRepository extends JpaRepository<Ingredient, Long> {

    Optional<Ingredient> findByName(String name); // 파이프라인에서 중복 저장 방지용
}
