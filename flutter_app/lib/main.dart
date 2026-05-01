// lib/main.dart
import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/dashboard_screen.dart'; // 대시보드 화면 불러오기
// import 'screens/login_screen.dart'; // 로그인 화면 불러오기

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

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // 탭별로 보여줄 화면 목록 (여기에 DashboardScreen을 넣어줌)
  static const List<Widget> _widgetOptions = <Widget>[
    DashboardScreen(),
    Center(child: Text('마이페이지 화면입니다')), // 임시 마이페이지
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, 
      body: _widgetOptions.elementAt(_selectedIndex),
      
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: '대시보드',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '마이페이지',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}