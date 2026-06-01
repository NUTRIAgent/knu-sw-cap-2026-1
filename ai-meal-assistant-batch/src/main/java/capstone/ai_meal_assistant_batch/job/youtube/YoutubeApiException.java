package capstone.ai_meal_assistant_batch.job.youtube;

/**
 * YouTube API 호출이 실패(할당량 초과, 키 미설정 등)해 배치를 중단시켜야 할 때 던진다.
 */
public class YoutubeApiException extends RuntimeException {

    public YoutubeApiException(String message) {
        super(message);
    }

    public YoutubeApiException(String message, Throwable cause) {
        super(message, cause);
    }
}
