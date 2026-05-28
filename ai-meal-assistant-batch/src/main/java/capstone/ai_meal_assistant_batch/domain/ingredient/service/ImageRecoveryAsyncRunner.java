package capstone.ai_meal_assistant_batch.domain.ingredient.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;

import java.util.concurrent.atomic.AtomicBoolean;

/**
 * 손상 이미지 복구를 백그라운드 스레드에서 비동기 실행한다.
 * 같은 클래스 내부에서 @Async 메서드를 호출하면 Spring 프록시를 거치지 않으므로
 * RecipeDataSyncService와 분리된 별도 빈으로 둔다.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class ImageRecoveryAsyncRunner {

    private final RecipeDataSyncService recipeDataSyncService;
    private final AtomicBoolean running = new AtomicBoolean(false);

    /**
     * @return 새 작업이 시작되었으면 true, 이미 진행 중이라 거부됐으면 false.
     */
    public boolean tryStart() {
        if (!running.compareAndSet(false, true)) {
            log.info("[복구] 이미 진행 중 — 새 요청 거부");
            return false;
        }
        runAsync();
        return true;
    }

    @Async
    void runAsync() {
        try {
            log.info("[복구] 비동기 작업 시작");
            recipeDataSyncService.recoverCorruptedImages();
        } catch (Exception e) {
            log.error("[복구] 비동기 실행 중 오류", e);
        } finally {
            running.set(false);
        }
    }
}
