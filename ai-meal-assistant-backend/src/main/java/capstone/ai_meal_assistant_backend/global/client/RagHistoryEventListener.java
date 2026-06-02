package capstone.ai_meal_assistant_backend.global.client;

import lombok.RequiredArgsConstructor;
import org.springframework.scheduling.annotation.Async;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;
import org.springframework.stereotype.Component;

/**
 * RAG 동기화 이벤트를 트랜잭션 커밋 이후(AFTER_COMMIT)에 비동기로 처리.
 * 커밋 전에 발사되어 롤백 시 RAG↔DB 불일치가 생기는 문제를 방지한다.
 */
@Component
@RequiredArgsConstructor
public class RagHistoryEventListener {

    private final AiHistoryClient aiHistoryClient;

    @Async
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onSave(RagHistoryEvents.Save e) {
        aiHistoryClient.saveHistory(
                e.userId(), e.logId(), e.recipeId(), e.recipeName(), e.comment(), e.rating());
    }

    @Async
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onDelete(RagHistoryEvents.Delete e) {
        aiHistoryClient.deleteHistory(e.logId());
    }
}
