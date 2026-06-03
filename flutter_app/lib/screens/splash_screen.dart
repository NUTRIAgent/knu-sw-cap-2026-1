import 'package:flutter/material.dart';
import 'package:flutter_app/services/auth_service.dart';
import 'package:flutter_app/services/price_alert_service.dart';
import 'package:flutter_app/services/token_storage.dart';
import 'package:flutter_app/services/user_profile_service.dart';
import 'package:flutter_app/theme.dart';
import 'login_screen.dart';
import 'main_screen.dart';
import 'onboarding_screen.dart';

// 앱 시작 시 자동 로그인 여부를 판단해 화면을 분기하는 스플래시 화면입니다.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // 1. 자동 로그인 미사용 또는 저장된 리프레시 토큰 없음 -> 로그인 화면
    final autoLogin = await TokenStorage.getAutoLogin();
    final refreshToken = await TokenStorage.getRefreshToken();
    if (!autoLogin || refreshToken == null || refreshToken.isEmpty) {
      _goTo(const LoginScreen());
      return;
    }

    // 2. 리프레시 토큰으로 새 토큰 발급 (실패 시 세션 만료로 간주)
    final refreshed = await AuthService.refreshTokens();
    if (!refreshed) {
      await TokenStorage.clearAll();
      _goTo(const LoginScreen());
      return;
    }

    // 3. FCM 토큰 백엔드 등록 (실패해도 로그인 흐름에 영향 없음)
    final jwt = await TokenStorage.getAccessToken();
    PriceAlertService.registerToken(jwt);

    // 4. 프로필 확인 후 온보딩 필요 여부 분기 — 판정 기준은 UserProfileService.needsOnboarding 참고
    final profileResponse = await UserProfileService.getProfile();
    final needsOnboarding = UserProfileService.needsOnboarding(profileResponse);

    _goTo(needsOnboarding ? const OnboardingScreen() : const MainScreen());
  }

  void _goTo(Widget screen) {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => screen),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 앱 로고 + 그 아래 브랜드 타이틀
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Image.asset(
                'assets/icon/app-logo.png',
                width: 120,
                height: 120,
              ),
            ),
            const SizedBox(height: 20),
            // 💡 앱 타이틀에 그라데이션 적용 (login_screen과 동일한 스타일)
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (Rect bounds) {
                return AppTheme.aiGradient.createShader(bounds);
              },
              child: const Text(
                '메밀-MeMeAI',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 32),
            CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ],
        ),
      ),
    );
  }
}
