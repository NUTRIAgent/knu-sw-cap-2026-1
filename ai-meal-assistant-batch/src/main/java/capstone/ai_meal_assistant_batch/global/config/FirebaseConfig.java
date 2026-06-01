package capstone.ai_meal_assistant_batch.global.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.Resource;

import jakarta.annotation.PostConstruct;
import java.io.IOException;
import java.io.InputStream;

@Slf4j
@Configuration
public class FirebaseConfig {

    @Value("${firebase.service-account-path}")
    private Resource serviceAccountResource;

    @PostConstruct
    public void init() {
        if (!FirebaseApp.getApps().isEmpty()) return;
        try (InputStream is = serviceAccountResource.getInputStream()) {
            FirebaseOptions options = FirebaseOptions.builder()
                    .setCredentials(GoogleCredentials.fromStream(is))
                    .build();
            FirebaseApp.initializeApp(options);
            log.info("[Firebase] Admin SDK 초기화 완료");
        } catch (IOException e) {
            log.warn("[Firebase] 서비스 계정 파일 없음 — FCM 알림 비활성화: {}", e.getMessage());
        }
    }
}
