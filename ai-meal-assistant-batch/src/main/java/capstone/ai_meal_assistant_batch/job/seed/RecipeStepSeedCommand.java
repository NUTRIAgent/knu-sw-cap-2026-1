package capstone.ai_meal_assistant_batch.job.seed;

import java.time.Instant;

import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import capstone.ai_meal_assistant_batch.domain.ingredient.service.RecipeDataSyncService;
import capstone.ai_meal_assistant_batch.global.log.BatchLog;
import lombok.RequiredArgsConstructor;

// 조리단계(menu_steps)만 단독 적재 — S3 업로드 없이 빠르게 실행
// cd ai-meal-assistant-batch
// ./gradlew bootRun --args='--batch.seed.steps.enabled=true'

@Component
@RequiredArgsConstructor
@ConditionalOnProperty(prefix = "batch.seed.steps", name = "enabled", havingValue = "true")
public class RecipeStepSeedCommand implements ApplicationRunner {

    private static final String JOB_NAME = "recipeStepSeed";

    private final RecipeDataSyncService recipeDataSyncService;

    @Override
    public void run(ApplicationArguments args) {
        Instant start = BatchLog.start(JOB_NAME);
        try {
            recipeDataSyncService.syncStepsOnly();
            BatchLog.success(JOB_NAME, start, "seeded menu_steps via cleaned_recipe_data.json");
        } catch (Exception e) {
            BatchLog.fail(JOB_NAME, start, e);
            throw e;
        }
    }
}
