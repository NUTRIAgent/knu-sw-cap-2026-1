import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const NutriAgentApp());
}

class NutriAgentApp extends StatelessWidget {
  const NutriAgentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NUTRI Agent',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme, // 분리한 테마 적용
      home: const DashboardScreen(), // 초기 화면 설정
    );
  }
}