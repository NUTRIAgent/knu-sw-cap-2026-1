// 인증 관련 데이터 모델들

// 로그인 요청 데이터
class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

// 회원가입 요청 데이터
class SignupRequest {
  final String email;
  final String password;
  final String nickname;
  final String? phoneNumber;
  final String? gender;
  final String role;
  final String? provider;
  final String? providerId;

  SignupRequest({
    required this.email,
    required this.password,
    required this.nickname,
    this.phoneNumber,
    this.gender,
    this.role = 'USER',
    this.provider,
    this.providerId,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'nickname': nickname,
      'phoneNumber': phoneNumber,
      'gender': gender,
      'role': role,
      'provider': provider,
      'providerId': providerId,
    };
  }
}

// 아이디(이메일) 찾기 결과 — 성공 시 마스킹된 이메일, 실패 시 에러 메시지
class FindEmailResult {
  final String? maskedEmail;
  final String? error;

  FindEmailResult({this.maskedEmail, this.error});
}

// 인증 응답 데이터
class AuthResponse {
  final bool success;
  final String? message;
  final AuthData? data;
  final String? error;

  AuthResponse({
    required this.success,
    this.message,
    this.data,
    this.error,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'] != null ? AuthData.fromJson(json['data']) : null,
      error: json['error'],
    );
  }
}

// 인증 데이터 (토큰, 사용자 정보 등)
class AuthData {
  final String? accessToken;
  final String? refreshToken;
  final User? user;

  AuthData({
    this.accessToken,
    this.refreshToken,
    this.user,
  });

  factory AuthData.fromJson(Map<String, dynamic> json) {
    return AuthData(
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }
}

// 사용자 정보
class User {
  final int? id;
  final String email;
  final String nickname;
  final String? gender;
  final String? role;

  User({
    this.id,
    required this.email,
    required this.nickname,
  this.gender,
    this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      nickname: json['nickname'],
  gender: json['gender'],
      role: json['role'],
    );
  }
}
