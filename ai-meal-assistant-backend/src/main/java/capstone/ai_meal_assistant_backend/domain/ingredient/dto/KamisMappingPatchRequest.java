package capstone.ai_meal_assistant_backend.domain.ingredient.dto;

public record KamisMappingPatchRequest(
        String kamisItemCode,
        String kamisItemName,
        Boolean confirm
) {}
