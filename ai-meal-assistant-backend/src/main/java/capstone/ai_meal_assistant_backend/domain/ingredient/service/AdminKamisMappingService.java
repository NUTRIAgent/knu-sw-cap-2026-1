package capstone.ai_meal_assistant_backend.domain.ingredient.service;

import capstone.ai_meal_assistant_backend.domain.ingredient.dto.AutoConfirmResult;
import capstone.ai_meal_assistant_backend.domain.ingredient.dto.KamisMappingGroupResponse;
import capstone.ai_meal_assistant_backend.domain.ingredient.dto.KamisMappingPatchRequest;
import capstone.ai_meal_assistant_backend.domain.ingredient.entity.IngredientKamisMapping;
import capstone.ai_meal_assistant_backend.domain.ingredient.repository.IngredientKamisMappingRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AdminKamisMappingService {

    private final IngredientKamisMappingRepository repository;

    @Transactional(readOnly = true)
    public List<KamisMappingGroupResponse> getUnconfirmedMappings() {
        List<IngredientKamisMapping> mappings = repository.findAllByConfirmedFalse();

        Map<Long, List<IngredientKamisMapping>> grouped = mappings.stream()
                .collect(Collectors.groupingBy(IngredientKamisMapping::getIngredientId));

        return grouped.entrySet().stream()
                .map(e -> {
                    String ingredientName = e.getValue().get(0).getIngredientName();
                    List<KamisMappingGroupResponse.CandidateDto> candidates = e.getValue().stream()
                            .sorted(Comparator.comparingDouble(
                                    m -> -(m.getAutoScore() != null ? m.getAutoScore() : 0.0)))
                            .map(m -> new KamisMappingGroupResponse.CandidateDto(
                                    m.getId(), m.getKamisItemCode(), m.getKamisItemName(), m.getAutoScore()))
                            .toList();
                    return new KamisMappingGroupResponse(e.getKey(), ingredientName, candidates);
                })
                .sorted(Comparator.comparing(KamisMappingGroupResponse::ingredientName))
                .toList();
    }

    @Transactional
    public void patchMapping(Long id, KamisMappingPatchRequest request) {
        IngredientKamisMapping mapping = repository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Mapping not found: " + id));

        mapping.updateKamisInfo(request.kamisItemCode(), request.kamisItemName());

        if (Boolean.TRUE.equals(request.confirm())) {
            mapping.confirm();
            // 같은 재료의 나머지 미확정 후보 자동 삭제
            List<IngredientKamisMapping> others = repository
                    .findAllByIngredientIdAndConfirmedFalseAndIdNot(mapping.getIngredientId(), id);
            repository.deleteAll(others);
        }
    }

    @Transactional
    public AutoConfirmResult autoConfirm(double minScore, double deleteBelow) {
        List<IngredientKamisMapping> candidates = repository.findAllByConfirmedFalse();

        Map<Long, List<IngredientKamisMapping>> grouped = candidates.stream()
                .collect(Collectors.groupingBy(IngredientKamisMapping::getIngredientId));

        int confirmedCount = 0;
        int deletedCount = 0;
        int needsReviewCount = 0;

        for (List<IngredientKamisMapping> group : grouped.values()) {
            IngredientKamisMapping best = group.stream()
                    .max(Comparator.comparingDouble(m -> m.getAutoScore() != null ? m.getAutoScore() : 0.0))
                    .orElse(null);
            if (best == null) continue;

            double bestScore = best.getAutoScore() != null ? best.getAutoScore() : 0.0;

            if (bestScore >= minScore) {
                // 점수 충분 → 자동 확정, 나머지 삭제
                best.confirm();
                List<IngredientKamisMapping> others = group.stream()
                        .filter(m -> !m.getId().equals(best.getId()))
                        .toList();
                repository.deleteAll(others);
                confirmedCount++;
            } else if (bestScore < deleteBelow) {
                // 최고 점수도 너무 낮음 → 전부 삭제
                repository.deleteAll(group);
                deletedCount++;
            } else {
                // 중간 점수 → 수동 검수
                needsReviewCount++;
            }
        }

        return new AutoConfirmResult(confirmedCount, deletedCount, needsReviewCount);
    }

    @Transactional
    public void deleteMapping(Long id) {
        IngredientKamisMapping mapping = repository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Mapping not found: " + id));
        if (mapping.isConfirmed()) {
            throw new IllegalStateException("Cannot delete a confirmed mapping. id=" + id);
        }
        repository.delete(mapping);
    }
}
