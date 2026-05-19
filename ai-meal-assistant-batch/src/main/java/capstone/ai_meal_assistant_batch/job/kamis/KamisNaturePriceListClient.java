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
		String rawUrl = uri.toString();
		String maskedUrl = rawUrl
				.replaceAll("(p_cert_key=)[^&]+", "$1***")
				.replaceAll("(p_cert_id=)[^&]+", "$1***");
		
		// 🚀 [디버깅용 로그] 콘솔에 찍힌 이 URL을 그대로 복사해서 브라우저 주소창에 쳐보세요!
		System.out.println("====== [KAMIS REQUEST URL] ======");
		System.out.println(maskedUrl);
		System.out.println("=================================");

		return restClient.get()
				.uri(uri)
				.header("User-Agent",
						"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36")
				.header("Accept", "application/xml,text/xml;q=0.9,*/*;q=0.8")
				.header("Accept-Language", "ko-KR,ko;q=0.9,en-US;q=0.8,en;q=0.7")
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
				// 명세서에 맞게 action 변경
				.queryParam("action", "dailySalesList");

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

		return b.build().encode().toUri(); 
	}

	public Duration defaultTimeout() {
		return Duration.ofSeconds(10);
	}
}