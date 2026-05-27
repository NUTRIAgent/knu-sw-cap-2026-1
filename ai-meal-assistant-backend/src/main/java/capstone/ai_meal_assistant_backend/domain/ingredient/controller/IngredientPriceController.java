package capstone.ai_meal_assistant_backend.domain.ingredient.controller;

import capstone.ai_meal_assistant_backend.domain.ingredient.dto.BatchPriceItem;
import capstone.ai_meal_assistant_backend.domain.ingredient.dto.BatchPriceRequest;
import capstone.ai_meal_assistant_backend.domain.ingredient.dto.IngredientPriceResponse;
import capstone.ai_meal_assistant_backend.domain.ingredient.service.IngredientPriceService;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/ingredients/prices")
@RequiredArgsConstructor
public class IngredientPriceController {

    private final IngredientPriceService service;

    @Getter
    @AllArgsConstructor
    private static class ApiResponse<T> {
        private boolean success;
        private T data;
        private String error;

        static <T> ApiResponse<T> ok(T data) {
            return new ApiResponse<>(true, data, null);
        }

        static <T> ApiResponse<T> fail(String error) {
            return new ApiResponse<>(false, null, error);
        }
    }

    /**
     * 전체 재료 최신 가격 목록 조회
     * GET /api/v1/ingredients/prices/all
     */
    @GetMapping("/all")
    public ResponseEntity<ApiResponse<List<IngredientPriceResponse>>> getAllPrices() {
        return ResponseEntity.ok(ApiResponse.ok(service.getAllLatest()));
    }

    /**
     * 단일 재료의 최신 가격 조회
     * GET /api/v1/ingredients/prices?name=양파
     */
    @GetMapping
    public ResponseEntity<ApiResponse<IngredientPriceResponse>> getPrice(@RequestParam("name") String name) {
        return service.getLatestByName(name)
                .<ResponseEntity<ApiResponse<IngredientPriceResponse>>>map(r -> ResponseEntity.ok(ApiResponse.ok(r)))
                .orElseGet(() -> ResponseEntity.status(404).body(ApiResponse.fail("가격 데이터 없음: " + name)));
    }

    /**
     * 여러 재료의 최신 가격 일괄 조회
     * POST /api/v1/ingredients/prices/batch
     * Body: { "names": ["양파", "당근"] }
     */
    @PostMapping("/batch")
    public ResponseEntity<ApiResponse<List<BatchPriceItem>>> getBatchPrices(@RequestBody BatchPriceRequest request) {
        List<BatchPriceItem> results = service.getBatchByNames(request.names());
        return ResponseEntity.ok(ApiResponse.ok(results));
    }
}
