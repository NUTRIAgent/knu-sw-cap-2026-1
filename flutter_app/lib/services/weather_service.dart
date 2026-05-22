import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class WeatherData {
  final double temperature;
  final int precipitationType;
  final String precipitationName;
  final int humidity;
  final double windSpeed;

  WeatherData({
    required this.temperature,
    required this.precipitationType,
    required this.precipitationName,
    required this.humidity,
    required this.windSpeed,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      temperature: (json['temperature'] as num).toDouble(),
      precipitationType: json['precipitationType'] as int,
      precipitationName: json['precipitationName'] as String,
      humidity: json['humidity'] as int,
      windSpeed: (json['windSpeed'] as num).toDouble(),
    );
  }
}

class WeatherService {
  static Future<WeatherData> fetchWeather(double lat, double lon) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/weather').replace(
      queryParameters: {
        'lat': lat.toString(),
        'lon': lon.toString(),
      },
    );

    final response = await http
        .get(uri)
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('날씨 조회 실패 (${response.statusCode})');
    }

    final json = jsonDecode(utf8.decode(response.bodyBytes));
    if (json['success'] != true || json['data'] == null) {
      throw Exception(json['error'] ?? '날씨 데이터 없음');
    }

    return WeatherData.fromJson(json['data'] as Map<String, dynamic>);
  }
}
