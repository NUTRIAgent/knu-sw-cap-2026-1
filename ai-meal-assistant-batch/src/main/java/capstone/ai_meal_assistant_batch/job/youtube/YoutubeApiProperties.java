package capstone.ai_meal_assistant_batch.job.youtube;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;

import java.util.List;

@Getter
@Setter
@ConfigurationProperties(prefix = "batch.youtube.api")
public class YoutubeApiProperties {

    /**
     * YouTube Data API v3 base URL
     */
    private String baseUrl = "https://www.googleapis.com/youtube/v3";

    /**
     * 환경변수 YOUTUBE_API_KEY 로 주입.
     * 미설정 시에도 앱은 정상 부팅하고, 매핑 엔드포인트 호출 시점에만 검증한다.
     */
    private String apiKey = "";

    /**
     * 검색 지역 코드 (한국 요리 영상 우선)
     */
    private String regionCode = "KR";

    /**
     * 검색 우선 언어
     */
    private String relevanceLanguage = "ko";

    /**
     * 메뉴명에 붙이는 검색 의도 키워드 (예: "김치찌개 레시피")
     */
    private String querySuffix = "레시피";

    /**
     * 검색 후보 수. 1순위가 부적합(반려동물/숏츠 등)일 때 대안을 고르기 위해 여러 개 받는다.
     * search 비용은 maxResults와 무관하게 호출당 100 units 고정.
     */
    private int maxResults = 10;

    /**
     * 영상 길이 필터: any / short(<4분) / medium(4~20분) / long(>20분).
     * 숏츠는 4분 미만이므로 medium 으로 두면 숏츠가 구조적으로 제외된다.
     */
    private String videoDuration = "medium";

    /**
     * 제목/설명/채널명에 이 키워드가 포함되면 제외 (반려동물·숏츠 등 오매칭 차단).
     * 비교는 소문자 기준.
     */
    private List<String> excludeKeywords = List.of(
            "강아지", "반려", "애견", "댕댕", "수제간식", "펫", "고양이", "냥이",
            "dog", "puppy", "pet", "cat", "#shorts", "쇼츠");
}
