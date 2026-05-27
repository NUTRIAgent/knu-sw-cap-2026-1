import 'package:flutter/material.dart';
import 'package:flutter_app/models/market_price_models.dart';
import 'package:flutter_app/theme.dart';

class MarketPriceDetailScreen extends StatelessWidget {
  final IngredientPriceModel price;

  const MarketPriceDetailScreen({super.key, required this.price});

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
                    const SizedBox(height: 16),
                    _buildChangeRatesCard(),
                    const SizedBox(height: 16),
                    _buildMarketInfoCard(),
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
      padding: const EdgeInsets.fromLTRB(8, 12, 24, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              price.ingredientName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
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
            price.displayPrice,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            price.displayDate,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangeRatesCard() {
    final hasAny = price.dayChangeRate != null ||
        price.weekChangeRate != null ||
        price.monthChangeRate != null;
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
          if (price.dayChangeRate != null)
            _buildRateBar('전일 대비', price.dayChangeRate!),
          if (price.weekChangeRate != null) ...[
            const SizedBox(height: 14),
            _buildRateBar('1주일 전 대비', price.weekChangeRate!),
          ],
          if (price.monthChangeRate != null) ...[
            const SizedBox(height: 14),
            _buildRateBar('1개월 전 대비', price.monthChangeRate!),
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

  Widget _buildMarketInfoCard() {
    if (price.marketName == null && price.marketType == null) {
      return const SizedBox.shrink();
    }

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
            '시장 정보',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 14),
          if (price.marketName != null) _buildInfoRow('시장명', price.marketName!),
          if (price.marketType != null) ...[
            const SizedBox(height: 10),
            _buildInfoRow('유형', price.marketType!),
          ],
          const SizedBox(height: 10),
          _buildInfoRow('기준일', price.displayDate),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
