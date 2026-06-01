package capstone.ai_meal_assistant_batch.job.alert;

import capstone.ai_meal_assistant_batch.domain.ingredient.entity.IngredientPrice;
import capstone.ai_meal_assistant_batch.domain.ingredient.repository.IngredientPriceRepository;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class PriceAlertNotificationService {

    private static final String KAMIS_SOURCE = "KAMIS_DAILY_SALES";

    @Value("${price-alert.change-threshold-percent:3.0}")
    private double thresholdPercent;

    private final IngredientPriceRepository ingredientPriceRepository;
    private final FcmPushService fcmPushService;

    @PersistenceContext
    private EntityManager entityManager;

    /**
     * KAMIS 가격 갱신 후 호출. 변동률 ≥ threshold인 재료의 팔로워에게 FCM 발송.
     */
    @Transactional(readOnly = true)
    public void dispatchAlerts() {
        log.info("[알림] 가격 변동 알림 발송 시작 (임계값: {}%)", thresholdPercent);

        List<IngredientPrice> kamisPrices = ingredientPriceRepository
                .findAllBySourceApi(KAMIS_SOURCE);

        int dispatched = 0;
        for (IngredientPrice price : kamisPrices) {
            if (price.getOriginalPrice() == null || price.getPrevDayPrice() == null
                    || price.getPrevDayPrice() == 0) continue;

            double changeRate = (price.getOriginalPrice() - price.getPrevDayPrice())
                    / (double) price.getPrevDayPrice() * 100.0;

            if (Math.abs(changeRate) < thresholdPercent) continue;

            Long ingredientId = price.getIngredient().getId();
            List<String> tokens = findFcmTokensByIngredientId(ingredientId);
            if (tokens.isEmpty()) continue;

            String ingredientName = price.getIngredient().getName();
            String direction = changeRate > 0 ? "▲" : "▼";
            String title = String.format("📊 %s 가격 변동", ingredientName);
            String body = String.format("%s %.1f%% 변동 (%,d원 → %,d원)",
                    direction, Math.abs(changeRate),
                    price.getPrevDayPrice(), price.getOriginalPrice());

            fcmPushService.sendToTokens(tokens, title, body);
            dispatched++;
        }
        log.info("[알림] 발송 완료 — {}개 재료 알림 처리", dispatched);
    }

    @SuppressWarnings("unchecked")
    private List<String> findFcmTokensByIngredientId(Long ingredientId) {
        try {
            return entityManager.createNativeQuery(
                            """
                            SELECT t.fcm_token
                            FROM user_ingredient_alerts a
                            JOIN user_device_tokens t ON t.user_id = a.user_id
                            WHERE a.ingredient_id = :ingredientId
                            """)
                    .setParameter("ingredientId", ingredientId)
                    .getResultList();
        } catch (Exception e) {
            log.warn("[알림] FCM 토큰 조회 실패 (테이블 미존재 가능): {}", e.getMessage());
            return List.of();
        }
    }
}
