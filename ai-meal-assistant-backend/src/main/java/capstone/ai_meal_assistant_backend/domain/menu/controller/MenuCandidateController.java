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

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<MenuCandidateDto>> getMenuById(@PathVariable("id") Long id) {
        return ResponseEntity.ok(ApiResponse.ok(menuCandidateService.getMenuById(id)));
    }

    /**
     * AI 추천용 메뉴 후보 반환
     * - ids 파라미터 제공 시: 해당 ID 목록의 메뉴만 반환 (AI agent 전용)
     * - ids 없고 JWT 있을 시: 사용자 조건 필터링 후 랜덤 25개
     * - ids 없고 JWT 없을 시: 랜덤 25개
     */
    @GetMapping("/candidates")
    public ResponseEntity<ApiResponse<List<MenuCandidateDto>>> getCandidates(
            @RequestHeader(value = "Authorization", required = false) String authHeader,
            @RequestParam(value = "ids", required = false) List<Long> ids) {

        if (ids != null && !ids.isEmpty()) {
            return ResponseEntity.ok(ApiResponse.ok(menuCandidateService.getCandidatesByIds(ids)));
        }

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
