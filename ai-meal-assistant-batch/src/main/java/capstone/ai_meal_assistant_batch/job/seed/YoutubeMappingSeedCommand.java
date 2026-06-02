package capstone.ai_meal_assistant_batch.job.seed;

import java.io.IOException;
import java.io.InputStream;
import java.time.Instant;
import java.util.List;
import java.util.Optional;

import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.core.annotation.Order;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;

import com.fasterxml.jackson.databind.ObjectMapper;

import capstone.ai_meal_assistant_batch.domain.menu.entity.Menu;
import capstone.ai_meal_assistant_batch.domain.menu.repository.MenuRepository;
import capstone.ai_meal_assistant_batch.global.log.BatchLog;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

/**
 * youtube-mapping-seed.json 을 읽어 menus.youtube_video_id 를 seed 합니다.
 * 값이 비어있는 메뉴에 한해서만 채움 (멱등 — 수동 교체/기존 값은 덮어쓰지 않음).
 *
 * 팀원은 git pull 후 배치 서버를 실행하기만 하면 로컬 DB에 매핑이 자동 반영됩니다.
 * (기본 활성. 끄려면 application.yml: batch.seed.youtube-mapping.enabled: false)
 *
 * seed 파일 갱신: YouTube 매핑 배치(map-youtube-videos)로 적재를 진행한 DB에서
 * (food_code, youtube_video_id) 목록을 다시 추출해 커밋하면 됩니다.
 */
@Slf4j
@Component
@RequiredArgsConstructor
@Order(1) // run-once 모드의 KAMIS 커맨드(System.exit)보다 먼저 실행 보장
@ConditionalOnProperty(prefix = "batch.seed.youtube-mapping", name = "enabled",
        havingValue = "true", matchIfMissing = true)
public class YoutubeMappingSeedCommand implements ApplicationRunner {

    private static final String JOB_NAME = "youtubeMappingSeed";
    private static final String SEED_FILE = "youtube-mapping-seed.json";

    private final MenuRepository menuRepository;
    private final ObjectMapper objectMapper;

    @Override
    public void run(ApplicationArguments args) throws Exception {
        Instant start = BatchLog.start(JOB_NAME);
        try {
            List<SeedEntry> entries = loadSeedFile();
            log.info("[{}] seed 파일 로드 완료: {}건", JOB_NAME, entries.size());

            int updated = 0;
            int skipped = 0;
            int missing = 0;

            for (SeedEntry entry : entries) {
                Optional<Menu> menuOpt = menuRepository.findByFoodCode(entry.foodCode());
                if (menuOpt.isEmpty()) {
                    log.debug("[{}] 메뉴 없음 — skip: foodCode={}", JOB_NAME, entry.foodCode());
                    missing++;
                    continue;
                }

                Menu menu = menuOpt.get();

                // 이미 값이 있으면 스킵 (멱등 — 수동 교체분 보존)
                if (menu.getYoutubeVideoId() != null && !menu.getYoutubeVideoId().isBlank()) {
                    skipped++;
                    continue;
                }

                menu.updateYoutubeVideoId(entry.videoId());
                menuRepository.save(menu);
                updated++;
            }

            log.info("[{}] 완료 — updated={}, skipped={}, missing={}", JOB_NAME, updated, skipped, missing);
            BatchLog.success(JOB_NAME, start,
                    java.util.Map.of("updated", updated, "skipped", skipped,
                            "missing", missing, "total", entries.size()));

        } catch (Exception e) {
            BatchLog.fail(JOB_NAME, start, e);
            throw e;
        }
    }

    private List<SeedEntry> loadSeedFile() {
        ClassPathResource resource = new ClassPathResource(SEED_FILE);
        if (!resource.exists()) {
            log.warn("[{}] {} 파일이 없어 seed를 건너뜁니다.", JOB_NAME, SEED_FILE);
            return List.of();
        }
        try (InputStream is = resource.getInputStream()) {
            SeedEntry[] arr = objectMapper.readValue(is, SeedEntry[].class);
            return List.of(arr);
        } catch (IOException e) {
            throw new IllegalStateException("Failed to load " + SEED_FILE, e);
        }
    }

    record SeedEntry(String foodCode, String videoId) {}
}
