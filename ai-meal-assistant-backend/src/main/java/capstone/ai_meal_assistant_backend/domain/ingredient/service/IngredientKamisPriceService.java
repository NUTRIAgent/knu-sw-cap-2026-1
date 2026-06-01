package capstone.ai_meal_assistant_backend.domain.ingredient.service;

import capstone.ai_meal_assistant_backend.domain.ingredient.dto.IngredientPriceResponse;
import capstone.ai_meal_assistant_backend.domain.ingredient.entity.IngredientKamisPrice;
import capstone.ai_meal_assistant_backend.domain.ingredient.repository.IngredientKamisPriceRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class IngredientKamisPriceService {

    private final IngredientKamisPriceRepository repository;

    public List<IngredientPriceResponse> getAllLatest() {
        return repository.findAllLatestWithIngredientId().stream()
                .map(row -> {
                    IngredientKamisPrice price = (IngredientKamisPrice) row[0];
                    Long ingredientId = row[1] != null ? ((Number) row[1]).longValue() : null;
                    return IngredientPriceResponse.fromKamis(price, ingredientId);
                })
                .collect(Collectors.toList());
    }
}
