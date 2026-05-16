import 'dart:convert';

import 'package:flutter_app/models/user_profile_models.dart';
import 'package:http/http.dart' as http;

import 'auth_service.dart';
import 'token_storage.dart';

class UserProfileService {
  // auth는 /api/v1을 쓰지만, profile은 백엔드 매핑이 /api/users/profile인 경우가 많아서 분리
  // 필요하면 여기만 /api/v1 로 바꾸면 됨.
  static const String _profileApiBasePath = '/api';

  static Future<Map<String, String>> _defaultHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    final accessToken = await TokenStorage.getAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    return headers;
  }

  static Uri _profileUriWithoutUserId() {
    return Uri.parse('${ApiConfig.baseUrl}$_profileApiBasePath/users/profile');
  }

  static Future<UserProfileResponse> getProfile() async {
    try {
      final response = await http
          .get(
            _profileUriWithoutUserId(),
            headers: await _defaultHeaders(),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('요청 시간 초과'),
          );

      if (response.body.isEmpty) {
        return UserProfileResponse(
          success: false,
          error: '빈 응답을 받았습니다. status=${response.statusCode}',
        );
      }

      final jsonResponse = jsonDecode(response.body);
      return UserProfileResponse.fromJson(jsonResponse);
    } catch (e) {
      return UserProfileResponse(success: false, error: '프로필 조회 중 오류: $e');
    }
  }

  static Future<UserProfileResponse> saveProfile({
    required UserProfileRequest request,
  }) async {
    // Spring 스펙: POST /api/users/profile
    return _upsertProfile(method: 'POST', request: request);
  }

  static Future<UserProfileResponse> updateProfile({
    required UserProfileRequest request,
  }) async {
    // Spring 스펙: PUT /api/users/profile
    return _upsertProfile(method: 'PUT', request: request);
  }

  static Future<UserProfileResponse> _upsertProfile({
    required String method,
    required UserProfileRequest request,
  }) async {
    try {
      final uri = _profileUriWithoutUserId();

      final headers = await _defaultHeaders();
      final body = jsonEncode(request.toJson());

  // 디버깅: 실제 호출되는 URL/헤더 여부 확인
  // ignore: avoid_print
  print('[UserProfileService] $method $uri hasAuth=${headers.containsKey('Authorization')}');

      late http.Response response;
      if (method == 'POST') {
        response = await http.post(uri, headers: headers, body: body);
      } else if (method == 'PUT') {
        response = await http.put(uri, headers: headers, body: body);
      } else {
        throw Exception('지원하지 않는 method: $method');
      }

  // ignore: avoid_print
  print('[UserProfileService] response status=${response.statusCode} body=${response.body}');

      if (response.body.isEmpty) {
        return UserProfileResponse(
          success: false,
          error: '빈 응답을 받았습니다. status=${response.statusCode}',
        );
      }

      final jsonResponse = jsonDecode(response.body);
      return UserProfileResponse.fromJson(jsonResponse);
    } catch (e) {
      return UserProfileResponse(success: false, error: '프로필 저장/수정 중 오류: $e');
    }
  }
}
