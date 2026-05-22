package capstone.ai_meal_assistant_backend.domain.weather.controller;

import capstone.ai_meal_assistant_backend.domain.weather.dto.WeatherResponse;
import capstone.ai_meal_assistant_backend.domain.weather.service.WeatherService;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/weather")
@RequiredArgsConstructor
public class WeatherController {

    private final WeatherService weatherService;

    @Getter
    @AllArgsConstructor
    private static class ApiResponse<T> {
        private boolean success;
        private T data;
        private String error;

        static <T> ApiResponse<T> ok(T data) {
            return new ApiResponse<>(true, data, null);
        }

        static <T> ApiResponse<T> fail(String error) {
            return new ApiResponse<>(false, null, error);
        }
    }

    @GetMapping
    public ResponseEntity<ApiResponse<WeatherResponse>> getWeather(
            @RequestParam("lat") double lat,
            @RequestParam("lon") double lon) {
        try {
            WeatherResponse weather = weatherService.getWeather(lat, lon);
            return ResponseEntity.ok(ApiResponse.ok(weather));
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                    .body(ApiResponse.fail("날씨 조회 실패: " + e.getMessage()));
        }
    }
}
