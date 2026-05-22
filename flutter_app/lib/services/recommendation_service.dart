import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_app/models/recommendation_models.dart';
import 'auth_service.dart';

class RecommendationService {
  static Future<List<MenuCandidate>> fetchCandidates(String? jwt) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/menus/candidates');
    final headers = <String, String>{};
    if (jwt != null && jwt.isNotEmpty) {
      headers['Authorization'] = 'Bearer $jwt';
    }

    final response = await http
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) return [];

    final json = jsonDecode(utf8.decode(response.bodyBytes));
    if (json['success'] != true || json['data'] == null) return [];
    return (json['data'] as List)
        .map((e) => MenuCandidate.fromJson(e))
        .toList();
  }

  static Future<RecommendationResult> recommend(RecommendationRequest request) async {
    final uri = Uri.parse('${ApiConfig.aiBaseUrl}/recommend');

    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(request.toJson()),
        )
        .timeout(
          const Duration(seconds: 120),
          onTimeout: () => throw Exception('AI 서버 응답 시간 초과 (120초)'),
        );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['detail'] ?? 'AI 추천 실패 (${response.statusCode})');
    }

    final json = jsonDecode(utf8.decode(response.bodyBytes));
    return RecommendationResult.fromJson(json);
  }

  static Future<void> saveFeedback(int menuId, int feedbackScore, String? jwt) async {
    if (jwt == null || jwt.isEmpty) return;
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/recommendation-logs');
    try {
      await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $jwt',
            },
            body: jsonEncode({'menuId': menuId, 'feedbackScore': feedbackScore}),
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  static Future<void> saveDetailedFeedback(
      int menuId, int starRating, String feedbackReason, String? jwt) async {
    if (jwt == null || jwt.isEmpty) return;
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/recommendation-logs');
    try {
      final body = <String, dynamic>{'menuId': menuId, 'starRating': starRating};
      if (feedbackReason.isNotEmpty) body['feedbackReason'] = feedbackReason;
      await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $jwt',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  static Future<MenuDetail?> fetchMenuDetail(int id, String? jwt) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/menus/$id');
    final headers = <String, String>{};
    if (jwt != null && jwt.isNotEmpty) {
      headers['Authorization'] = 'Bearer $jwt';
    }
    try {
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      if (json['success'] != true || json['data'] == null) return null;
      return MenuDetail.fromJson(json['data'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
