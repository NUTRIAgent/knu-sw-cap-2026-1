package capstone.ai_meal_assistant_batch.job.seed;

import java.time.Instant;

import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import capstone.ai_meal_assistant_batch.domain.ingredient.service.RecipeDataSyncService;
import capstone.ai_meal_assistant_batch.global.log.BatchLog;
import lombok.RequiredArgsConstructor;

// 재료(menu_ingredients)만 단독 재적재 — 파싱 로직 수정 후 기존 데이터 교정 시 사용
// cd ai-meal-assistant-batch
// ./gradlew bootRun --args='--batch.seed.recipe-ingredients.enabled=true'

@Component
@RequiredArgsConstructor
@ConditionalOnProperty(prefix = "batch.seed.recipe-ingredients", name = "enabled", havingValue = "true")
public class RecipeIngredientSeedCommand implements ApplicationRunner {

    private static final String JOB_NAME = "recipeIngredientSeed";

    private final RecipeDataSyncService recipeDataSyncService;

    @Override
    public void run(ApplicationArguments args) {
        Instant start = BatchLog.start(JOB_NAME);
        try {
            recipeDataSyncService.syncIngredientsOnly();
            BatchLog.success(JOB_NAME, start, "re-seeded menu_ingredients via cleaned_recipe_data.json");
        } catch (Exception e) {
            BatchLog.fail(JOB_NAME, start, e);
            throw e;
        }
    }
}
