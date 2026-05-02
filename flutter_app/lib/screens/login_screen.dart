import 'package:flutter/material.dart';

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
              
              // 1. 메인 타이틀
              const Text(
                '고물가 시대에 사는\n당신을 위한 메뉴 추천\n어플리케이션',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: Color.fromARGB(255, 0, 0, 0),
                  height: 1.4,
                  letterSpacing: -0.5,
                ),
              ),
              
              const Spacer(flex: 2),
              
              // 이메일로 계속하기
              _buildLoginButton(
                text: '이메일로 계속하기',
                backgroundColor: const Color(0xFF8CA384), 
                textColor: Colors.white,
                onPressed: () {
                  // TODO: 이메일 가입/로그인 라우팅
                },
              ),
              const SizedBox(height: 16),

              // 카카오로 계속하기
              _buildLoginButton(
                text: '카카오로 계속하기',
                backgroundColor: const Color(0xFFEAE145),
                textColor: Colors.white,
                onPressed: () {},
              ),
              const SizedBox(height: 16),

              // 네이버로 계속하기
              _buildLoginButton(
                text: '네이버로 계속하기',
                backgroundColor: const Color(0xFF5CC959), 
                textColor: Colors.white,
                onPressed: () {},
              ),
              const SizedBox(height: 16),

              // Google로 계속하기
              _buildLoginButton(
                text: 'Google로 계속하기',
                backgroundColor: const Color(0xFF4A31FF),
                textColor: Colors.white,
                onPressed: () {},
              ),
              const SizedBox(height: 16),

              // Apple로 계속하기
              _buildLoginButton(
                text: 'Apple로 계속하기',
                backgroundColor: Colors.black,
                textColor: Colors.white,
                onPressed: () {},
              ),

              const Spacer(flex: 3), // 버튼 하단 여백 확보
            ],
          ),
        ),
      ),
    );
  }

  // 버튼을 찍어내는 공통 위젯 함수
  Widget _buildLoginButton({
    required String text,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}