import 'package:flutter/material.dart';
import 'theme.dart';
// import 'screens/dashboard_screen.dart';
// import 'screens/main_screen.dart';
import 'screens/login_screen.dart'; 

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
      home: const LoginScreen(),
      // home: const MainScreen(),
      // home: const LoginScreen(),
    );
  }
}