import 'package:flutter/material.dart';
import 'onboarding_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  // 온보딩 화면으로 이동
  void _navigateToOnboarding(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const OnboardingScreen()),
    );
  }

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
              const Text(
                '고물가 시대에 사는\n당신을 위한 메뉴 추천\n어플리케이션',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                  height: 1.4,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(flex: 2),
              
              _buildLoginButton(
                text: '이메일로 계속하기',
                backgroundColor: const Color(0xFF8CA384), 
                textColor: Colors.white,
                onPressed: () => _navigateToOnboarding(context),
              ),
              const SizedBox(height: 16),

              _buildLoginButton(
                text: '카카오로 계속하기',
                backgroundColor: const Color(0xFFEAE145),
                textColor: Colors.white,
                onPressed: () => _navigateToOnboarding(context),
              ),
              const SizedBox(height: 16),

              _buildLoginButton(
                text: '네이버로 계속하기',
                backgroundColor: const Color(0xFF5CC959), 
                textColor: Colors.white,
                onPressed: () => _navigateToOnboarding(context),
              ),
              const SizedBox(height: 16),

              _buildLoginButton(
                text: 'Google로 계속하기',
                backgroundColor: const Color(0xFF4A31FF),
                textColor: Colors.white,
                onPressed: () => _navigateToOnboarding(context),
              ),
              const SizedBox(height: 16),

              _buildLoginButton(
                text: 'Apple로 계속하기',
                backgroundColor: Colors.black,
                textColor: Colors.white,
                onPressed: () => _navigateToOnboarding(context),
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }

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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}