package capstone.ai_meal_assistant_batch.job.price;

import capstone.ai_meal_assistant_batch.domain.ingredient.entity.Ingredient;
import capstone.ai_meal_assistant_batch.domain.ingredient.entity.IngredientPrice;
import capstone.ai_meal_assistant_batch.domain.ingredient.repository.IngredientPriceRepository;
import capstone.ai_meal_assistant_batch.domain.ingredient.repository.IngredientRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class DefaultPriceFillService {

    private static final String SOURCE_API = "DEFAULT";
    private static final String DEFAULT_UNIT = "100g";

    private final IngredientRepository ingredientRepository;
    private final IngredientPriceRepository ingredientPriceRepository;

    @Transactional
    public DefaultPriceFillResult fillMissingPrices() {
        List<Ingredient> missing = ingredientRepository.findIngredientsWithoutAnyPrice();
        if (missing.isEmpty()) {
            return new DefaultPriceFillResult(0, 0);
        }

        LocalDateTime now = LocalDateTime.now();
        List<IngredientPrice> records = missing.stream()
                .map(ingredient -> IngredientPrice.builder()
                        .ingredient(ingredient)
                        .sourceApi(SOURCE_API)
                        .pricePerGram(0.0)
                        .originalPrice(0)
                        .originalUnit(DEFAULT_UNIT)
                        .baseDate(now)
                        .lastSyncAt(now)
                        .build())
                .toList();

        ingredientPriceRepository.saveAll(records);
        return new DefaultPriceFillResult(records.size(), 0);
    }
}
