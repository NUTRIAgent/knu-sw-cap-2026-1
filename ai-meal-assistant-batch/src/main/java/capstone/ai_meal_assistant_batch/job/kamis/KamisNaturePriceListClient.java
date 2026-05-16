package capstone.ai_meal_assistant_batch.job.kamis;

import java.net.URI;
import java.time.Duration;
import java.util.Map;

import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.util.UriComponentsBuilder;

import lombok.RequiredArgsConstructor;

@Component
@RequiredArgsConstructor
public class KamisNaturePriceListClient {

	private final KamisApiProperties properties;

	private final RestClient restClient = RestClient.create();

	public String fetchXml(Map<String, String> params) {
		URI uri = buildUri(params);
		return restClient.get()
				.uri(uri)
				.accept(MediaType.APPLICATION_XML)
				.retrieve()
				.body(String.class);
	}

	private URI buildUri(Map<String, String> params) {
		String baseUrl = properties.getBaseUrl();
		if (baseUrl == null || baseUrl.isBlank()) {
			throw new IllegalStateException("batch.kamis.api.base-url is required");
		}

		UriComponentsBuilder b = UriComponentsBuilder
				.fromUriString(baseUrl)
				.path("/service/price/xml.do")
				.queryParam("action", "NaturePriceList");

		// required/common params
		if (properties.getApiKey() != null && !properties.getApiKey().isBlank()) {
			b.queryParam("p_cert_key", properties.getApiKey());
		}
		if (properties.getCertId() != null && !properties.getCertId().isBlank()) {
			b.queryParam("p_cert_id", properties.getCertId());
		}
		b.queryParam("p_returntype", properties.getReturnType() == null ? "xml" : properties.getReturnType());

		// user params
		params.forEach(b::queryParam);

		return b.build(true).toUri();
	}

	/**
	 * 개발/디버깅용 기본 타임아웃(네트워크 이슈가 잦아서 호출부에서 재시도 권장)
	 */
	public Duration defaultTimeout() {
		return Duration.ofSeconds(10);
	}
}
