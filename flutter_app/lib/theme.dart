import 'package:flutter/material.dart';

class AppTheme {
  // 💡 새로운 AI 테마 그라데이션 컬러 (#c2e59c -> #64b3f4)
  static const Color gradientStart = Color(0xFFC2E59C); // Light Green
  static const Color gradientEnd = Color(0xFF64B3F4);   // Sky Blue
  
  // 앱의 기본 포인트 색상 (그라데이션 중 더 짙은 Sky Blue를 Primary로 사용)
  static const Color primaryColor = Color(0xFF64B3F4);
  static const Color backgroundColor = Color(0xFFF8FAFC); // 밝은 연회색 배경

  // 💡 공통 그라데이션 정의 (위젯에서 AppTheme.aiGradient 로 호출)
  static const LinearGradient aiGradient = LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: gradientStart,
        surface: Colors.white,
      ),
      
      // 1. 카드(Card) 스타일: 20px 라운딩 (소프트 라운디드)
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      // 2. 버튼 스타일: Full-round (Capsule style)
      // (단색 버튼을 쓸 경우 기본적으로 primaryColor가 적용됨)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(), 
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          elevation: 0,
        ),
      ),

      // 3. 입력창(TextField) 스타일: 16px 라운딩
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
      ),
    );
  }
}