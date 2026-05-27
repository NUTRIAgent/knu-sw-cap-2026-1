package capstone.ai_meal_assistant_batch.job.seed;

import java.time.Instant;

import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import capstone.ai_meal_assistant_batch.domain.ingredient.service.RecipeDataSyncService;
import capstone.ai_meal_assistant_batch.global.log.BatchLog;
import lombok.RequiredArgsConstructor;

/**
 * 서버 시작 시 menu_allergies 자동 매핑 실행
 * - syncAllergyMappings()는 멱등(이미 존재하는 쌍 skip)이므로 매 시작 시 안전하게 실행 가능
 * - application.yml: batch.seed.allergies.enabled=true 로 활성화
 */
@Component
@RequiredArgsConstructor
@ConditionalOnProperty(prefix = "batch.seed.allergies", name = "enabled", havingValue = "true")
public class AllergySeedCommand implements ApplicationRunner {

    private static final String JOB_NAME = "allergySeed";

    private final RecipeDataSyncService recipeDataSyncService;

    @Override
    public void run(ApplicationArguments args) {
        Instant start = BatchLog.start(JOB_NAME);
        try {
            recipeDataSyncService.syncAllergyMappings();
            BatchLog.success(JOB_NAME, start, "menu_allergies auto-mapping complete");
        } catch (Exception e) {
            BatchLog.fail(JOB_NAME, start, e);
            throw e;
        }
    }
}
