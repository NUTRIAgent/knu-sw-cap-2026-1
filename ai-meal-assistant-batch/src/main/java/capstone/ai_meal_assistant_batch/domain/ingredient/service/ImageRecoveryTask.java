package capstone.ai_meal_assistant_batch.domain.ingredient.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;

import java.util.concurrent.atomic.AtomicBoolean;

/**
 * 손상 이미지 복구의 실제 비동기 실행 본체.
 *
 * <p>@Async는 Spring 프록시를 통해 호출될 때만 동작한다. 따라서 호출자(가드 역할의
 * {@link ImageRecoveryAsyncRunner})와 반드시 <b>다른 빈</b>에 두고, 메서드는
 * <b>public</b>으로 선언해야 한다. (같은 클래스 내부 호출 = self-invocation 은 프록시를
 * 우회하여 @Async 가 무시되고, package-private 메서드는 어드바이스 대상에서 제외된다.)
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class ImageRecoveryTask {

    private final RecipeDataSyncService recipeDataSyncService;

    /**
     * 백그라운드 스레드에서 손상 이미지 복구를 수행한다.
     *
     * @param running 호출자가 소유한 진행 상태 플래그. 작업 종료 시 false 로 되돌린다.
     */
    @Async
    public void run(AtomicBoolean running) {
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
