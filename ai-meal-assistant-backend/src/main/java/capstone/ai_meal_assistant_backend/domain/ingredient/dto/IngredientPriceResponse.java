package capstone.ai_meal_assistant_backend.domain.ingredient.dto;

import capstone.ai_meal_assistant_backend.domain.ingredient.entity.IngredientKamisPrice;
import capstone.ai_meal_assistant_backend.domain.ingredient.entity.IngredientPrice;

import java.time.LocalDateTime;

public record IngredientPriceResponse(
        Long ingredientId,
        String ingredientName,
        String kamisItemCode,
        Double pricePerGram,
        Integer originalPrice,
        String originalUnit,
        String marketName,
        String marketType,
        LocalDateTime baseDate,
        Double dayChangeRate,
        Double weekChangeRate,
        Double monthChangeRate
) {
    public static IngredientPriceResponse from(IngredientPrice price) {
        return new IngredientPriceResponse(
                price.getIngredient().getId(),
                price.getIngredient().getName(),
                null,
                price.getPricePerGram(),
                price.getOriginalPrice(),
                price.getOriginalUnit(),
                price.getMarketName(),
                price.getMarketType(),
                price.getBaseDate(),
                calcChangeRate(price.getOriginalPrice(), price.getPrevDayPrice()),
                calcChangeRate(price.getOriginalPrice(), price.getPrevWeekPrice()),
                calcChangeRate(price.getOriginalPrice(), price.getPrevMonthPrice())
        );
    }

    public static IngredientPriceResponse fromKamis(IngredientKamisPrice price, Long ingredientId) {
        return new IngredientPriceResponse(
                ingredientId,
                price.getKamisItemName(),
                price.getKamisItemCode(),
                price.getPricePerGram(),
                price.getOriginalPrice(),
                price.getOriginalUnit(),
                price.getMarketName(),
                price.getMarketType(),
                price.getBaseDate(),
                calcChangeRate(price.getOriginalPrice(), price.getPrevDayPrice()),
                calcChangeRate(price.getOriginalPrice(), price.getPrevWeekPrice()),
                calcChangeRate(price.getOriginalPrice(), price.getPrevMonthPrice())
        );
    }

    private static Double calcChangeRate(Integer current, Integer prev) {
        if (current == null || prev == null || prev == 0) return null;
        return Math.round((current - prev) * 1000.0 / prev) / 10.0;
    }
}
