package capstone.ai_meal_assistant_batch.domain.etl;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.ExchangeStrategies;
import org.springframework.web.reactive.function.client.WebClient;

@Slf4j
@Service
public class FoodSafetyApiFetcher {

    private final WebClient webClient;

    @Value("${foodsafety.api-key}")
    private String apiKey;  // 식약처 API-KEY

    //    생성자 주입을 통해 WebClient 기본 세팅 (Base URL 및 버퍼 크기 지정)
    public FoodSafetyApiFetcher(WebClient.Builder webClientBuilder) {

//        Buffer 크기를 10MB로 늘려주는 전략 생성
        ExchangeStrategies exchangeStrategies = ExchangeStrategies.builder()
                .codecs(configurer -> configurer.defaultCodecs().maxInMemorySize(10 * 1024 * 1024)) // 10MB (1000개 이상의 데이터도 거뜬함!)
                .build();

        this.webClient = webClientBuilder
                .exchangeStrategies(exchangeStrategies) // Buffer 크기 확장
                .baseUrl("http://openapi.foodsafetykorea.go.kr")
                .build();
    }

    //    식약처 API에서 레시피 JSON 데이터를 가져오는 메서드
    public String fetchRecipeData() {

        log.info("식약처 API 호출");

//        API 호출 시작
        return webClient.get()
//                URI 조합: (api/인증키/서비스명/데이터타입/시작인덱스/종료인덱스)
                .uri("/api/{apiKey}/COOKRCP01/json/899/1146", apiKey)
                .retrieve() // 결과물 가져오기
                .bodyToMono(String.class) // 결과물을 String 형태의 Mono 상자에 담음
                .block(); // 상자가 열릴 때까지 대기
    }
}
