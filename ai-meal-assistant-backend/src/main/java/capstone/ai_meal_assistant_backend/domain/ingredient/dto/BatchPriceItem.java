package capstone.ai_meal_assistant_backend.domain.ingredient.dto;

import java.time.LocalDateTime;

public record BatchPriceItem(
        String ingredientName,
        boolean found,
        Double pricePerGram,
        Integer originalPrice,
        String originalUnit,
        LocalDateTime baseDate
) {
    public static BatchPriceItem notFound(String name) {
        return new BatchPriceItem(name, false, null, null, null, null);
    }

    public static BatchPriceItem found(IngredientPriceResponse r) {
        return new BatchPriceItem(
                r.ingredientName(),
                true,
                r.pricePerGram(),
                r.originalPrice(),
                r.originalUnit(),
                r.baseDate()
        );
    }
}
