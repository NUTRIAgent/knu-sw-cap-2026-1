package capstone.ai_meal_assistant_batch.job.naver;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.util.UriComponentsBuilder;

import java.net.URI;
import java.util.List;

@Component
@RequiredArgsConstructor
public class NaverShoppingClient {

    private final NaverShoppingApiProperties properties;
    private final RestClient restClient = RestClient.create();

    public List<NaverShoppingItem> search(String query) {
        URI uri = UriComponentsBuilder
                .fromUriString(properties.getBaseUrl())
                .path("/v1/search/shop.json")
                .queryParam("query", query)
                .queryParam("display", properties.getDisplayCount())
                .queryParam("sort", "sim")
                .build()
                .encode()
                .toUri();

        NaverShoppingResponse response = restClient.get()
                .uri(uri)
                .header("X-Naver-Client-Id", properties.getClientId())
                .header("X-Naver-Client-Secret", properties.getClientSecret())
                .retrieve()
                .body(NaverShoppingResponse.class);

        if (response == null || response.items() == null) return List.of();
        return response.items();
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    private record NaverShoppingResponse(int total, List<NaverShoppingItem> items) {}
}
