import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_app/models/auth_models.dart';
import 'token_storage.dart';

// 백엔드 API 기본 설정
class ApiConfig {
  // 배포 환경에서는 빌드 시 --dart-define=API_BASE_URL=https://... 로 주입 (미지정 시 로컬 개발 기본값)
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );
  static const String apiVersion = '/api/v1';
  static const String aiBaseUrl = String.fromEnvironment(
    'AI_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );
}

// 인증 관련 API 서비스
class AuthService {
  // 로그인
  static Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.apiVersion}/auth/login');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('요청 시간 초과'),
      );

      final jsonResponse = jsonDecode(response.body);
      final authResponse = AuthResponse.fromJson(jsonResponse);

      // 성공 시 토큰 저장
      if (authResponse.success && authResponse.data?.accessToken != null) {
        await TokenStorage.saveTokens(
          accessToken: authResponse.data!.accessToken!,
          refreshToken: authResponse.data?.refreshToken,
        );
        if (authResponse.data?.user != null) {
          await TokenStorage.saveUserInfo(
            email: authResponse.data!.user!.email,
            nickname: authResponse.data!.user!.nickname,
            gender: authResponse.data!.user!.gender,
            userId: authResponse.data!.user!.id,
          );
        }
      }

      return authResponse;
    } catch (e) {
      return AuthResponse(
        success: false,
        error: '로그인 중 오류가 발생했습니다: $e',
      );
    }
  }

  // 토큰 갱신 (자동 로그인용) — 저장된 리프레시 토큰으로 새 토큰을 발급받아 저장
  static Future<bool> refreshTokens() async {
    try {
      final refreshToken = await TokenStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) return false;

      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.apiVersion}/auth/refresh');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'refreshToken': refreshToken,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('요청 시간 초과'),
      );

      final jsonResponse = jsonDecode(response.body);
      final authResponse = AuthResponse.fromJson(jsonResponse);

      // 성공 시 새 토큰 저장
      if (authResponse.success && authResponse.data?.accessToken != null) {
        await TokenStorage.saveTokens(
          accessToken: authResponse.data!.accessToken!,
          refreshToken: authResponse.data?.refreshToken,
        );
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  // 이메일 중복확인 (true: 이미 사용 중, false: 사용 가능, null: 확인 실패)
  static Future<bool?> checkEmailExists(String email) {
    return _checkExists('email', email);
  }

  // 닉네임 중복확인 (true: 이미 사용 중, false: 사용 가능, null: 확인 실패)
  static Future<bool?> checkNicknameExists(String nickname) {
    return _checkExists('nickname', nickname);
  }

  static Future<bool?> _checkExists(String paramName, String value) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.apiVersion}/users/exists')
          .replace(queryParameters: {paramName: value});

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('요청 시간 초과'),
      );

      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['success'] == true) {
        return jsonResponse['data']?['exists'] == true;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // 회원가입
  static Future<AuthResponse> signup({
    required String email,
    required String password,
    required String nickname,
    required String? gender,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.apiVersion}/auth/signup');

      final request = SignupRequest(
        email: email,
        password: password,
        nickname: nickname,
        gender: gender,
      );

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('요청 시간 초과'),
      );

      final jsonResponse = jsonDecode(response.body);
      final authResponse = AuthResponse.fromJson(jsonResponse);

      // 성공 시 토큰 저장
      if (authResponse.success && authResponse.data?.accessToken != null) {
        await TokenStorage.saveTokens(
          accessToken: authResponse.data!.accessToken!,
          refreshToken: authResponse.data?.refreshToken,
        );
        if (authResponse.data?.user != null) {
          await TokenStorage.saveUserInfo(
            email: authResponse.data!.user!.email,
            nickname: authResponse.data!.user!.nickname,
            gender: authResponse.data!.user!.gender,
            userId: authResponse.data!.user!.id,
          );
        }
      }

      return authResponse;
    } catch (e) {
      return AuthResponse(
        success: false,
        error: '회원가입 중 오류가 발생했습니다: $e',
      );
    }
  }

  // 로그아웃
  static Future<void> logout() async {
    await TokenStorage.clearAll();
  }

  // 토큰이 유효한지 확인
  static Future<bool> isLoggedIn() async {
    return await TokenStorage.hasToken();
  }
}
