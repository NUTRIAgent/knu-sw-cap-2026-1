import 'package:flutter/material.dart';

class AppTheme {
  // 포인트 컬러: 올리브
  static const Color oliveColor = Color(0xFF6B8E23);
  static const Color backgroundColor = Color(0xFFF5F6F5);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: oliveColor,
        primary: oliveColor,
        surface: Colors.white,
        background: backgroundColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      // 공통 버튼 스타일 정의
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: oliveColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}