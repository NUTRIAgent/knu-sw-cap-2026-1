package capstone.ai_meal_assistant_backend.domain.history.controller;

import capstone.ai_meal_assistant_backend.domain.history.dto.RecommendationLogResponse;
import capstone.ai_meal_assistant_backend.domain.history.service.RecommendationLogService;
import capstone.ai_meal_assistant_backend.global.security.JwtUtil;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.RequiredArgsConstructor;
import lombok.Setter;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
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
        recommendationLogService.saveFeedback(email, request.getMenuId(),
                request.getFeedbackScore(), request.getStarRating(), request.getFeedbackReason());
        return ResponseEntity.ok(Map.of("success", true));
    }

    @GetMapping("/my")
    public ResponseEntity<?> getMyFeedbacks(
            @RequestHeader(value = "Authorization", required = false) String authHeader) {

        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            return ResponseEntity.status(401).body(Map.of("success", false, "error", "인증이 필요합니다."));
        }

        String email = jwtUtil.getEmailFromToken(authHeader.substring(7));
        List<RecommendationLogResponse> feedbacks = recommendationLogService.getUserFeedbacks(email);
        return ResponseEntity.ok(Map.of("success", true, "data", feedbacks));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteFeedback(
            @RequestHeader(value = "Authorization", required = false) String authHeader,
            @PathVariable("id") Long id) {

        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            return ResponseEntity.status(401).body(Map.of("success", false, "error", "인증이 필요합니다."));
        }

        String email = jwtUtil.getEmailFromToken(authHeader.substring(7));
        try {
            recommendationLogService.deleteFeedback(email, id);
            return ResponseEntity.ok(Map.of("success", true));
        } catch (SecurityException e) {
            return ResponseEntity.status(403).body(Map.of("success", false, "error", e.getMessage()));
        }
    }

    @Getter
    @Setter
    @NoArgsConstructor
    static class FeedbackRequest {
        private Long menuId;
        private Integer feedbackScore;  // 후보 좋아요/싫어요: 1 or -1
        private Integer starRating;     // AI 픽 별점: 1~5
        private String feedbackReason;
    }
}
