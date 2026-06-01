import 'package:flutter/material.dart';
import 'package:flutter_app/services/cart_service.dart';
import 'package:flutter_app/theme.dart';
import 'package:url_launcher/url_launcher.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<CartItem> _items = [];
  final Set<String> _collapsed = {};

  @override
  void initState() {
    super.initState();
    _load();
    CartService.itemCount.addListener(_load);
  }

  @override
  void dispose() {
    CartService.itemCount.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final items = await CartService.getItems();
    if (mounted) setState(() => _items = items);
  }

  Future<void> _remove(CartItem item) async {
    await CartService.removeItem(item);
    await _load();
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('장바구니 비우기'),
        content: const Text('모든 재료를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('삭제', style: TextStyle(color: Colors.red[400])),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await CartService.clear();
      await _load();
    }
  }

  static String _nameOnly(String ingredient) {
    return ingredient
        .replaceAll(
          RegExp(
            r'\s+\d[\d./]*\s*'
            r'(g|kg|ml|l|L|개|컵|큰술|작은술|줌|봉|팩|캔|병|조각|인분|장|쪽|대|단|포|cc|꼬집|움큼)?'
            r'\s*$',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(
          RegExp(r'\s+(약간|조금|적당량|소량|한꼬집|취향껏|필요량|기호에따라)\s*$'),
          '',
        )
        .trim();
  }

  Future<void> _openNaver(String ingredient) async {
    final query = _nameOnly(ingredient);
    final uri = Uri.parse(
        'https://search.shopping.naver.com/search/all?query=${Uri.encodeComponent(query)}');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('브라우저를 열 수 없습니다')),
        );
      }
    }
  }

  /// menuName 기준으로 그룹핑
  Map<String, List<CartItem>> get _grouped {
    final map = <String, List<CartItem>>{};
    for (final item in _items) {
      final key = item.menuName.isEmpty ? '기타' : item.menuName;
      map.putIfAbsent(key, () => []).add(item);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(child: _items.isEmpty ? _buildEmpty() : _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 16, 8),
      child: Row(
        children: [
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => AppTheme.aiGradient.createShader(bounds),
            child: const Text(
              '장바구니',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),
          ),
          const Spacer(),
          if (_items.isNotEmpty)
            TextButton(
              onPressed: _clearAll,
              child: Text(
                '전체 비우기',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            '장바구니가 비어 있어요',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
          const SizedBox(height: 8),
          Text(
            '추천 메뉴 상세에서 재료를 담아보세요',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    final grouped = _grouped;
    final menuNames = grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      itemCount: menuNames.length,
      itemBuilder: (context, groupIndex) {
        final menuName = menuNames[groupIndex];
        final items = grouped[menuName]!;
        final isCollapsed = _collapsed.contains(menuName);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (groupIndex > 0) const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() {
                if (isCollapsed) {
                  _collapsed.remove(menuName);
                } else {
                  _collapsed.add(menuName);
                }
              }),
              child: Container(
                color: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 14,
                      decoration: BoxDecoration(
                        gradient: AppTheme.aiGradient,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        menuName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Text(
                      '${items.length}개',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      isCollapsed
                          ? Icons.keyboard_arrow_down_rounded
                          : Icons.keyboard_arrow_up_rounded,
                      size: 20,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ),
            ),
            if (!isCollapsed) ...items.map((item) => _buildItemCard(item)),
          ],
        );
      },
    );
  }

  Widget _buildItemCard(CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.only(left: 8, right: 16, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.close, size: 18, color: Colors.grey[400]),
            tooltip: '삭제',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => _remove(item),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.ingredient,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          GestureDetector(
            onTap: () => _openNaver(item.ingredient),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF03C75A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'N',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(width: 4),
                  Text(
                    '쇼핑',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
