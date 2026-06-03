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
        // 유저 정보도 갱신 저장 (자동 로그인 시 마이페이지 성별 등이 비지 않도록)
        if (authResponse.data?.user != null) {
          await TokenStorage.saveUserInfo(
            email: authResponse.data!.user!.email,
            nickname: authResponse.data!.user!.nickname,
            gender: authResponse.data!.user!.gender,
            userId: authResponse.data!.user!.id,
          );
        }
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

  // 휴대폰 번호 중복확인 (true: 이미 사용 중, false: 사용 가능, null: 확인 실패)
  static Future<bool?> checkPhoneNumberExists(String phoneNumber) {
    return _checkExists('phoneNumber', phoneNumber);
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
    String? phoneNumber,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.apiVersion}/auth/signup');

      final request = SignupRequest(
        email: email,
        password: password,
        nickname: nickname,
        phoneNumber: phoneNumber,
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

  // 아이디(이메일) 찾기 — 가입 시 등록한 휴대폰 번호로 마스킹된 이메일 조회
  static Future<FindEmailResult> findEmail(String phoneNumber) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.apiVersion}/auth/find-email');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phoneNumber': phoneNumber}),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('요청 시간 초과'),
      );

      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['success'] == true) {
        return FindEmailResult(maskedEmail: jsonResponse['data']?['maskedEmail']);
      }
      return FindEmailResult(error: jsonResponse['error'] ?? '아이디 찾기에 실패했습니다.');
    } catch (e) {
      return FindEmailResult(error: '아이디 찾기 중 오류가 발생했습니다: $e');
    }
  }

  // 비밀번호 재설정 인증코드 발송 (null: 성공, 문자열: 에러 메시지)
  static Future<String?> requestPasswordCode(String email) {
    return _postPasswordApi('code', {'email': email});
  }

  // 비밀번호 재설정 인증코드 검증 (null: 성공, 문자열: 에러 메시지)
  static Future<String?> verifyPasswordCode(String email, String code) {
    return _postPasswordApi('verify', {'email': email, 'code': code});
  }

  // 비밀번호 재설정 (null: 성공, 문자열: 에러 메시지)
  static Future<String?> resetPassword(String email, String code, String newPassword) {
    return _postPasswordApi('reset', {
      'email': email,
      'code': code,
      'newPassword': newPassword,
    });
  }

  static Future<String?> _postPasswordApi(String path, Map<String, dynamic> body) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.apiVersion}/auth/password/$path');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('요청 시간 초과'),
      );

      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['success'] == true) return null;
      return jsonResponse['error'] ?? '요청에 실패했습니다.';
    } catch (e) {
      return '요청 중 오류가 발생했습니다: $e';
    }
  }

  // 로그아웃 — 서버에 저장된 refresh token 무효화 후 로컬 토큰 정리
  static Future<void> logout() async {
    // 서버 무효화는 best-effort: 네트워크 오류여도 로컬 로그아웃은 항상 완료돼야 한다
    try {
      final refreshToken = await TokenStorage.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.apiVersion}/auth/logout');
        await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'refreshToken': refreshToken,
          }),
        ).timeout(const Duration(seconds: 5));
      }
    } catch (_) {
      // 무시 — 서버 측 토큰은 TTL(7일)로 결국 만료된다
    }
    await TokenStorage.clearAll();
  }

  // 토큰이 유효한지 확인
  static Future<bool> isLoggedIn() async {
    return await TokenStorage.hasToken();
  }

  // 회원탈퇴 — 성공 시 로컬 토큰까지 정리. 반환값: null=성공, 그 외=에러 메시지
  static Future<String?> deleteAccount() async {
    try {
      final accessToken = await TokenStorage.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        return '로그인 정보가 없습니다. 다시 로그인해 주세요.';
      }

      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.apiVersion}/users/me');
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('요청 시간 초과'),
      );

      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['success'] == true) {
        await TokenStorage.clearAll();
        return null;
      }
      return jsonResponse['error'] ?? '회원탈퇴에 실패했습니다.';
    } catch (e) {
      return '요청 중 오류가 발생했습니다: $e';
    }
  }
}
