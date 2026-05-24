package capstone.ai_meal_assistant_backend.domain.ingredient.dto;

import java.util.List;

public record KamisMappingGroupResponse(
        Long ingredientId,
        String ingredientName,
        List<CandidateDto> candidates
) {
    public record CandidateDto(
            Long id,
            String kamisItemCode,
            String kamisItemName,
            Double autoScore
    ) {}
}
