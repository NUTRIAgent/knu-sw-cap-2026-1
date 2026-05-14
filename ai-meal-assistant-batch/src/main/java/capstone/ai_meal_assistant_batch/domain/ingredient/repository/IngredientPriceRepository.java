package capstone.ai_meal_assistant_batch.domain.ingredient.repository;

import java.time.LocalDateTime;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import capstone.ai_meal_assistant_batch.domain.ingredient.entity.IngredientPrice;

public interface IngredientPriceRepository extends JpaRepository<IngredientPrice, Long> {

	Optional<IngredientPrice> findByIngredientIdAndSourceApiAndMarketNameAndMarketTypeAndOriginalUnitAndBaseDate(
			Long ingredientId,
			String sourceApi,
			String marketName,
			String marketType,
			String originalUnit,
			LocalDateTime baseDate);
}
