package capstone.ai_meal_assistant_batch.job.alert;

import com.google.firebase.FirebaseApp;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.MulticastMessage;
import com.google.firebase.messaging.Notification;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;

@Slf4j
@Service
public class FcmPushService {

    private static final int FCM_BATCH_LIMIT = 500;

    /**
     * 여러 FCM 토큰에 멀티캐스트로 알림을 발송한다.
     * sendEach()로 최대 500건을 하나의 HTTP 요청으로 처리해 개별 send() 루프보다 빠르다.
     * Firebase Admin SDK가 초기화되지 않았으면 조용히 스킵.
     */
    public void sendToTokens(List<String> tokens, String title, String body) {
        if (FirebaseApp.getApps().isEmpty()) {
            log.warn("[FCM] Firebase 미초기화 — 알림 스킵 (토큰 {}개)", tokens.size());
            return;
        }
        if (tokens.isEmpty()) return;

        Notification notification = Notification.builder()
                .setTitle(title)
                .setBody(body)
                .build();

        // FCM 멀티캐스트 한 번에 최대 500건 제한 → 청크 단위로 발송
        for (int i = 0; i < tokens.size(); i += FCM_BATCH_LIMIT) {
            List<String> chunk = tokens.subList(i, Math.min(i + FCM_BATCH_LIMIT, tokens.size()));
            try {
                MulticastMessage message = MulticastMessage.builder()
                        .addAllTokens(chunk)
                        .setNotification(notification)
                        .build();
                FirebaseMessaging.getInstance().sendEachForMulticast(message);
            } catch (Exception e) {
                log.warn("[FCM] 멀티캐스트 발송 실패: {}", e.getMessage());
            }
        }
        log.info("[FCM] 알림 발송 완료 — 대상 {}개, 제목: {}", tokens.size(), title);
    }
}
