import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_app/models/recommendation_models.dart';
import 'package:flutter_app/screens/recommendation_history_detail_screen.dart';
import 'package:flutter_app/services/recommendation_service.dart';
import 'package:flutter_app/theme.dart';

class RecommendationHistoryScreen extends StatefulWidget {
  final String jwt;
  const RecommendationHistoryScreen({super.key, required this.jwt});

  @override
  State<RecommendationHistoryScreen> createState() =>
      _RecommendationHistoryScreenState();
}

class _RecommendationHistoryScreenState
    extends State<RecommendationHistoryScreen> {
  List<AiPickItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await RecommendationService.fetchMyAiPicks(widget.jwt);
    if (mounted) setState(() { _items = items; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('추천 이력',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppTheme.backgroundColor,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _items.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  color: AppTheme.primaryColor,
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _items.length,
                    itemBuilder: (context, index) =>
                        _buildCard(_items[index]),
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bookmark_border_rounded,
              size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('저장된 추천 이력이 없어요',
              style: TextStyle(fontSize: 16, color: Colors.grey[500])),
          const SizedBox(height: 8),
          Text('AI 픽 화면의 저장 버튼을 눌러보세요',
              style: TextStyle(fontSize: 13, color: Colors.grey[400])),
        ],
      ),
    );
  }

  Widget _buildCard(AiPickItem item) {
    return GestureDetector(
      onTap: () async {
        if (item.aiResultJson == null) return;
        RecommendationResult? result;
        try {
          result = RecommendationResult.fromJson(
              jsonDecode(item.aiResultJson!) as Map<String, dynamic>);
        } catch (_) {
          return;
        }
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RecommendationHistoryDetailScreen(
              logId: item.id,
              result: result!,
              initialStarRating: item.starRating,
              initialFeedbackReason: item.feedbackReason,
              jwt: widget.jwt,
            ),
          ),
        );
        _load();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
        child: Row(
          children: [
            if (item.menuImageUrl != null && item.menuImageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  item.menuImageUrl!,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      _imagePlaceholder(),
                ),
              )
            else
              _imagePlaceholder(),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.menuName,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  if (item.createdAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.createdAt!,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[400]),
                    ),
                  ],
                  if (item.starRating != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < item.starRating!
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 14,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.restaurant_menu,
          color: AppTheme.primaryColor, size: 24),
    );
  }
}
