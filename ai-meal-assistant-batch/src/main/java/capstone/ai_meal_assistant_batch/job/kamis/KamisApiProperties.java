package capstone.ai_meal_assistant_batch.job.kamis;

import org.springframework.boot.context.properties.ConfigurationProperties;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@ConfigurationProperties(prefix = "batch.kamis.api")
public class KamisApiProperties {

	/**
	 * 예: https://www.kamis.or.kr
	 */
	private String baseUrl = "https://www.kamis.or.kr";

	/**
	 * 환경변수 KAMIS_API_KEY 권장
	 */
	@NotBlank
	private String apiKey;

	/**
	 * KAMIS 문서 기준 p_cert_id
	 */
	@NotBlank
	private String certId;

	/**
	 * KAMIS 문서 기준 p_returntype
	 */
	private String returnType = "xml";
}
