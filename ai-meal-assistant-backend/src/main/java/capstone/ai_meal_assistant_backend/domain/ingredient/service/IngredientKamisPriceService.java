package capstone.ai_meal_assistant_backend.domain.ingredient.service;

import capstone.ai_meal_assistant_backend.domain.ingredient.dto.IngredientPriceResponse;
import capstone.ai_meal_assistant_backend.domain.ingredient.entity.IngredientKamisMapping;
import capstone.ai_meal_assistant_backend.domain.ingredient.entity.IngredientKamisPrice;
import capstone.ai_meal_assistant_backend.domain.ingredient.repository.IngredientKamisMappingRepository;
import capstone.ai_meal_assistant_backend.domain.ingredient.repository.IngredientKamisPriceRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class IngredientKamisPriceService {

    private final IngredientKamisPriceRepository repository;
    private final IngredientKamisMappingRepository mappingRepository;

    public List<IngredientPriceResponse> getAllLatest() {
        List<IngredientKamisPrice> prices = repository.findAllLatest();

        // kamisItemCode → ingredientId 맵 (confirmed 무관)
        List<String> codes = prices.stream()
                .map(IngredientKamisPrice::getKamisItemCode)
                .collect(Collectors.toList());
        Map<String, Long> codeToIngredientId = mappingRepository
                .findAllByKamisItemCodeIn(codes).stream()
                .collect(Collectors.toMap(
                        IngredientKamisMapping::getKamisItemCode,
                        IngredientKamisMapping::getIngredientId,
                        (a, b) -> a   // 중복 시 첫 번째 유지
                ));

        return prices.stream()
                .map(p -> IngredientPriceResponse.fromKamis(
                        p, codeToIngredientId.get(p.getKamisItemCode())))
                .collect(Collectors.toList());
    }
}
