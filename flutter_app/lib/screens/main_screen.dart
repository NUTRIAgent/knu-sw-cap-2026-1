import 'package:flutter/material.dart';
import 'package:flutter_app/services/cart_service.dart';
import 'package:flutter_app/theme.dart';
import 'cart_screen.dart';
import 'dashboard_screen.dart';
import 'market_price_screen.dart';
import 'mypage_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  int _cartCount = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    DashboardScreen(),
    MarketPriceScreen(),
    MyPageScreen(),
    CartScreen(),
  ];

  @override
  void initState() {
    super.initState();
    CartService.getItems();
    CartService.itemCount.addListener(_onCartCountChanged);
  }

  @override
  void dispose() {
    CartService.itemCount.removeListener(_onCartCountChanged);
    super.dispose();
  }

  void _onCartCountChanged() {
    if (mounted) setState(() => _cartCount = CartService.itemCount.value);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(index: _selectedIndex, children: _widgetOptions),

      // 💡 하단 네비게이션 바 전체를 Container로 감싸서 그림자와 라운딩 추가
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        // 💡 위쪽 양끝 모서리를 부드럽게 라운딩 처리 (24px)
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BottomNavigationBar(
            backgroundColor: Colors.white,
            elevation: 0, // Container의 boxShadow를 쓰기 위해 기본 그림자 제거
            type: BottomNavigationBarType.fixed,

            // 선택되지 않은 아이템 색상
            unselectedItemColor: Colors.grey.shade400,
            // 텍스트 라벨 색상은 프라이머리 컬러(Indigo)로 통일
            selectedItemColor: AppTheme.primaryColor,

            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: const Icon(Icons.home_filled),
                activeIcon: ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (Rect bounds) {
                    return AppTheme.aiGradient.createShader(bounds);
                  },
                  child: const Icon(Icons.home_filled),
                ),
                label: '대시보드',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.storefront_outlined),
                activeIcon: ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (Rect bounds) {
                    return AppTheme.aiGradient.createShader(bounds);
                  },
                  child: const Icon(Icons.storefront),
                ),
                label: '시세',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person),
                activeIcon: ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (Rect bounds) {
                    return AppTheme.aiGradient.createShader(bounds);
                  },
                  child: const Icon(Icons.person),
                ),
                label: '마이페이지',
              ),
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: _cartCount > 0,
                  label: Text('$_cartCount'),
                  child: const Icon(Icons.shopping_cart_outlined),
                ),
                activeIcon: Badge(
                  isLabelVisible: _cartCount > 0,
                  label: Text('$_cartCount'),
                  child: ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (Rect bounds) {
                      return AppTheme.aiGradient.createShader(bounds);
                    },
                    child: const Icon(Icons.shopping_cart),
                  ),
                ),
                label: '장바구니',
              ),
            ],
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
          ),
        ),
      ),
    );
  }
}
