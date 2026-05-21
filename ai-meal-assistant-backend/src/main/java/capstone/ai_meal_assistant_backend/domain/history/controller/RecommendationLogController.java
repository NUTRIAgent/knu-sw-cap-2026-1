package capstone.ai_meal_assistant_backend.domain.history.controller;

import capstone.ai_meal_assistant_backend.domain.history.service.RecommendationLogService;
import capstone.ai_meal_assistant_backend.global.security.JwtUtil;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.RequiredArgsConstructor;
import lombok.Setter;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/recommendation-logs")
@RequiredArgsConstructor
public class RecommendationLogController {

    private final RecommendationLogService recommendationLogService;
    private final JwtUtil jwtUtil;

    @PostMapping
    public ResponseEntity<?> saveFeedback(
            @RequestHeader(value = "Authorization", required = false) String authHeader,
            @RequestBody FeedbackRequest request) {

        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            return ResponseEntity.status(401).body(Map.of("success", false, "error", "인증이 필요합니다."));
        }

        String email = jwtUtil.getEmailFromToken(authHeader.substring(7));
        recommendationLogService.saveFeedback(email, request.getMenuId(), request.getFeedbackScore());
        return ResponseEntity.ok(Map.of("success", true));
    }

    @Getter
    @Setter
    @NoArgsConstructor
    static class FeedbackRequest {
        private Long menuId;
        private int feedbackScore;
    }
}
