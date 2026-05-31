package capstone.ai_meal_assistant_batch.domain.ingredient.repository;

import capstone.ai_meal_assistant_batch.domain.ingredient.entity.IngredientPrice;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.Optional;

// 물가
public interface IngredientPriceRepository extends JpaRepository<IngredientPrice, Long> {

    // 특정 식재료(예: 양파)의 가장 최근(날짜 내림차순) 가격 1개만 가져옴
    Optional<IngredientPrice> findTopByIngredientIdOrderByBaseDateDesc(Long ingredientId);

    Optional<IngredientPrice> findTopByIngredientIdAndSourceApi(Long ingredientId, String sourceApi);
}
