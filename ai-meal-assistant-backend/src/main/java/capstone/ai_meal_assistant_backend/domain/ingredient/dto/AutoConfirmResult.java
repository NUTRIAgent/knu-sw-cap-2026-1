package capstone.ai_meal_assistant_backend.domain.ingredient.dto;

public record AutoConfirmResult(
        int confirmedCount,
        int deletedCount,
        int needsReviewCount
) {}
