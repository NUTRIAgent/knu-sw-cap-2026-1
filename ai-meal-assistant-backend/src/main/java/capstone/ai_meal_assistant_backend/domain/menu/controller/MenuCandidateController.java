package capstone.ai_meal_assistant_backend.domain.menu.controller;

import capstone.ai_meal_assistant_backend.domain.menu.dto.MenuCandidateDto;
import capstone.ai_meal_assistant_backend.domain.menu.service.MenuCandidateService;
import capstone.ai_meal_assistant_backend.global.security.JwtUtil;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/menus")
@RequiredArgsConstructor
public class MenuCandidateController {

    private final MenuCandidateService menuCandidateService;
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

    /**
     * AI 추천용 메뉴 후보 25개 반환
     * - 알레르기 메뉴 제외
     * - 예산 필터
     * - 단백질 수준 필터
     * - 이후 fitnessGoal / foodPreferences 필드 병합 시 확장 예정
     */
    @GetMapping("/candidates")
    public ResponseEntity<ApiResponse<List<MenuCandidateDto>>> getCandidates(
            @RequestHeader(value = "Authorization", required = false) String authHeader) {

        List<MenuCandidateDto> candidates;
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            String email = jwtUtil.getEmailFromToken(authHeader.substring(7));
            candidates = menuCandidateService.getCandidates(email);
        } else {
            candidates = menuCandidateService.getRandomCandidates();
        }
        return ResponseEntity.ok(ApiResponse.ok(candidates));
    }
}
