package capstone.ai_meal_assistant_backend.domain.notification.service;

import capstone.ai_meal_assistant_backend.domain.ingredient.entity.Ingredient;
import capstone.ai_meal_assistant_backend.domain.ingredient.repository.IngredientRepository;
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
    private final IngredientRepository ingredientRepository;
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
    public void follow(String email, Long ingredientId) {
        User user = findUser(email);
        Ingredient ingredient = findIngredient(ingredientId);
        if (!alertRepository.existsByUserAndIngredient(user, ingredient)) {
            alertRepository.save(UserIngredientAlert.builder()
                    .user(user)
                    .ingredient(ingredient)
                    .build());
        }
    }

    @Transactional
    public void unfollow(String email, Long ingredientId) {
        User user = findUser(email);
        Ingredient ingredient = findIngredient(ingredientId);
        alertRepository.deleteByUserAndIngredient(user, ingredient);
    }

    @Transactional(readOnly = true)
    public boolean isFollowing(String email, Long ingredientId) {
        User user = findUser(email);
        Ingredient ingredient = findIngredient(ingredientId);
        return alertRepository.existsByUserAndIngredient(user, ingredient);
    }

    @Transactional(readOnly = true)
    public List<Map<String, Object>> getMyAlerts(String email) {
        User user = findUser(email);
        return alertRepository.findByUser(user).stream()
                .map(a -> Map.<String, Object>of(
                        "ingredientId", a.getIngredient().getId(),
                        "ingredientName", a.getIngredient().getName()))
                .collect(Collectors.toList());
    }

    private User findUser(String email) {
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));
    }

    private Ingredient findIngredient(Long id) {
        return ingredientRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("재료를 찾을 수 없습니다. id=" + id));
    }
}
