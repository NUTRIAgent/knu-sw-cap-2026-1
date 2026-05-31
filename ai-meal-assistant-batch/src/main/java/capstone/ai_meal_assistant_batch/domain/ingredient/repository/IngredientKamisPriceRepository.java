package capstone.ai_meal_assistant_batch.domain.ingredient.repository;

import capstone.ai_meal_assistant_batch.domain.ingredient.entity.IngredientKamisPrice;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.Optional;

public interface IngredientKamisPriceRepository extends JpaRepository<IngredientKamisPrice, Long> {

    Optional<IngredientKamisPrice> findByKamisItemCodeAndMarketNameAndMarketTypeAndOriginalUnitAndBaseDate(
            String kamisItemCode,
            String marketName,
            String marketType,
            String originalUnit,
            LocalDateTime baseDate
    );
}
