package capstone.ai_meal_assistant_batch.domain.ingredient.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.concurrent.atomic.AtomicBoolean;

/**
 * 손상 이미지 복구의 동시 실행을 막는 가드(guard).
 *
 * <p>중복 실행 방지 플래그({@link AtomicBoolean})만 소유하고, 실제 비동기 실행은
 * 별도 빈인 {@link ImageRecoveryTask}에 위임한다. @Async는 프록시를 거쳐 호출될 때만
 * 동작하므로, 같은 클래스 내부 호출(self-invocation)이 되지 않도록 실행 본체를
 * 반드시 다른 빈으로 분리해야 한다.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class ImageRecoveryAsyncRunner {

    private final ImageRecoveryTask imageRecoveryTask;
    private final AtomicBoolean running = new AtomicBoolean(false);

    /**
     * @return 새 작업이 시작되었으면 true, 이미 진행 중이라 거부됐으면 false.
     */
    public boolean tryStart() {
        if (!running.compareAndSet(false, true)) {
            log.info("[복구] 이미 진행 중 — 새 요청 거부");
            return false;
        }
        try {
            // 다른 빈의 public @Async 메서드 → 프록시 경유 → 백그라운드 스레드에서 실행.
            imageRecoveryTask.run(running);
        } catch (RuntimeException e) {
            // 비동기 디스패치 자체가 실패한 경우 플래그가 영구히 잠기지 않도록 해제.
            running.set(false);
            log.error("[복구] 비동기 작업 디스패치 실패", e);
            throw e;
        }
        return true;
    }
}
