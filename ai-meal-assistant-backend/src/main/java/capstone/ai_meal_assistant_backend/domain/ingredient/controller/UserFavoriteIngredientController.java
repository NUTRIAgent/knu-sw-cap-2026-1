package capstone.ai_meal_assistant_backend.domain.ingredient.controller;

import capstone.ai_meal_assistant_backend.domain.ingredient.service.UserFavoriteIngredientService;
import capstone.ai_meal_assistant_backend.global.security.JwtUtil;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Set;

@RestController
@RequestMapping("/api/v1/ingredients/favorites")
@RequiredArgsConstructor
public class UserFavoriteIngredientController {

    private final UserFavoriteIngredientService favoriteService;
    private final JwtUtil jwtUtil;

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

    /** GET /api/v1/ingredients/favorites/ids — 관심 재료 ID 목록 */
    @GetMapping("/ids")
    public ResponseEntity<ApiResponse<Set<Long>>> getFavoriteIds(
            @RequestHeader("Authorization") String authHeader) {
        String email = extractEmail(authHeader);
        return ResponseEntity.ok(ApiResponse.ok(favoriteService.getFavoriteIds(email)));
    }

    /** POST /api/v1/ingredients/favorites/{ingredientId} — 관심 재료 추가 */
    @PostMapping("/{ingredientId}")
    public ResponseEntity<ApiResponse<Void>> addFavorite(
            @RequestHeader("Authorization") String authHeader,
            @PathVariable Long ingredientId) {
        String email = extractEmail(authHeader);
        favoriteService.addFavorite(email, ingredientId);
        return ResponseEntity.ok(ApiResponse.ok(null));
    }

    /** DELETE /api/v1/ingredients/favorites/{ingredientId} — 관심 재료 제거 */
    @DeleteMapping("/{ingredientId}")
    public ResponseEntity<ApiResponse<Void>> removeFavorite(
            @RequestHeader("Authorization") String authHeader,
            @PathVariable Long ingredientId) {
        String email = extractEmail(authHeader);
        favoriteService.removeFavorite(email, ingredientId);
        return ResponseEntity.ok(ApiResponse.ok(null));
    }

    private String extractEmail(String authHeader) {
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            throw new IllegalArgumentException("유효하지 않은 인증 헤더입니다.");
        }
        return jwtUtil.getEmailFromToken(authHeader.substring(7));
    }
}
