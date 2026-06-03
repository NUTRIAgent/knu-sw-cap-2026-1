package capstone.ai_meal_assistant_backend.global.client;

/**
 * RAG(벡터DB) 동기화 도메인 이벤트.
 * 트랜잭션 커밋 이후(RagHistoryEventListener)에 AI 서버로 반영된다.
 */
public final class RagHistoryEvents {

    private RagHistoryEvents() {}

    /** 별점+코멘트 피드백 저장/갱신 → RAG 적재 */
    public record Save(
            String userId,
            Long logId,
            Long recipeId,
            String recipeName,
            String comment,
            int rating
    ) {}

    /** 피드백 삭제 → RAG 제거 */
    public record Delete(Long logId) {}
}
