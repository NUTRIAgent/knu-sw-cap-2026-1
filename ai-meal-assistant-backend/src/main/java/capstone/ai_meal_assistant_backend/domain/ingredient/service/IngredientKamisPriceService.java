package capstone.ai_meal_assistant_backend.domain.ingredient.service;

import capstone.ai_meal_assistant_backend.domain.ingredient.dto.IngredientPriceResponse;
import capstone.ai_meal_assistant_backend.domain.ingredient.repository.IngredientKamisPriceRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class IngredientKamisPriceService {

    private final IngredientKamisPriceRepository repository;

    public List<IngredientPriceResponse> getAllLatest() {
        return repository.findAllLatest().stream()
                .map(IngredientPriceResponse::fromKamis)
                .toList();
    }
}
