import 'package:flutter/material.dart';
import 'package:flutter_app/services/auth_service.dart';
import 'package:flutter_app/services/price_alert_service.dart';
import 'package:flutter_app/services/token_storage.dart';
import 'main_screen.dart';
import 'package:flutter_app/theme.dart';
import 'package:flutter_app/services/user_profile_service.dart';
import 'onboarding_screen.dart';

// 직접 로그인을 진행하는 페이지입니다. (소셜로그인X)
class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

    void _submitLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // 1. 로그인 API 호출 (이 안에서 토큰이 로컬에 저장됨)
      final response = await AuthService.login(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (response.success) {
        // FCM 토큰 백엔드 등록 (실패해도 로그인 흐름에 영향 없음)
        final jwt = await TokenStorage.getAccessToken();
        PriceAlertService.registerToken(jwt);

        // 💡 2. 토큰이 저장되었으니, 프로필 정보를 찔러서 온보딩 필요 여부 확인
        final profileResponse = await UserProfileService.getProfile();
        
        if (!mounted) return;
        
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인 성공!')),
        );

        // 💡 3. 필수 데이터(예: 키, 몸무게)가 없으면 온보딩 대상으로 간주
        // 백엔드에서 아직 프로필이 안 만들어졌거나, height가 null인 경우
        // 💡 키 값이 null이거나, 백엔드 초기값인 999(또는 999.0)인 경우 온보딩으로 보냅니다
        bool needsOnboarding = profileResponse.data == null || 
                              profileResponse.data?.height == null || 
                              profileResponse.data?.height == 999 || 
                              profileResponse.data?.height == 999.0;

        if (needsOnboarding) {
          // 첫 로그인 유저 -> 온보딩 화면으로 이동 (뒤로 가기 방지)
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const OnboardingScreen()),
            (route) => false,
          );
        } else {
          // 기존 유저 -> 메인 대시보드로 이동 (뒤로 가기 방지)
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
            (route) => false,
          );
        }
      } else {
        // 로그인 실패 시
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.error ?? '로그인 실패했습니다.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('로그인', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '다시 오신 것을 환영합니다!\n계정 정보를 입력해 주세요.', 
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.4)
                ),
                const SizedBox(height: 40),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: '이메일',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    // 💡 입력창 모서리를 글로벌 테마와 동일하게 16px로 맞춤
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                  validator: (value) => (value == null || value.isEmpty) ? '이메일을 입력해 주세요.' : null,
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: '비밀번호',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    // 💡 입력창 모서리를 글로벌 테마와 동일하게 16px로 맞춤
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                  validator: (value) => (value == null || value.isEmpty) ? '비밀번호를 입력해 주세요.' : null,
                ),
                const SizedBox(height: 40),

                // 💡 로그인 버튼에 그라데이션 및 캡슐형 디자인 적용
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    // 로딩 중일 때는 회색 처리, 아닐 때는 그라데이션
                    color: _isLoading ? Colors.grey.shade400 : null,
                    gradient: _isLoading ? null : AppTheme.aiGradient,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      if (!_isLoading)
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent, // 투명하게 처리해 뒤쪽 그라데이션 노출
                      shadowColor: Colors.transparent,     // 기본 그림자 제거
                      shape: const StadiumBorder(),
                      padding: EdgeInsets.zero,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            '로그인하기', 
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}