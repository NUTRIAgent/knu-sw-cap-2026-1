// lib/theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static const Color oliveColor = Color(0xFF6B8E23);
  static const Color backgroundColor = Color(0xFFF5F6F5);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: oliveColor,
        primary: oliveColor,
        surface: Colors.white,
        background: backgroundColor,
      ),
      
      // 공통 버튼 스타일
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: oliveColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 18), // 크기 통일
          elevation: 0,
        ),
      ),

      // 공통 텍스트 입력창(TextField) 스타일
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: oliveColor, width: 2),
        ),
        labelStyle: const TextStyle(fontSize: 14),
      ),
    );
  }
}