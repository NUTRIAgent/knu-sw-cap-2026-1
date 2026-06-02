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
     * 트랜잭션 안에서 DB 조회만 완료한 뒤, 트랜잭션 밖에서 FCM 발송.
     * (외부 네트워크 I/O 동안 DB 커넥션 점유 방지)
     */
    public void dispatchAlerts() {
        log.info("[알림] 가격 변동 알림 발송 시작 (임계값: {}%)", thresholdPercent);

        List<AlertTarget> targets = collectAlertTargets();
        if (targets.isEmpty()) {
            log.info("[알림] 발송 대상 없음");
            return;
        }

        for (AlertTarget target : targets) {
            fcmPushService.sendToTokens(target.tokens(), target.title(), target.body());
        }
        log.info("[알림] 발송 완료 — {}개 재료 알림 처리", targets.size());
    }

    /** DB 조회 전용 — 트랜잭션 내에서 알림 대상 리스트를 모두 수집해 반환. */
    @Transactional(readOnly = true)
    public List<AlertTarget> collectAlertTargets() {
        List<IngredientKamisPrice> kamisPrices = findLatestKamisPrices();
        List<AlertTarget> targets = new java.util.ArrayList<>();

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

            targets.add(new AlertTarget(tokens, title, body));
        }
        return targets;
    }

    public record AlertTarget(List<String> tokens, String title, String body) {}

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
