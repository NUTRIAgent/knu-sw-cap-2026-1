import 'package:flutter/material.dart';
import 'package:flutter_app/models/recommendation_models.dart';
import 'package:flutter_app/screens/menu_detail_screen.dart' show AiPickBody;
import 'package:flutter_app/services/recommendation_service.dart';
import 'package:flutter_app/theme.dart';

class RecommendationHistoryDetailScreen extends StatefulWidget {
  final int logId;
  final RecommendationResult result;
  final int? initialStarRating;
  final String? initialFeedbackReason;
  final String? youtubeVideoId;
  final String jwt;

  const RecommendationHistoryDetailScreen({
    super.key,
    required this.logId,
    required this.result,
    this.initialStarRating,
    this.initialFeedbackReason,
    this.youtubeVideoId,
    required this.jwt,
  });

  @override
  State<RecommendationHistoryDetailScreen> createState() =>
      _RecommendationHistoryDetailScreenState();
}

class _RecommendationHistoryDetailScreenState
    extends State<RecommendationHistoryDetailScreen> {
  late int _starRating;
  late TextEditingController _reasonController;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _starRating = widget.initialStarRating ?? 0;
    _reasonController =
        TextEditingController(text: widget.initialFeedbackReason ?? '');
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (_starRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('별점을 선택해주세요')),
      );
      return;
    }
    setState(() => _submitting = true);
    final ok = await RecommendationService.updateFeedback(
      widget.logId,
      _starRating,
      _reasonController.text.trim(),
      widget.jwt,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? '피드백이 저장됐습니다' : '저장에 실패했습니다')),
    );
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(widget.result.menuName,
            style: const TextStyle(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppTheme.backgroundColor,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: AppTheme.aiGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, color: Colors.white, size: 12),
                SizedBox(width: 4),
                Text('AI 픽',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // AI 결과 본문 재현
            AiPickBody(
              result: widget.result,
              youtubeVideoId: widget.youtubeVideoId,
            ),
            // 피드백 폼
            _buildFeedbackSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('이 추천은 어떠셨나요?',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (i) => IconButton(
                icon: Icon(
                  i < _starRating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: 40,
                  color: i < _starRating ? Colors.amber : Colors.grey[300],
                ),
                onPressed: () => setState(() => _starRating = i + 1),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reasonController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: '한 줄 코멘트 (선택)',
              hintStyle:
                  TextStyle(color: Colors.grey[400], fontSize: 14),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submitFeedback,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('피드백 저장',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
