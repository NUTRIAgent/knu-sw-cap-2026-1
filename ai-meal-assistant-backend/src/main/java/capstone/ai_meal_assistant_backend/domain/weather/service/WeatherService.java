package capstone.ai_meal_assistant_backend.domain.weather.service;

import capstone.ai_meal_assistant_backend.domain.weather.dto.WeatherResponse;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class WeatherService {

    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    @Value("${weather.api-key}")
    private String apiKey;

    private static final String KMA_URL =
            "https://apis.data.go.kr/1360000/VilageFcstInfoService_2.0/getUltraSrtNcst";

    public WeatherResponse getWeather(double lat, double lon) {
        int[] grid = toGrid(lat, lon);
        String[] dateTime = getBaseDateTime();

        String url = UriComponentsBuilder.fromHttpUrl(KMA_URL)
                .queryParam("serviceKey", apiKey)
                .queryParam("nx", grid[0])
                .queryParam("ny", grid[1])
                .queryParam("base_date", dateTime[0])
                .queryParam("base_time", dateTime[1])
                .queryParam("dataType", "JSON")
                .queryParam("numOfRows", 10)
                .build(false)
                .toUriString();

        String raw = restTemplate.getForObject(url, String.class);
        return parseResponse(raw);
    }

    private WeatherResponse parseResponse(String raw) {
        try {
            JsonNode root = objectMapper.readTree(raw);
            JsonNode items = root.path("response").path("body").path("items").path("item");

            Map<String, String> data = new HashMap<>();
            for (JsonNode item : items) {
                data.put(item.get("category").asText(), item.get("obsrValue").asText());
            }

            double temperature = Double.parseDouble(data.getOrDefault("T1H", "0"));
            int precipitationType = Integer.parseInt(data.getOrDefault("PTY", "0"));
            int humidity = Integer.parseInt(data.getOrDefault("REH", "0"));
            double windSpeed = Double.parseDouble(data.getOrDefault("WSD", "0"));

            return new WeatherResponse(temperature, precipitationType, toPtyName(precipitationType), humidity, windSpeed);
        } catch (Exception e) {
            throw new RuntimeException("기상청 API 파싱 실패 raw=" + raw, e);
        }
    }

    private String toPtyName(int pty) {
        return switch (pty) {
            case 1 -> "비";
            case 2 -> "비/눈";
            case 3 -> "눈";
            case 5 -> "빗방울";
            case 6 -> "빗방울/눈날림";
            case 7 -> "눈날림";
            default -> "맑음";
        };
    }

    // 초단기실황은 매시 40분 이후부터 제공되므로 40분 미만이면 1시간 전 사용
    private String[] getBaseDateTime() {
        LocalDateTime now = LocalDateTime.now(ZoneId.of("Asia/Seoul"));
        if (now.getMinute() < 40) {
            now = now.minusHours(1);
        }
        String baseDate = now.format(DateTimeFormatter.ofPattern("yyyyMMdd"));
        String baseTime = now.format(DateTimeFormatter.ofPattern("HH")) + "00";
        return new String[]{baseDate, baseTime};
    }

    // 기상청 공식 제공 격자 좌표 변환 수식 (위경도 → nx, ny)
    private int[] toGrid(double lat, double lon) {
        final double RE = 6371.00877;
        final double GRID = 5.0;
        final double SLAT1 = 30.0;
        final double SLAT2 = 60.0;
        final double OLON = 126.0;
        final double OLAT = 38.0;
        final int XO = 43;
        final int YO = 136;
        final double DEGRAD = Math.PI / 180.0;

        double re = RE / GRID;
        double slat1 = SLAT1 * DEGRAD;
        double slat2 = SLAT2 * DEGRAD;
        double olon = OLON * DEGRAD;
        double olat = OLAT * DEGRAD;

        double sn = Math.log(Math.cos(slat1) / Math.cos(slat2))
                / Math.log(Math.tan(Math.PI * 0.25 + slat2 * 0.5)
                / Math.tan(Math.PI * 0.25 + slat1 * 0.5));
        double sf = Math.pow(Math.tan(Math.PI * 0.25 + slat1 * 0.5), sn)
                * Math.cos(slat1) / sn;
        double ro = re * sf / Math.pow(Math.tan(Math.PI * 0.25 + olat * 0.5), sn);

        double ra = re * sf / Math.pow(Math.tan(Math.PI * 0.25 + lat * DEGRAD * 0.5), sn);
        double theta = lon * DEGRAD - olon;
        if (theta > Math.PI) theta -= 2.0 * Math.PI;
        if (theta < -Math.PI) theta += 2.0 * Math.PI;
        theta *= sn;

        int nx = (int) Math.floor(ra * Math.sin(theta) + XO + 0.5);
        int ny = (int) Math.floor(ro - ra * Math.cos(theta) + YO + 0.5);

        return new int[]{nx, ny};
    }
}
