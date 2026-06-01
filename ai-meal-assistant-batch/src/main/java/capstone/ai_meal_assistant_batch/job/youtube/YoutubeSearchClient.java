package capstone.ai_meal_assistant_batch.job.youtube;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.client.HttpStatusCodeException;
import org.springframework.web.client.RestClient;
import org.springframework.web.util.UriComponentsBuilder;

import java.net.URI;
import java.util.List;
import java.util.Optional;

/**
 * YouTube Data API v3 search 호출 클라이언트.
 * 메뉴명으로 임베드 가능한 대표 영상 1건의 videoId를 찾는다.
 */
@Slf4j
@Component
public class YoutubeSearchClient {

    private final YoutubeApiProperties properties;
    private final ObjectMapper objectMapper;
    private final RestClient restClient = RestClient.create();

    public YoutubeSearchClient(YoutubeApiProperties properties, ObjectMapper objectMapper) {
        this.properties = properties;
        this.objectMapper = objectMapper;
    }

    /**
     * @return 대표 videoId. 적절한 임베드 가능 영상이 없으면 Optional.empty()
     * @throws YoutubeApiException HTTP 오류(할당량 초과 등) — 배치 전체를 중단시킨다.
     */
    public Optional<String> searchVideoId(String menuName) {
        if (properties.getApiKey() == null || properties.getApiKey().isBlank()) {
            throw new YoutubeApiException("YOUTUBE_API_KEY가 설정되지 않았습니다. 환경변수를 확인하세요.");
        }

        String query = (menuName + " " + properties.getQuerySuffix()).trim();
        URI uri = UriComponentsBuilder
                .fromUriString(properties.getBaseUrl())
                .path("/search")
                .queryParam("part", "snippet")
                .queryParam("q", query)
                .queryParam("type", "video")
                .queryParam("videoEmbeddable", "true") // 임베드 불가 영상 제외(앱에서 재생 깨짐 방지)
                .queryParam("videoDuration", properties.getVideoDuration()) // medium=4~20분 → 숏츠(4분 미만) 제외
                .queryParam("maxResults", properties.getMaxResults())
                .queryParam("regionCode", properties.getRegionCode())
                .queryParam("relevanceLanguage", properties.getRelevanceLanguage())
                .queryParam("key", properties.getApiKey())
                .build()
                .encode()
                .toUri();

        String raw;
        try {
            raw = restClient.get()
                    .uri(uri)
                    .header("User-Agent", "NUTRIAgent/1.0")
                    .header("Accept", "application/json")
                    .retrieve()
                    .body(String.class);
        } catch (HttpStatusCodeException e) {
            // 할당량 초과(403 quotaExceeded)/레이트리밋(429) 등 — 원문 덤프 후 배치 중단
            log.error("[YouTube][ERROR] HTTP {} query=\"{}\" body={}",
                    e.getStatusCode(), query, e.getResponseBodyAsString());
            throw new YoutubeApiException(
                    "YouTube API 호출 실패(status=" + e.getStatusCode() + "). 할당량/키를 확인하세요.", e);
        }

        try {
            SearchResponse response = objectMapper.readValue(raw, SearchResponse.class);
            if (response == null || response.items() == null || response.items().isEmpty()) {
                return Optional.empty();
            }
            // 후보를 순서대로 보며 반려동물/숏츠 등 부적합 영상은 건너뛰고 첫 통과 영상을 채택
            for (SearchItem item : response.items()) {
                if (item.id() == null || item.id().videoId() == null || item.id().videoId().isBlank()) {
                    continue;
                }
                if (isExcluded(item.snippet())) {
                    log.info("[YouTube] 제외(부적합) query=\"{}\" title=\"{}\"",
                            query, item.snippet() != null ? item.snippet().title() : null);
                    continue;
                }
                return Optional.of(item.id().videoId());
            }
            return Optional.empty();
        } catch (YoutubeApiException e) {
            throw e;
        } catch (Exception parseEx) {
            // 파싱 실패: 원문 덤프 후 해당 메뉴만 건너뜀(배치는 계속)
            log.error("[YouTube][ERROR] 응답 파싱 실패 query=\"{}\" raw={}", query, raw, parseEx);
            return Optional.empty();
        }
    }

    /**
     * 제목/설명/채널명에 차단 키워드가 포함되면 true (소문자 비교).
     */
    private boolean isExcluded(Snippet snippet) {
        if (snippet == null) {
            return false;
        }
        String haystack = ((snippet.title() == null ? "" : snippet.title()) + " "
                + (snippet.description() == null ? "" : snippet.description()) + " "
                + (snippet.channelTitle() == null ? "" : snippet.channelTitle()))
                .toLowerCase();
        for (String keyword : properties.getExcludeKeywords()) {
            if (keyword != null && !keyword.isBlank()
                    && haystack.contains(keyword.toLowerCase())) {
                return true;
            }
        }
        return false;
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    private record SearchResponse(List<SearchItem> items) {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    private record SearchItem(Id id, Snippet snippet) {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    private record Id(String videoId) {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    private record Snippet(String title, String description, String channelTitle) {}
}
