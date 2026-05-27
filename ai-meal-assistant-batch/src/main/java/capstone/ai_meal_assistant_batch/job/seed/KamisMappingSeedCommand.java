package capstone.ai_meal_assistant_batch.job.seed;

import java.io.IOException;
import java.io.InputStream;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;

import com.fasterxml.jackson.databind.ObjectMapper;

import capstone.ai_meal_assistant_batch.domain.ingredient.entity.Ingredient;
import capstone.ai_meal_assistant_batch.domain.ingredient.entity.IngredientKamisMapping;
import capstone.ai_meal_assistant_batch.domain.ingredient.repository.IngredientKamisMappingRepository;
import capstone.ai_meal_assistant_batch.domain.ingredient.repository.IngredientRepository;
import capstone.ai_meal_assistant_batch.global.log.BatchLog;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

/**
 * kamis-mapping-seed.json 을 읽어 ingredient_kamis_mappings 테이블을 seed 합니다.
 * confirmed=true 매핑이 없는 재료에 한해서만 INSERT (멱등).
 *
 * 실행: --batch.seed.kamis-mapping.enabled=true
 * 또는 application.yml: batch.seed.kamis-mapping.enabled: true
 */
@Slf4j
@Component
@RequiredArgsConstructor
@ConditionalOnProperty(prefix = "batch.seed.kamis-mapping", name = "enabled", havingValue = "true")
public class KamisMappingSeedCommand implements ApplicationRunner {

    private static final String JOB_NAME = "kamisMappingSeed";
    private static final String SEED_FILE = "kamis-mapping-seed.json";

    private final IngredientRepository ingredientRepository;
    private final IngredientKamisMappingRepository mappingRepository;
    private final ObjectMapper objectMapper;

    @Override
    public void run(ApplicationArguments args) throws Exception {
        Instant start = BatchLog.start(JOB_NAME);
        try {
            List<SeedEntry> entries = loadSeedFile();
            log.info("[{}] seed 파일 로드 완료: {}건", JOB_NAME, entries.size());

            int inserted = 0;
            int skipped = 0;

            for (SeedEntry entry : entries) {
                // confirmed=true 매핑이 이미 있으면 스킵 (멱등)
                Optional<Ingredient> ingredientOpt = ingredientRepository.findByName(entry.ingredientName());
                if (ingredientOpt.isEmpty()) {
                    log.debug("[{}] 재료 없음 — skip: {}", JOB_NAME, entry.ingredientName());
                    skipped++;
                    continue;
                }

                Ingredient ingredient = ingredientOpt.get();

                if (mappingRepository.existsByIngredientIdAndConfirmedTrue(ingredient.getId())) {
                    skipped++;
                    continue;
                }

                mappingRepository.save(IngredientKamisMapping.builder()
                        .ingredient(ingredient)
                        .ingredientName(entry.ingredientName())
                        .kamisItemCode(entry.kamisItemCode())
                        .kamisItemName(entry.kamisItemName())
                        .confirmed(true)
                        .build());
                inserted++;
            }

            log.info("[{}] 완료 — inserted={}, skipped={}", JOB_NAME, inserted, skipped);
            BatchLog.success(JOB_NAME, start,
                    java.util.Map.of("inserted", inserted, "skipped", skipped, "total", entries.size()));

        } catch (Exception e) {
            BatchLog.fail(JOB_NAME, start, e);
            throw e;
        }
    }

    private List<SeedEntry> loadSeedFile() {
        ClassPathResource resource = new ClassPathResource(SEED_FILE);
        try (InputStream is = resource.getInputStream()) {
            SeedEntry[] arr = objectMapper.readValue(is, SeedEntry[].class);
            return List.of(arr);
        } catch (IOException e) {
            throw new IllegalStateException("Failed to load " + SEED_FILE, e);
        }
    }

    record SeedEntry(String ingredientName, String kamisItemCode, String kamisItemName) {}
}
