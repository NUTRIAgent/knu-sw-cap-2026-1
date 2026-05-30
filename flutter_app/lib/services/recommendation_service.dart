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

  static Stream<RecommendationResult> recommendStream(RecommendationRequest request) async* {
    final client = http.Client();
    try {
      final uri = Uri.parse('${ApiConfig.aiBaseUrl}/recommend');
      final httpRequest = http.Request('POST', uri)
        ..headers['Content-Type'] = 'application/json; charset=utf-8'
        ..body = jsonEncode(request.toJson());

      final streamedResponse = await client.send(httpRequest).timeout(
        const Duration(seconds: 180),
        onTimeout: () => throw Exception('AI 서버 응답 시간 초과 (180초)'),
      );

      if (streamedResponse.statusCode != 200) {
        final body = await streamedResponse.stream.bytesToString();
        final decoded = jsonDecode(body);
        throw Exception(decoded['detail'] ?? 'AI 추천 실패 (${streamedResponse.statusCode})');
      }

      final lines = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in lines) {
        if (!line.startsWith('data: ')) continue;
        final data = line.substring(6);
        if (data == '[DONE]') return;
        final decoded = jsonDecode(data) as Map<String, dynamic>;
        if (decoded.containsKey('error')) throw Exception(decoded['error']);
        yield RecommendationResult.fromJson(decoded);
      }
    } finally {
      client.close();
    }
  }

  /// 후보 중 선택한 메뉴 1개를 AI 분석 (단일 JSON 응답)
  static Future<RecommendationResult> analyzeSelected(
      SelectMenuRequest request) async {
    final uri = Uri.parse('${ApiConfig.aiBaseUrl}/recommend/select');
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json; charset=utf-8'},
          body: jsonEncode(request.toJson()),
        )
        .timeout(
          const Duration(seconds: 60),
          onTimeout: () => throw Exception('AI 서버 응답 시간 초과 (60초)'),
        );

    if (response.statusCode != 200) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(decoded['detail'] ?? 'AI 분석 실패 (${response.statusCode})');
    }

    final decoded =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (decoded.containsKey('error')) throw Exception(decoded['error']);
    return RecommendationResult.fromJson(decoded);
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

  static Future<List<FeedbackHistoryItem>> fetchMyFeedbacks(String? jwt) async {
    if (jwt == null || jwt.isEmpty) return [];
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/recommendation-logs/my');
    try {
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $jwt'},
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return [];
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      if (json['success'] != true || json['data'] == null) return [];
      return (json['data'] as List)
          .map((e) => FeedbackHistoryItem.fromJson(e))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<bool> deleteFeedback(int logId, String? jwt) async {
    if (jwt == null || jwt.isEmpty) return false;
    final uri =
        Uri.parse('${ApiConfig.baseUrl}/api/recommendation-logs/$logId');
    try {
      final response = await http.delete(
        uri,
        headers: {'Authorization': 'Bearer $jwt'},
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return false;
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      return json['success'] == true;
    } catch (_) {
      return false;
    }
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
