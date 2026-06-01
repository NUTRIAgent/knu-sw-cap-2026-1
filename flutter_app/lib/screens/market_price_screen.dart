import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_app/models/market_price_models.dart';
import 'package:flutter_app/screens/market_price_detail_screen.dart';
import 'package:flutter_app/services/favorite_ingredient_service.dart';
import 'package:flutter_app/services/market_price_service.dart';
import 'package:flutter_app/theme.dart';

enum _KamisSort { none, risingFirst, fallingFirst }

enum _NaverSort { none, cheapest, expensive }

class MarketPriceScreen extends StatefulWidget {
  const MarketPriceScreen({super.key});

  @override
  State<MarketPriceScreen> createState() => _MarketPriceScreenState();
}

class _MarketPriceScreenState extends State<MarketPriceScreen>
    with SingleTickerProviderStateMixin {
  List<IngredientPriceModel> _kamisPrices = [];
  List<IngredientPriceModel> _kamisFiltered = [];
  List<IngredientPriceModel> _naverPrices = [];
  List<IngredientPriceModel> _naverFiltered = [];
  Set<int> _favoriteIds = {};
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;
  bool _showFavoritesOnly = false;
  _KamisSort _kamisSort = _KamisSort.none;
  _NaverSort _naverSort = _NaverSort.none;
  final TextEditingController _searchController = TextEditingController();

  bool get _isNaverTab => _tabController.index == 1;

  List<IngredientPriceModel> get _currentFiltered =>
      _isNaverTab ? _naverFiltered : _kamisFiltered;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
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
        MarketPriceService.getNaverShoppingPrices(),
        FavoriteIngredientService.getFavoriteIds(),
      ]);
      final kamisPrices = results[0] as List<IngredientPriceModel>;
      final naverPrices = results[1] as List<IngredientPriceModel>;
      final favIds = results[2] as Set<int>;
      setState(() {
        _kamisPrices = kamisPrices;
        _naverPrices = naverPrices;
        _favoriteIds = favIds;
        _updateDisplayLists();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<IngredientPriceModel> _applyFilter(
    List<IngredientPriceModel> source, {
    bool applyFav = false,
  }) {
    final q = _searchController.text.trim();
    var list = (applyFav && _showFavoritesOnly)
        ? source
            .where((p) =>
                p.ingredientId != null && _favoriteIds.contains(p.ingredientId))
            .toList()
        : List<IngredientPriceModel>.from(source);
    if (q.isNotEmpty) {
      list = list.where((p) => p.ingredientName.contains(q)).toList();
    }
    return list;
  }

  List<IngredientPriceModel> _applySort(
    List<IngredientPriceModel> list, {
    bool naver = false,
  }) {
    final sorted = List<IngredientPriceModel>.from(list);
    if (naver) {
      switch (_naverSort) {
        case _NaverSort.cheapest:
          sorted.sort((a, b) => a.pricePerGram.compareTo(b.pricePerGram));
        case _NaverSort.expensive:
          sorted.sort((a, b) => b.pricePerGram.compareTo(a.pricePerGram));
        case _NaverSort.none:
          break;
      }
    } else {
      switch (_kamisSort) {
        case _KamisSort.risingFirst:
          sorted.sort((a, b) {
            final ar = a.dayChangeRate ?? double.negativeInfinity;
            final br = b.dayChangeRate ?? double.negativeInfinity;
            return br.compareTo(ar);
          });
        case _KamisSort.fallingFirst:
          sorted.sort((a, b) {
            final ar = a.dayChangeRate ?? double.infinity;
            final br = b.dayChangeRate ?? double.infinity;
            return ar.compareTo(br);
          });
        case _KamisSort.none:
          break;
      }
    }
    return sorted;
  }

  void _updateDisplayLists() {
    _kamisFiltered = _applySort(_applyFilter(_kamisPrices));
    _naverFiltered =
        _applySort(_applyFilter(_naverPrices, applyFav: true), naver: true);
  }

  void _onSearch(String query) {
    setState(() {
      _updateDisplayLists();
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
      _updateDisplayLists();
    });
    try {
      if (isFav) {
        await FavoriteIngredientService.removeFavorite(id);
      } else {
        await FavoriteIngredientService.addFavorite(id);
      }
    } catch (_) {
      setState(() {
        if (isFav) {
          _favoriteIds = Set.from(_favoriteIds)..add(id);
        } else {
          _favoriteIds = Set.from(_favoriteIds)..remove(id);
        }
        _updateDisplayLists();
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
            _buildTabBar(),
            _buildSearchBar(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final subtitle = _isNaverTab
        ? '네이버쇼핑 기준 레시피 재료 온라인 단가'
        : 'KAMIS 농수산물 전일 대비 등락 정보';
    final notice = _isNaverTab
        ? '레시피 재료 온라인 기준 · 실제 판매가와 다를 수 있음'
        : '도소매 기준 · 실제 마트·시장 가격과 다를 수 있음';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) =>
                AppTheme.aiGradient.createShader(bounds),
            child: const Text(
              '식재료 가격 동향',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    size: 13, color: AppTheme.primaryColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    notice,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.primaryColor.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      unselectedLabelStyle:
          const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      labelColor: AppTheme.primaryColor,
      unselectedLabelColor: Colors.grey,
      indicatorColor: AppTheme.primaryColor,
      indicatorWeight: 2.5,
      tabs: const [
        Tab(text: '가격 동향'),
        Tab(text: '온라인 단가'),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Row(
        children: [
          Expanded(
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
          ),
          const SizedBox(width: 8),
          _buildSortButton(),
        ],
      ),
    );
  }

  Widget _buildSortButton() {
    final hasActive = _isNaverTab
        ? (_showFavoritesOnly || _naverSort != _NaverSort.none)
        : _kamisSort != _KamisSort.none;

    return PopupMenuButton<String>(
      offset: const Offset(0, 40),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.tune,
            color: hasActive ? AppTheme.primaryColor : Colors.grey[600],
            size: 22,
          ),
          if (hasActive)
            Positioned(
              right: -3,
              top: -3,
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
      onSelected: (value) {
        setState(() {
          if (_isNaverTab) {
            switch (value) {
              case 'fav':
                _showFavoritesOnly = !_showFavoritesOnly;
              case 'naver_none':
                _naverSort = _NaverSort.none;
              case 'cheapest':
                _naverSort = _NaverSort.cheapest;
              case 'expensive':
                _naverSort = _NaverSort.expensive;
            }
          } else {
            switch (value) {
              case 'kamis_none':
                _kamisSort = _KamisSort.none;
              case 'rising':
                _kamisSort = _KamisSort.risingFirst;
              case 'falling':
                _kamisSort = _KamisSort.fallingFirst;
            }
          }
          _updateDisplayLists();
        });
      },
      itemBuilder: (context) {
        if (_isNaverTab) {
          return [
            PopupMenuItem<String>(
              value: 'fav',
              child: Row(
                children: [
                  Icon(
                    _showFavoritesOnly
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    size: 20,
                    color: _showFavoritesOnly
                        ? AppTheme.primaryColor
                        : Colors.grey[500],
                  ),
                  const SizedBox(width: 8),
                  const Text('관심 재료만 보기'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            _sortMenuItem('naver_none', '기본 순', _naverSort == _NaverSort.none),
            _sortMenuItem(
                'cheapest', '저렴한 순', _naverSort == _NaverSort.cheapest),
            _sortMenuItem(
                'expensive', '비싼 순', _naverSort == _NaverSort.expensive),
          ];
        } else {
          return [
            _sortMenuItem(
                'kamis_none', '기본 순', _kamisSort == _KamisSort.none),
            _sortMenuItem('rising', '상승률 높은 순',
                _kamisSort == _KamisSort.risingFirst),
            _sortMenuItem('falling', '하락률 높은 순',
                _kamisSort == _KamisSort.fallingFirst),
          ];
        }
      },
    );
  }

  PopupMenuItem<String> _sortMenuItem(
      String value, String label, bool selected) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(
            Icons.check,
            size: 18,
            color: selected ? AppTheme.primaryColor : Colors.transparent,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              color: selected ? AppTheme.primaryColor : Colors.black87,
            ),
          ),
        ],
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

    if (_currentFiltered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isNaverTab && _showFavoritesOnly
                  ? Icons.favorite_border
                  : Icons.search_off,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              _isNaverTab && _showFavoritesOnly
                  ? '관심 재료를 추가해보세요\n시세 카드의 하트를 눌러 저장할 수 있어요'
                  : (_searchController.text.isNotEmpty
                      ? "'${_searchController.text}'에 대한 시세 정보가 없습니다"
                      : '시세 정보가 없습니다'),
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: Colors.grey[600], fontSize: 15, height: 1.5),
            ),
          ],
        ),
      );
    }

    final bool showSummary = !_isNaverTab &&
        !_showFavoritesOnly &&
        _searchController.text.isEmpty &&
        _kamisSort == _KamisSort.none &&
        _kamisPrices.any((p) => p.dayChangeRate != null);

    return RefreshIndicator(
      color: AppTheme.primaryColor,
      onRefresh: _loadAll,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        itemCount: _currentFiltered.length + (showSummary ? 1 : 0),
        itemBuilder: (context, index) {
          if (showSummary && index == 0) return _buildSummarySection();
          final item = _currentFiltered[showSummary ? index - 1 : index];
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
    final withRates =
        _kamisPrices.where((p) => p.dayChangeRate != null).toList();
    final upItems = withRates.where((p) => p.dayChangeRate! >= 3.0).toList()
      ..sort((a, b) => b.dayChangeRate!.compareTo(a.dayChangeRate!));
    final downItems = withRates.where((p) => p.dayChangeRate! <= -3.0).toList()
      ..sort((a, b) => a.dayChangeRate!.compareTo(b.dayChangeRate!));

    if (upItems.isEmpty && downItems.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              '오늘의 주요 변동',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black54,
              ),
            ),
          ),
          _buildMarqueeRow(upItems, true),
          const SizedBox(height: 6),
          _buildMarqueeRow(downItems, false),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildMarqueeRow(List<IngredientPriceModel> items, bool isUp) {
    final color =
        isUp ? const Color(0xFFE53935) : const Color(0xFF1E88E5);
    final icon = isUp ? Icons.arrow_upward : Icons.arrow_downward;
    final label = isUp ? '상승' : '하락';

    return SizedBox(
      height: 34,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 11, color: color),
                const SizedBox(width: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 16, color: Colors.grey.shade200),
          const SizedBox(width: 8),
          Expanded(
            child: items.isEmpty
                ? Text(
                    '오늘 해당 없음',
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  )
                : _MarqueeStrip(
                    items: items,
                    chipBuilder: (p) => _buildSummaryChip(p, isUp),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(IngredientPriceModel price, bool isUp) {
    final color =
        isUp ? const Color(0xFFE53935) : const Color(0xFF1E88E5);
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
    final isFav =
        price.ingredientId != null && _favoriteIds.contains(price.ingredientId);
    final sourceLabel = _isNaverTab ? '네이버쇼핑' : 'KAMIS';

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
                  if (price.originalPrice != null &&
                      price.originalUnit != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      '${price.displayPrice} · $sourceLabel',
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey[400]),
                    ),
                  ],
                ],
              ),
            ),
            if (price.dayChangeRate != null)
              _buildChangeRateColumn(price.dayChangeRate!),
            if (!_isNaverTab)
              const SizedBox(width: 4)
            else ...[
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
          isFavorite: price.ingredientId != null &&
              _favoriteIds.contains(price.ingredientId),
          onFavoriteToggle: price.ingredientId != null
              ? () => _toggleFavorite(price)
              : null,
        ),
      ),
    );
  }
}

