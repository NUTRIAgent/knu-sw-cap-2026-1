import 'package:shared_preferences/shared_preferences.dart';

// 로컬 스토리지에서 토큰과 사용자 정보를 관리하는 클래스
class TokenStorage {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userEmailKey = 'user_email';
  static const String _userNicknameKey = 'user_nickname';
  static const String _userGenderKey = 'user_gender';
  static const String _userIdKey = 'user_id';

  // 토큰 저장
  static Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    if (refreshToken != null) {
      await prefs.setString(_refreshTokenKey, refreshToken);
    }
  }

  // 사용자 정보 저장
  static Future<void> saveUserInfo({
    required String email,
    required String nickname,
    String? gender,
    int? userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userEmailKey, email);
    await prefs.setString(_userNicknameKey, nickname);
    if (gender != null) {
      await prefs.setString(_userGenderKey, gender);
    }
    if (userId != null) {
      await prefs.setInt(_userIdKey, userId);
    }
  }

  static Future<void> saveGender(String gender) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userGenderKey, gender);
  }

  static Future<void> saveNickname(String nickname) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNicknameKey, nickname);
  }

  static Future<String?> getGender() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userGenderKey);
  }

  // 사용자 ID 조회
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  // Access Token 조회
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  // Refresh Token 조회
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  // 사용자 이메일 조회
  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  // 사용자 닉네임 조회
  static Future<String?> getUserNickname() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNicknameKey);
  }

  // 로그아웃 (모든 토큰 및 사용자 정보 삭제)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userNicknameKey);
  await prefs.remove(_userGenderKey);
  await prefs.remove(_userIdKey);
  }

  // 토큰 존재 여부 확인
  static Future<bool> hasToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
