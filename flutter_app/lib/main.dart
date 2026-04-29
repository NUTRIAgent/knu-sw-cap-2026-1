import 'package:flutter/material.dart';

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
      theme: ThemeData(
        // 포인트 컬러: 올리브 (Olive Green)
        primaryColor: const Color(0xFF6B8E23),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B8E23),
          primary: const Color(0xFF6B8E23),
          surface: Colors.white,
          background: const Color(0xFFF5F6F5), // 완전히 순백색보다 눈이 편안한 오프화이트
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F6F5),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

// 1. 하단 네비게이션 바를 관리하는 메인 스크린
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // 탭별로 보여줄 화면 목록
  static const List<Widget> _widgetOptions = <Widget>[
    DashboardScreen(),
    MyPageScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
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
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        onTap: _onItemTapped,
      ),
    );
  }
}

// 2. 대시보드 (첫 화면)
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 상단: 앱 타이틀 또는 로고 영역
            const Text(
              'NUTRI Agent',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B8E23),
              ),
            ),
            const SizedBox(height: 24),

            // 상단: 날씨 및 오늘 하루 브리핑 공간
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.wb_sunny, color: Colors.orangeAccent, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        '서울시 맑음, 22°C',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 30, thickness: 1, color: Color(0xFFEEEEEE)),
                  Text(
                    '오늘의 브리핑',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '상쾌한 날씨입니다. 매일 하시는 5km 러닝 후 근손실 방지를 위해 오늘은 단백질이 풍부하고 예산에 맞는 메뉴를 추천해 드릴 준비가 되었습니다.',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            
            const Spacer(),

            // 중앙/하단: 메뉴 추천 바로가기 버튼
            ElevatedButton(
              onPressed: () {
                // TODO: 메뉴 추천 API 호출 및 로직 연결
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant_menu, size: 24),
                  SizedBox(width: 12),
                  Text(
                    '맞춤 메뉴 추천 받기',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// 3. 마이페이지 (임시 빈 화면)
class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '마이페이지 화면입니다.',
        style: TextStyle(fontSize: 18, color: Colors.grey),
      ),
    );
  }
}