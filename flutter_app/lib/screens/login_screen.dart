import 'package:flutter/material.dart';
import 'signup_screen.dart';
import 'email_login_screen.dart';
import 'package:flutter_app/theme.dart'; // 💡 AppTheme 임포트 추가

// 직접 가입 or 소셜 로그인을 선택할 수 있는 페이지 입니다.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 35.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              
              // 💡 타이틀 문구에 그라데이션 적용 (ShaderMask 활용)
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (Rect bounds) {
                  return AppTheme.aiGradient.createShader(bounds);
                },
                child: const Text(
                  '고물가 시대에 사는\n당신을 위한 메뉴 추천\n어플리케이션',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900, // 더 뚜렷하게 보이도록 두께 증가
                    height: 1.4,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const Spacer(flex: 2),
              
              // 💡 1. 가입하기 버튼 (앱 메인 테마인 그라데이션 적용)
              Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppTheme.aiGradient,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SignupScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent, // 투명하게 해서 그라데이션 노출
                    shadowColor: Colors.transparent,     // 기본 그림자 제거
                    shape: const StadiumBorder(),
                  ),
                  child: const Text(
                    '가입하기', 
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // // 💡 2. 소셜 로그인 버튼들 (브랜드 고유 색상 유지)
              // _buildLoginButton(
              //   text: '카카오로 계속하기',
              //   backgroundColor: const Color(0xFFEAE145),
              //   textColor: Colors.black87,
              //   onPressed: () {},
              // ),
              // const SizedBox(height: 16),

              // _buildLoginButton(
              //   text: '네이버로 계속하기',
              //   backgroundColor: const Color(0xFF5CC959), 
              //   textColor: Colors.white,
              //   onPressed: () {},
              // ),
              // const SizedBox(height: 16),

              // _buildLoginButton(
              //   text: 'Google로 계속하기',
              //   backgroundColor: const Color(0xFF4A31FF),
              //   textColor: Colors.white,
              //   onPressed: () {},
              // ),
              // const SizedBox(height: 16),

              // _buildLoginButton(
              //   text: 'Apple로 계속하기',
              //   backgroundColor: Colors.black,
              //   textColor: Colors.white,
              //   onPressed: () {},
              // ),

              const Spacer(flex: 2),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('이미 계정이 있으신가요?', style: TextStyle(color: Colors.grey)),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const EmailLoginScreen()),
                      );
                    },
                    child: Text(
                      '로그인하기', 
                      // 💡 텍스트 버튼 색상을 테마의 primaryColor(하늘색)로 변경
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)
                    ),
                  ),
                ],
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }

  // 소셜 로그인 버튼 전용 헬퍼 위젯 (브랜드 컬러를 받아 처리)
  Widget _buildLoginButton({
    required String text, 
    required Color backgroundColor, 
    required Color textColor, 
    required VoidCallback onPressed
  }) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          shape: const StadiumBorder(), // 💡 Capsule 모양 통일
        ),
        child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}