package capstone.ai_meal_assistant_backend.domain.notification.service;

import capstone.ai_meal_assistant_backend.domain.notification.entity.UserDeviceToken;
import capstone.ai_meal_assistant_backend.domain.notification.entity.UserIngredientAlert;
import capstone.ai_meal_assistant_backend.domain.notification.repository.UserDeviceTokenRepository;
import capstone.ai_meal_assistant_backend.domain.notification.repository.UserIngredientAlertRepository;
import capstone.ai_meal_assistant_backend.domain.user.entity.User;
import capstone.ai_meal_assistant_backend.domain.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class NotificationService {

    private final UserRepository userRepository;
    private final UserDeviceTokenRepository deviceTokenRepository;
    private final UserIngredientAlertRepository alertRepository;

    @Transactional
    public void registerToken(String email, String fcmToken, String platform) {
        User user = findUser(email);
        deviceTokenRepository.findByUserAndFcmToken(user, fcmToken)
                .orElseGet(() -> deviceTokenRepository.save(
                        UserDeviceToken.builder()
                                .user(user)
                                .fcmToken(fcmToken)
                                .platform(platform)
                                .build()));
    }

    @Transactional
    public void follow(String email, String kamisItemCode, String kamisItemName) {
        User user = findUser(email);
        if (!alertRepository.existsByUserAndKamisItemCode(user, kamisItemCode)) {
            alertRepository.save(UserIngredientAlert.builder()
                    .user(user)
                    .kamisItemCode(kamisItemCode)
                    .kamisItemName(kamisItemName)
                    .build());
        }
    }

    @Transactional
    public void unfollow(String email, String kamisItemCode) {
        User user = findUser(email);
        alertRepository.deleteByUserAndKamisItemCode(user, kamisItemCode);
    }

    @Transactional(readOnly = true)
    public boolean isFollowing(String email, String kamisItemCode) {
        User user = findUser(email);
        return alertRepository.existsByUserAndKamisItemCode(user, kamisItemCode);
    }

    @Transactional(readOnly = true)
    public List<Map<String, Object>> getMyAlerts(String email) {
        User user = findUser(email);
        return alertRepository.findByUser(user).stream()
                .map(a -> Map.<String, Object>of(
                        "kamisItemCode", a.getKamisItemCode(),
                        "kamisItemName", a.getKamisItemName()))
                .collect(Collectors.toList());
    }

    private User findUser(String email) {
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));
    }
}
