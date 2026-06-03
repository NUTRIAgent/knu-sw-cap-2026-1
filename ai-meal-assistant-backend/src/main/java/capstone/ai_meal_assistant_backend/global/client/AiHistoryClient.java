package capstone.ai_meal_assistant_backend.global.client;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.http.client.JdkClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

import java.net.http.HttpClient;
import java.util.Map;

/**
 * AI 서버(FastAPI)의 사용자 이력 RAG(/history) 연동 클라이언트.
 * 호출은 RagHistoryEventListener가 커밋 후(@TransactionalEventListener) 비동기로 트리거하며,
 * 실패는 로깅만 한다(피드백 저장 자체에는 영향 없음).
 */
@Slf4j
@Component
public class AiHistoryClient {

    private final RestClient restClient;

    public AiHistoryClient(@Value("${ai.base-url:http://localhost:8000}") String aiBaseUrl) {
        // JDK HttpClient 기본 HTTP/2(h2c 업그레이드)를 uvicorn이 거부하므로 HTTP/1.1로 고정
        HttpClient httpClient = HttpClient.newBuilder()
                .version(HttpClient.Version.HTTP_1_1)
                .build();
        this.restClient = RestClient.builder()
                .baseUrl(aiBaseUrl)
                .requestFactory(new JdkClientHttpRequestFactory(httpClient))
                .build();
    }

    public void saveHistory(String userId, Long logId, Long recipeId, String recipeName,
                            String comment, int rating) {
        try {
            restClient.post().uri("/history")
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(Map.of(
                            "user_id", userId,
                            "log_id", logId,
                            "recipe_id", String.valueOf(recipeId),
                            "recipe_name", recipeName,
                            "comment", comment == null ? "" : comment,
                            "rating", rating
                    ))
                    .retrieve()
                    .toBodilessEntity();
        } catch (Exception e) {
            log.warn("[AiHistoryClient] RAG 저장 실패 logId={}: {}", logId, e.getMessage());
        }
    }

    public void deleteHistory(Long logId) {
        try {
            restClient.delete().uri("/history/{logId}", logId)
                    .retrieve()
                    .toBodilessEntity();
        } catch (Exception e) {
            log.warn("[AiHistoryClient] RAG 삭제 실패 logId={}: {}", logId, e.getMessage());
        }
    }
}
