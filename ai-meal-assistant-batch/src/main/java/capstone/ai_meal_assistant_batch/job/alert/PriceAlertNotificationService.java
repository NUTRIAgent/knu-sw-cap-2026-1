package capstone.ai_meal_assistant_batch.job.alert;

import capstone.ai_meal_assistant_batch.domain.ingredient.entity.IngredientKamisPrice;
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

    private final FcmPushService fcmPushService;

    @PersistenceContext
    private EntityManager entityManager;

    /**
     * KAMIS 가격 갱신 후 호출.
     * ingredient_kamis_prices 테이블을 직접 조회해 변동률 감지 → FCM 발송.
     */
    @Transactional(readOnly = true)
    public void dispatchAlerts() {
        log.info("[알림] 가격 변동 알림 발송 시작 (임계값: {}%)", thresholdPercent);

        List<IngredientKamisPrice> kamisPrices = findLatestKamisPrices();

        int dispatched = 0;
        for (IngredientKamisPrice price : kamisPrices) {
            if (price.getOriginalPrice() == null || price.getPrevDayPrice() == null
                    || price.getPrevDayPrice() == 0) continue;

            double changeRate = (price.getOriginalPrice() - price.getPrevDayPrice())
                    / (double) price.getPrevDayPrice() * 100.0;

            if (Math.abs(changeRate) < thresholdPercent) continue;

            List<String> tokens = findFcmTokensByKamisItemCode(price.getKamisItemCode());
            if (tokens.isEmpty()) continue;

            String direction = changeRate > 0 ? "▲" : "▼";
            String title = String.format("📊 %s 가격 변동", price.getKamisItemName());
            String body = String.format("%s %.1f%% 변동 (%,d원 → %,d원)",
                    direction, Math.abs(changeRate),
                    price.getPrevDayPrice(), price.getOriginalPrice());

            fcmPushService.sendToTokens(tokens, title, body);
            dispatched++;
        }
        log.info("[알림] 발송 완료 — {}개 재료 알림 처리", dispatched);
    }

    @SuppressWarnings("unchecked")
    private List<IngredientKamisPrice> findLatestKamisPrices() {
        return entityManager.createNativeQuery(
                        """
                        SELECT * FROM ingredient_kamis_prices
                        WHERE id IN (
                            SELECT MAX(id) FROM ingredient_kamis_prices
                            GROUP BY kamis_item_code
                        )
                        """, IngredientKamisPrice.class)
                .getResultList();
    }

    @SuppressWarnings("unchecked")
    private List<String> findFcmTokensByKamisItemCode(String kamisItemCode) {
        try {
            return entityManager.createNativeQuery(
                            """
                            SELECT t.fcm_token
                            FROM user_ingredient_alerts a
                            JOIN user_device_tokens t ON t.user_id = a.user_id
                            WHERE a.kamis_item_code = :kamisItemCode
                            """)
                    .setParameter("kamisItemCode", kamisItemCode)
                    .getResultList();
        } catch (Exception e) {
            log.warn("[알림] FCM 토큰 조회 실패: {}", e.getMessage());
            return List.of();
        }
    }
}
