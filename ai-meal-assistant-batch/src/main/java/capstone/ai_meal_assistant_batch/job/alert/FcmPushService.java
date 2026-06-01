package capstone.ai_meal_assistant_batch.job.alert;

import com.google.firebase.FirebaseApp;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;

@Slf4j
@Service
public class FcmPushService {

    /**
     * 여러 FCM 토큰에 알림을 개별 발송한다.
     * Firebase Admin SDK가 초기화되지 않았으면 조용히 스킵.
     */
    public void sendToTokens(List<String> tokens, String title, String body) {
        if (FirebaseApp.getApps().isEmpty()) {
            log.warn("[FCM] Firebase 미초기화 — 알림 스킵 (토큰 {}개)", tokens.size());
            return;
        }
        if (tokens.isEmpty()) return;

        for (String token : tokens) {
            try {
                Message message = Message.builder()
                        .setToken(token)
                        .setNotification(Notification.builder()
                                .setTitle(title)
                                .setBody(body)
                                .build())
                        .build();
                FirebaseMessaging.getInstance().send(message);
            } catch (Exception e) {
                log.warn("[FCM] 알림 발송 실패 (토큰 일부 무효 가능): {}", e.getMessage());
            }
        }
        log.info("[FCM] 알림 발송 완료 — 대상 {}개, 제목: {}", tokens.size(), title);
    }
}
