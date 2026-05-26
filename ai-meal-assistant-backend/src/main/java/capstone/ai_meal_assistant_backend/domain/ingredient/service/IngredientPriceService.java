package capstone.ai_meal_assistant_backend.domain.ingredient.service;

import capstone.ai_meal_assistant_backend.domain.ingredient.dto.BatchPriceItem;
import capstone.ai_meal_assistant_backend.domain.ingredient.dto.IngredientPriceResponse;
import capstone.ai_meal_assistant_backend.domain.ingredient.entity.IngredientPrice;
import capstone.ai_meal_assistant_backend.domain.ingredient.repository.IngredientPriceRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class IngredientPriceService {

    private final IngredientPriceRepository repository;

    public Optional<IngredientPriceResponse> getLatestByName(String name) {
        List<IngredientPrice> results = repository.findLatestByIngredientName(name, PageRequest.of(0, 1));
        return results.isEmpty() ? Optional.empty() : Optional.of(IngredientPriceResponse.from(results.get(0)));
    }

    public List<BatchPriceItem> getBatchByNames(List<String> names) {
        return names.stream()
                .map(name -> getLatestByName(name)
                        .map(BatchPriceItem::found)
                        .orElseGet(() -> BatchPriceItem.notFound(name)))
                .toList();
    }
}
