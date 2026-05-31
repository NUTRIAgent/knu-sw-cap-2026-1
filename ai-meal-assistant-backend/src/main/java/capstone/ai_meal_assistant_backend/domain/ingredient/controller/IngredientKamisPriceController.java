package capstone.ai_meal_assistant_backend.domain.ingredient.controller;

import capstone.ai_meal_assistant_backend.domain.ingredient.dto.IngredientPriceResponse;
import capstone.ai_meal_assistant_backend.domain.ingredient.service.IngredientKamisPriceService;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/ingredients/kamis-prices")
@RequiredArgsConstructor
public class IngredientKamisPriceController {

    private final IngredientKamisPriceService service;

    @Getter
    @AllArgsConstructor
    private static class ApiResponse<T> {
        private boolean success;
        private T data;
        private String error;

        static <T> ApiResponse<T> ok(T data) {
            return new ApiResponse<>(true, data, null);
        }
    }

    @GetMapping("/all")
    public ResponseEntity<ApiResponse<List<IngredientPriceResponse>>> getAllPrices() {
        return ResponseEntity.ok(ApiResponse.ok(service.getAllLatest()));
    }
}
