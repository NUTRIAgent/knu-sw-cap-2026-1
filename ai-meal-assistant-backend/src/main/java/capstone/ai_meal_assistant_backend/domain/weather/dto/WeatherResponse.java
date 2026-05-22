package capstone.ai_meal_assistant_backend.domain.weather.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class WeatherResponse {
    private double temperature;
    private int precipitationType;
    private String precipitationName;
    private int humidity;
    private double windSpeed;
}
