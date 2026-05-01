package capstone.ai_meal_assistant_backend.domain.etl;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;

@Slf4j
@Service
public class FoodSafetyApiFetcher {

    private final WebClient webClient;

//    생성자 주입을 통해 WebClient 기본 세팅 (Base URL 지정)
    public FoodSafetyApiFetcher(WebClient.Builder webClientBuilder) {
        this.webClient = webClientBuilder
                .baseUrl("http://openapi.foodsafetykorea.go.kr")
                .build();
    }

//    식약처 API에서 레시피 JSON 데이터를 가져오는 메서드
    public String fetchRecipeData(){
        String apiKey = "c97ed774ef1741c085a0";

        log.info("식약처 API 호출 시작");

//        API 호출 시작
        return webClient.get()
//                URI 조합: (api/인증키/서비스명/데이터타입/시작인덱스/종료인덱스)
                .uri("/api/c97ed774ef1741c085a0/COOKRCP01/json/1/10", apiKey)
                .retrieve() // 결과물 가져오기
                .bodyToMono(String.class) // 결과물을 String 형태의 Mono 상자에 담음
                .block(); // 상자가 열릴 때까지 대기
    }


}
