package capstone.ai_meal_assistant_backend.domain.ingredient.dto;

import capstone.ai_meal_assistant_backend.domain.ingredient.entity.IngredientPrice;

import java.time.LocalDateTime;

public record IngredientPriceResponse(
        Long ingredientId,
        String ingredientName,
        Double pricePerGram,
        Integer originalPrice,
        String originalUnit,
        String marketName,
        String marketType,
        LocalDateTime baseDate
) {
    public static IngredientPriceResponse from(IngredientPrice price) {
        return new IngredientPriceResponse(
                price.getIngredient().getId(),
                price.getIngredient().getName(),
                price.getPricePerGram(),
                price.getOriginalPrice(),
                price.getOriginalUnit(),
                price.getMarketName(),
                price.getMarketType(),
                price.getBaseDate()
        );
    }
}
