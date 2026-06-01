package capstone.ai_meal_assistant_backend.domain.notification.controller;

import capstone.ai_meal_assistant_backend.domain.notification.service.NotificationService;
import capstone.ai_meal_assistant_backend.global.security.JwtUtil;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.RequiredArgsConstructor;
import lombok.Setter;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationService notificationService;
    private final JwtUtil jwtUtil;

    @PostMapping("/token")
    public ResponseEntity<?> registerToken(
            @RequestHeader(value = "Authorization", required = false) String authHeader,
            @RequestBody TokenRequest request) {
        String email = extractEmail(authHeader);
        if (email == null) return unauthorized();
        notificationService.registerToken(email, request.getFcmToken(), request.getPlatform());
        return ResponseEntity.ok(Map.of("success", true));
    }

    @PostMapping("/alerts")
    public ResponseEntity<?> follow(
            @RequestHeader(value = "Authorization", required = false) String authHeader,
            @RequestBody AlertRequest request) {
        String email = extractEmail(authHeader);
        if (email == null) return unauthorized();
        notificationService.follow(email, request.getKamisItemCode(), request.getKamisItemName());
        return ResponseEntity.ok(Map.of("success", true));
    }

    @DeleteMapping("/alerts/{kamisItemCode}")
    public ResponseEntity<?> unfollow(
            @RequestHeader(value = "Authorization", required = false) String authHeader,
            @PathVariable("kamisItemCode") String kamisItemCode) {
        String email = extractEmail(authHeader);
        if (email == null) return unauthorized();
        notificationService.unfollow(email, kamisItemCode);
        return ResponseEntity.ok(Map.of("success", true));
    }

    @GetMapping("/alerts/{kamisItemCode}/status")
    public ResponseEntity<?> followStatus(
            @RequestHeader(value = "Authorization", required = false) String authHeader,
            @PathVariable("kamisItemCode") String kamisItemCode) {
        String email = extractEmail(authHeader);
        if (email == null) return unauthorized();
        boolean following = notificationService.isFollowing(email, kamisItemCode);
        return ResponseEntity.ok(Map.of("success", true, "following", following));
    }

    @GetMapping("/alerts")
    public ResponseEntity<?> myAlerts(
            @RequestHeader(value = "Authorization", required = false) String authHeader) {
        String email = extractEmail(authHeader);
        if (email == null) return unauthorized();
        return ResponseEntity.ok(Map.of("success", true, "data", notificationService.getMyAlerts(email)));
    }

    private String extractEmail(String authHeader) {
        if (authHeader == null || !authHeader.startsWith("Bearer ")) return null;
        return jwtUtil.getEmailFromToken(authHeader.substring(7));
    }

    private ResponseEntity<?> unauthorized() {
        return ResponseEntity.status(401).body(Map.of("success", false, "error", "인증이 필요합니다."));
    }

    @Getter @Setter @NoArgsConstructor
    static class TokenRequest {
        private String fcmToken;
        private String platform;
    }

    @Getter @Setter @NoArgsConstructor
    static class AlertRequest {
        private String kamisItemCode;
        private String kamisItemName;
    }
}
