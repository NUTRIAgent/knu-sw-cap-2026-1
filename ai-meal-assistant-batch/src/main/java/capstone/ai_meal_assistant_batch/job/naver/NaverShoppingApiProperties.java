package capstone.ai_meal_assistant_batch.job.naver;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;

@Getter
@Setter
@ConfigurationProperties(prefix = "batch.naver.shopping")
public class NaverShoppingApiProperties {

    private String baseUrl = "https://openapi.naver.com";

    @NotBlank
    private String clientId;

    @NotBlank
    private String clientSecret;

    private int displayCount = 10;
}