class _MarqueeStrip extends StatefulWidget {
  final List<IngredientPriceModel> items;
  final Widget Function(IngredientPriceModel) chipBuilder;

  const _MarqueeStrip({
    required this.items,
    required this.chipBuilder,
  });

  @override
  State<_MarqueeStrip> createState() => _MarqueeStripState();
}

class _MarqueeStripState extends State<_MarqueeStrip>
    with SingleTickerProviderStateMixin {
  final ScrollController _controller = ScrollController();
  Ticker? _ticker;
  Duration _lastElapsed = Duration.zero;

  static const int _repeatCount = 4;
  static const double _pixelsPerMs = 0.04; // 40px/s

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScroll());
  }

  @override
  void didUpdateWidget(_MarqueeStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _ticker?.stop();
      if (_controller.hasClients) _controller.jumpTo(0);
      _lastElapsed = Duration.zero;
      WidgetsBinding.instance.addPostFrameCallback((_) => _startScroll());
    }
  }

  void _startScroll() {
    _ticker?.dispose();
    _lastElapsed = Duration.zero;
    _ticker = createTicker((elapsed) {
      if (!_controller.hasClients) return;
      final pos = _controller.position;
      final max = pos.maxScrollExtent;
      if (max <= 0) return;

      final deltaMs = (elapsed - _lastElapsed).inMicroseconds / 1000.0;
      _lastElapsed = elapsed;

      // 전체 콘텐츠 너비의 1/_repeatCount 지점에서 처음으로 점프 (seamless loop)
      final singleWidth = (max + pos.viewportDimension) / _repeatCount;
      final next = pos.pixels + (_pixelsPerMs * deltaMs);
      _controller.jumpTo(next >= singleWidth ? next - singleWidth : next);
    });
    _ticker!.start();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allItems = List.generate(_repeatCount, (_) => widget.items)
        .expand((x) => x)
        .toList();

    return SingleChildScrollView(
      controller: _controller,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Row(
        children: [
          for (final item in allItems) ...[
            widget.chipBuilder(item),
            const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}
