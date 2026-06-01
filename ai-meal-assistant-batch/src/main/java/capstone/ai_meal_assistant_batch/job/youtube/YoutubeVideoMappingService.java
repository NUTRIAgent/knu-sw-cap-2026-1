package capstone.ai_meal_assistant_batch.job.youtube;

import capstone.ai_meal_assistant_batch.domain.menu.entity.Menu;
import capstone.ai_meal_assistant_batch.domain.menu.repository.MenuRepository;
import capstone.ai_meal_assistant_batch.global.log.BatchLog;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

/**
 * 메뉴별로 YouTube Data API를 검색해 대표 영상 videoId를 Menu.youtubeVideoId에 적재한다.
 *
 * 특징:
 * - idempotent: 이미 videoId가 있는 메뉴는 건너뜀 → 재실행/할당량 분할 안전
 * - 매핑한 메뉴는 즉시 저장 → 할당량 초과로 중단돼도 진행분은 보존(재실행 시 이어서 진행)
 * - dryRun: DB 저장 없이 검색만 수행해 결과를 미리 확인
 *
 * 긴 트랜잭션을 피하기 위해 메서드 전체를 @Transactional로 묶지 않고,
 * 매핑 건마다 save(merge)로 개별 반영한다.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class YoutubeVideoMappingService {

    private static final String JOB_NAME = "youtubeVideoMapping";

    private final MenuRepository menuRepository;
    private final YoutubeSearchClient youtubeSearchClient;

    public YoutubeVideoMappingResult mapVideos(boolean dryRun, Integer limit) {
        Instant start = BatchLog.start(JOB_NAME + (dryRun ? "(dryRun)" : ""));
        try {
            // id 오름차순 고정 → 매 실행 재현 가능, 진행 추적 용이
            List<Menu> menus = menuRepository.findAll(Sort.by(Sort.Direction.ASC, "id"));
            int total = menus.size();
            int targeted = 0;
            int updated = 0;
            int notFound = 0;

            for (Menu menu : menus) {
                String existing = menu.getYoutubeVideoId();
                if (existing != null && !existing.isBlank()) {
                    continue; // 이미 매핑됨 → skip
                }
                if (limit != null && targeted >= limit) {
                    break;
                }
                targeted++;

                Optional<String> videoId = youtubeSearchClient.searchVideoId(menu.getName());
                if (videoId.isEmpty()) {
                    notFound++;
                    log.info("[YouTube] 미발견 menuId={} name={}", menu.getId(), menu.getName());
                    continue;
                }

                updated++;
                if (!dryRun) {
                    menu.updateYoutubeVideoId(videoId.get());
                    menuRepository.save(menu);
                }
                log.info("[YouTube] 매핑 menuId={} name={} videoId={}{}",
                        menu.getId(), menu.getName(), videoId.get(),
                        dryRun ? " (dryRun)" : "");
            }

            YoutubeVideoMappingResult result =
                    new YoutubeVideoMappingResult(total, targeted, updated, notFound, dryRun);
            BatchLog.success(JOB_NAME, start, result);
            return result;
        } catch (Exception e) {
            BatchLog.fail(JOB_NAME, start, e);
            throw e;
        }
    }
}
