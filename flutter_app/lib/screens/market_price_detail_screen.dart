import 'package:flutter/material.dart';
import 'package:flutter_app/models/market_price_models.dart';
import 'package:flutter_app/theme.dart';
import 'package:url_launcher/url_launcher.dart';

class MarketPriceDetailScreen extends StatefulWidget {
  final IngredientPriceModel price;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  const MarketPriceDetailScreen({
    super.key,
    required this.price,
    this.isFavorite = false,
    this.onFavoriteToggle,
  });

  @override
  State<MarketPriceDetailScreen> createState() =>
      _MarketPriceDetailScreenState();
}

class _MarketPriceDetailScreenState extends State<MarketPriceDetailScreen> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite;
  }

  void _handleFavoriteToggle() {
    setState(() => _isFavorite = !_isFavorite);
    widget.onFavoriteToggle?.call();
  }

  Future<void> _openNaverShopping() async {
    final url = Uri.https('search.shopping.naver.com', '/search/all', {
      'query': widget.price.ingredientName,
    });
    final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('브라우저를 열 수 없습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPriceHeroCard(),
                    const SizedBox(height: 12),
                    _buildNaverShoppingButton(),
                    const SizedBox(height: 16),
                    _buildChangeRatesCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              widget.price.ingredientName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
          if (widget.onFavoriteToggle != null)
            IconButton(
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.redAccent : Colors.grey[400],
              ),
              onPressed: _handleFavoriteToggle,
            ),
        ],
      ),
    );
  }

  Widget _buildPriceHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.aiGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '현재 시세',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.price.displayPrice,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.price.displayDate,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.verified_outlined,
                size: 12,
                color: Colors.white.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              Text(
                'KAMIS 한국농수산식품유통공사 제공',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNaverShoppingButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _openNaverShopping,
        icon: const Icon(Icons.open_in_new_rounded, size: 18),
        label: const Text(
          '네이버 쇼핑에서 가격 비교',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF03C75A), // 네이버 브랜드 그린
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildChangeRatesCard() {
    final p = widget.price;
    final hasAny =
        p.dayChangeRate != null ||
        p.weekChangeRate != null ||
        p.monthChangeRate != null;
    if (!hasAny) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
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
            '가격 변동률',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          if (p.dayChangeRate != null) _buildRateBar('전일 대비', p.dayChangeRate!),
          if (p.weekChangeRate != null) ...[
            const SizedBox(height: 14),
            _buildRateBar('1주일 전 대비', p.weekChangeRate!),
          ],
          if (p.monthChangeRate != null) ...[
            const SizedBox(height: 14),
            _buildRateBar('1개월 전 대비', p.monthChangeRate!),
          ],
        ],
      ),
    );
  }

  Widget _buildRateBar(String label, double rate) {
    final isPositive = rate > 0;
    final isZero = rate == 0;
    final color = isZero
        ? Colors.grey
        : (isPositive ? const Color(0xFFE53935) : const Color(0xFF1E88E5));
    final fill = (rate.abs() / 30.0).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            Text(
              isZero
                  ? '변동 없음'
                  : '${isPositive ? '+' : ''}${rate.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fill,
            minHeight: 6,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
