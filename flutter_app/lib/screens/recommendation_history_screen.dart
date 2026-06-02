import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_app/models/recommendation_models.dart';
import 'package:flutter_app/notifiers.dart';
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

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    final items = await RecommendationService.fetchMyAiPicks(widget.jwt);
    if (mounted) setState(() { _items = items; _loading = false; });
  }

  // ── 피드백 BottomSheet ─────────────────────────────

  Future<void> _showFeedbackBottomSheet(AiPickItem item) async {
    int starRating = item.starRating ?? 0;
    final reasonController =
        TextEditingController(text: item.feedbackReason ?? '');
    bool submitting = false; // 빌더 밖에서 선언 — rebuild 시 리셋 방지
    bool? feedbackResult; // null=미제출, true=성공, false=실패

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (_, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              20,
              24,
              MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 핸들 바
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  item.menuName,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '이 추천은 어떠셨나요?',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
                const SizedBox(height: 16),
                // 별점
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (i) => IconButton(
                      icon: Icon(
                        i < starRating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 38,
                        color: i < starRating ? Colors.amber : Colors.grey[300],
                      ),
                      onPressed: () =>
                          setSheetState(() => starRating = i + 1),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // 코멘트
                TextField(
                  controller: reasonController,
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
                // 저장 버튼
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: submitting || starRating == 0
                        ? null
                        : () async {
                            setSheetState(() => submitting = true);
                            final ok =
                                await RecommendationService.updateFeedback(
                              item.id,
                              starRating,
                              reasonController.text.trim(),
                              widget.jwt,
                            );
                            feedbackResult = ok;
                            if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: submitting
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
        },
      ),
    );

    // 닫힘 애니메이션 중 리빌드가 컨트롤러를 참조할 수 있으므로 다음 프레임 후 dispose
    WidgetsBinding.instance.addPostFrameCallback((_) => reasonController.dispose());

    if (!mounted) return;
    if (feedbackResult == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('피드백이 저장됐습니다')),
      );
      feedbackRefreshNotifier.value++;
      await _load(silent: true);
    } else if (feedbackResult == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장에 실패했습니다')),
      );
    }
  }

  Future<void> _confirmDelete(AiPickItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('이력 삭제'),
        content: Text('"${item.menuName}" 추천 이력을 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await RecommendationService.deleteFeedback(item.id, widget.jwt);
    if (!mounted) return;
    if (ok) {
      feedbackRefreshNotifier.value++;
      await _load(silent: true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('삭제에 실패했습니다')),
      );
    }
  }

  // ── 빌드 ──────────────────────────────────────────

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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        children: [
          // ── 상단: 이력 정보 (탭 → 상세 화면) ──
          GestureDetector(
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
                  builder: (_) =>
                      RecommendationHistoryDetailScreen(result: result!),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  if (item.menuImageUrl != null &&
                      item.menuImageUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        item.menuImageUrl!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, e, s) => _imagePlaceholder(),
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
                            style:
                                TextStyle(fontSize: 12, color: Colors.grey[400]),
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
          ),
          // ── 구분선 ──
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
          // ── 하단: 피드백 | 삭제 버튼 ──
          SizedBox(
            height: 40,
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => _showFeedbackBottomSheet(item),
                    style: TextButton.styleFrom(
                      foregroundColor: item.starRating != null
                          ? Colors.grey[500]
                          : AppTheme.primaryColor,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.starRating != null
                              ? Icons.edit_outlined
                              : Icons.star_border_rounded,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.starRating != null ? '피드백 수정' : '피드백 남기기',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                    width: 1, height: 24,
                    child: VerticalDivider(thickness: 1, color: Color(0xFFF0F0F0))),
                Expanded(
                  child: TextButton(
                    onPressed: () => _confirmDelete(item),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red[300],
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 14),
                        SizedBox(width: 4),
                        Text('삭제',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
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
