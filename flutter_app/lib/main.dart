import 'package:flutter/material.dart';
import 'theme.dart';
<<<<<<< HEAD
import 'screens/dashboard_screen.dart'; // 대시보드 화면 불러오기
=======
import 'screens/main_screen.dart';
// import 'screens/login_screen.dart'; 
>>>>>>> c45ae355407de7db5f221650b87e6448101d1812


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
      theme: AppTheme.lightTheme,
      
      home: const MainScreen(),
      // home: const LoginScreen(),
    );
  }
}