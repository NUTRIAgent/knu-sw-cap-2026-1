package capstone.ai_meal_assistant_batch.job.alert;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * FCM 알림 테스트용 엔드포인트.
 * POST /api/admin/fcm/test?token={FCM_TOKEN}
 */
@RestController
@RequestMapping("/api/admin/fcm")
@RequiredArgsConstructor
public class FcmTestController {

    private final FcmPushService fcmPushService;
    private final PriceAlertNotificationService priceAlertNotificationService;

    /** 특정 FCM 토큰으로 테스트 알림 발송 */
    @PostMapping("/test")
    public ResponseEntity<String> testFcm(@RequestParam String token) {
        fcmPushService.sendToTokens(
                List.of(token),
                "📊 가격 변동 알림 테스트",
                "알림이 정상적으로 작동합니다! 🎉"
        );
        return ResponseEntity.ok("FCM 테스트 발송 완료");
    }

    /** 변동률 알림 즉시 실행 (배치 스케줄 기다리지 않고 수동 트리거) */
    @PostMapping("/dispatch-alerts")
    public ResponseEntity<String> dispatchAlerts() {
        priceAlertNotificationService.dispatchAlerts();
        return ResponseEntity.ok("가격 변동 알림 발송 완료. 서버 로그를 확인하세요.");
    }
}
