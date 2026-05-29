import 'package:flutter/material.dart';
import 'package:flutter_app/models/market_price_models.dart';
import 'package:flutter_app/screens/market_price_detail_screen.dart';
import 'package:flutter_app/services/favorite_ingredient_service.dart';
import 'package:flutter_app/services/market_price_service.dart';
import 'package:flutter_app/theme.dart';

class MarketPriceScreen extends StatefulWidget {
  const MarketPriceScreen({super.key});

  @override
  State<MarketPriceScreen> createState() => _MarketPriceScreenState();
}

class _MarketPriceScreenState extends State<MarketPriceScreen> {
  List<IngredientPriceModel> _allPrices = [];
  List<IngredientPriceModel> _filtered = [];
  Set<int> _favoriteIds = {};
  bool _isLoading = true;
  String? _error;
  bool _showFavoritesOnly = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        MarketPriceService.getAllPrices(),
        FavoriteIngredientService.getFavoriteIds(),
      ]);
      final prices = results[0] as List<IngredientPriceModel>;
      final favIds = results[1] as Set<int>;
      setState(() {
        _allPrices = prices;
        _favoriteIds = favIds;
        _filtered = _applyFilter(prices);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<IngredientPriceModel> _applyFilter(List<IngredientPriceModel> source) {
    final q = _searchController.text.trim();
    var list = _showFavoritesOnly
        ? source.where((p) => p.ingredientId != null && _favoriteIds.contains(p.ingredientId)).toList()
        : source;
    if (q.isNotEmpty) {
      list = list.where((p) => p.ingredientName.contains(q)).toList();
    }
    return list;
  }

  void _onSearch(String query) {
    setState(() => _filtered = _applyFilter(_allPrices));
  }

  void _onTabChanged(bool favoritesOnly) {
    setState(() {
      _showFavoritesOnly = favoritesOnly;
      _filtered = _applyFilter(_allPrices);
    });
  }

  Future<void> _toggleFavorite(IngredientPriceModel price) async {
    final id = price.ingredientId;
    if (id == null) return;
    final isFav = _favoriteIds.contains(id);
    setState(() {
      if (isFav) {
        _favoriteIds = Set.from(_favoriteIds)..remove(id);
      } else {
        _favoriteIds = Set.from(_favoriteIds)..add(id);
      }
      _filtered = _applyFilter(_allPrices);
    });
    try {
      if (isFav) {
        await FavoriteIngredientService.removeFavorite(id);
      } else {
        await FavoriteIngredientService.addFavorite(id);
      }
    } catch (_) {
      // 실패 시 롤백
      setState(() {
        if (isFav) {
          _favoriteIds = Set.from(_favoriteIds)..add(id);
        } else {
          _favoriteIds = Set.from(_favoriteIds)..remove(id);
        }
        _filtered = _applyFilter(_allPrices);
      });
    }
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
            _buildTabRow(),
            _buildSearchBar(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => AppTheme.aiGradient.createShader(bounds),
            child: const Text(
              '식재료 가격 동향',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'KAMIS 농수산물 전일 대비 등락 정보',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 13, color: Colors.amber.shade700),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '도·소매 기준 가격으로, 실제 마트·시장 판매가와 다를 수 있습니다.',
                    style: TextStyle(fontSize: 11, color: Colors.amber.shade800),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
      child: Row(
        children: [
          _buildTabChip('전체', !_showFavoritesOnly, () => _onTabChanged(false)),
          const SizedBox(width: 8),
          _buildTabChip('관심 재료', _showFavoritesOnly, () => _onTabChanged(true)),
        ],
      ),
    );
  }

  Widget _buildTabChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearch,
        decoration: InputDecoration(
          hintText: '재료명 검색 (예: 감자, 양파)',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[400]),
                  onPressed: () {
                    _searchController.clear();
                    _onSearch('');
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              '데이터를 불러오지 못했습니다',
              style: TextStyle(color: Colors.grey[600], fontSize: 15),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadAll, child: const Text('다시 시도')),
          ],
        ),
      );
    }

    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _showFavoritesOnly ? Icons.favorite_border : Icons.search_off,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              _showFavoritesOnly
                  ? '관심 재료를 추가해보세요\n시세 카드의 하트를 눌러 저장할 수 있어요'
                  : (_searchController.text.isNotEmpty
                      ? "'${_searchController.text}'에 대한 시세 정보가 없습니다"
                      : '시세 정보가 없습니다'),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 15, height: 1.5),
            ),
          ],
        ),
      );
    }

    final bool showSummary = !_showFavoritesOnly &&
        _searchController.text.isEmpty &&
        _allPrices.any((p) => p.dayChangeRate != null);

    return RefreshIndicator(
      color: AppTheme.primaryColor,
      onRefresh: _loadAll,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        itemCount: _filtered.length + (showSummary ? 1 : 0),
        itemBuilder: (context, index) {
          if (showSummary && index == 0) return _buildSummarySection();
          final item = _filtered[showSummary ? index - 1 : index];
          return _buildPriceCard(item);
        },
      ),
    );
  }

  Widget _buildChangeRateColumn(double rate) {
    final isPositive = rate > 0;
    final isZero = rate == 0;
    final color = isZero
        ? Colors.grey
        : (isPositive ? const Color(0xFFE53935) : const Color(0xFF1E88E5));
    final icon = isZero
        ? Icons.remove
        : (isPositive ? Icons.arrow_upward : Icons.arrow_downward);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 2),
            Text(
              isZero ? '0%' : '${rate.abs().toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        Text(
          '전일 대비',
          style: TextStyle(fontSize: 10, color: Colors.grey[400]),
        ),
      ],
    );
  }

  Widget _buildSummarySection() {
    final withRates = _allPrices.where((p) => p.dayChangeRate != null).toList();
    final topUp = (withRates.where((p) => p.dayChangeRate! > 0).toList()
          ..sort((a, b) => b.dayChangeRate!.compareTo(a.dayChangeRate!)))
        .take(3)
        .toList();
    final topDown = (withRates.where((p) => p.dayChangeRate! < 0).toList()
          ..sort((a, b) => a.dayChangeRate!.compareTo(b.dayChangeRate!)))
        .take(3)
        .toList();

    if (topUp.isEmpty && topDown.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '오늘의 주요 변동',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 10),
          if (topUp.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: topUp.map((p) => _buildSummaryChip(p, true)).toList(),
            ),
          if (topUp.isNotEmpty && topDown.isNotEmpty) const SizedBox(height: 6),
          if (topDown.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: topDown.map((p) => _buildSummaryChip(p, false)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(IngredientPriceModel price, bool isUp) {
    final color = isUp ? const Color(0xFFE53935) : const Color(0xFF1E88E5);
    final icon = isUp ? Icons.arrow_upward : Icons.arrow_downward;
    final rate = price.dayChangeRate!.abs().toStringAsFixed(1);
    return GestureDetector(
      onTap: () => _pushDetail(price),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 3),
            Text(
              price.ingredientName,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '$rate%',
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceCard(IngredientPriceModel price) {
    final isFav = price.ingredientId != null && _favoriteIds.contains(price.ingredientId);
    return GestureDetector(
      onTap: () => _pushDetail(price),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.storefront_outlined,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    price.ingredientName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  if (price.originalPrice != null && price.originalUnit != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      '${price.displayPrice} · KAMIS',
                      style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                    ),
                  ],
                ],
              ),
            ),
            if (price.dayChangeRate != null)
              _buildChangeRateColumn(price.dayChangeRate!),
            const SizedBox(width: 8),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _toggleFavorite(price),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  size: 20,
                  color: isFav ? Colors.redAccent : Colors.grey[400],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _pushDetail(IngredientPriceModel price) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MarketPriceDetailScreen(
          price: price,
          isFavorite: price.ingredientId != null && _favoriteIds.contains(price.ingredientId),
          onFavoriteToggle: price.ingredientId != null ? () => _toggleFavorite(price) : null,
        ),
      ),
    );
  }
}
