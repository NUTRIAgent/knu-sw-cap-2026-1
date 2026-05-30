import 'package:flutter/material.dart';
import 'package:flutter_app/models/recommendation_models.dart';
import 'package:flutter_app/screens/menu_detail_screen.dart';
import 'package:flutter_app/services/recommendation_service.dart';
import 'package:flutter_app/theme.dart';

class RecommendationScreen extends StatefulWidget {
  final List<MenuCandidate> candidates;
  final RecommendationRequest request;

  const RecommendationScreen({
    super.key,
    required this.candidates,
    required this.request,
  });

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  late List<MenuCandidate> _candidates;
  late RecommendationRequest _currentRequest;

  final List<RecommendationResult> _aiResults = [];
  bool _aiLoading = true;
  String? _aiError;
  bool _reloading = false;

  final Set<int> _negativeFeedbackIds = {};
  final Set<int> _positiveFeedbackIds = {};

  int _rating = 0;
  final TextEditingController _feedbackController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _candidates = List.from(widget.candidates);
    _currentRequest = widget.request;
    _fetchAiResult();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _fetchAiResult() async {
    try {
      await for (final result in RecommendationService.recommendStream(_currentRequest)) {
        if (!mounted) return;
        setState(() => _aiResults.add(result));
      }
      if (mounted) setState(() => _aiLoading = false);
    } catch (e) {
      if (mounted) setState(() { _aiError = e.toString(); _aiLoading = false; });
    }
  }

  Future<void> _onFeedback(int menuId, bool isPositive) async {
    setState(() {
      if (isPositive) {
        _positiveFeedbackIds.add(menuId);
        _negativeFeedbackIds.remove(menuId);
      } else {
        _negativeFeedbackIds.add(menuId);
        _positiveFeedbackIds.remove(menuId);
      }
    });

    await RecommendationService.saveFeedback(
      menuId, isPositive ? 1 : -1, widget.request.jwtToken);

    _checkAllNegative();
  }

  void _checkAllNegative() {
    final aiPickIds = _aiResults.map((r) => r.menuId).toSet();
    final nonAiPick = _candidates.where((c) => !aiPickIds.contains(c.id)).toList();
    if (nonAiPick.isEmpty) return;
    if (nonAiPick.every((c) => _negativeFeedbackIds.contains(c.id))) {
      _reload();
    }
  }

  Future<void> _reload() async {
    if (_reloading) return;
    setState(() => _reloading = true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('후보 메뉴를 다시 불러오는 중입니다...')),
    );

    try {
      final newCandidates = await RecommendationService.fetchCandidates(widget.request.jwtToken);
      if (!mounted) return;
      setState(() {
        _candidates = newCandidates;
        _currentRequest = widget.request.copyWith(
          candidateMenuIds: newCandidates.map((c) => c.id).toList(),
        );
        _aiLoading = true;
        _aiResults.clear();
        _aiError = null;
        _negativeFeedbackIds.clear();
        _positiveFeedbackIds.clear();
        _reloading = false;
      });
      _fetchAiResult();
    } catch (_) {
      if (mounted) setState(() => _reloading = false);
    }
  }

  void _showFeedbackBottomSheet(int menuId) {
    _rating = 0;
    _feedbackController.clear();
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 32,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('이번 추천은 어떠셨나요?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => IconButton(
                  icon: Icon(
                    i < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 48,
                    color: i < _rating ? Colors.amber : Colors.grey[300],
                  ),
                  onPressed: () => setModal(() => _rating = i + 1),
                )),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _feedbackController,
                maxLines: 3,
                onChanged: (_) => setModal(() {}),
                decoration: InputDecoration(
                  hintText: '아쉬운 점이 있다면 알려주세요...',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Builder(
                builder: (_) {
                  final canSubmit =
                      _rating > 0 && _feedbackController.text.trim().isNotEmpty;
                  return Container(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: canSubmit ? AppTheme.aiGradient : null,
                      color: canSubmit ? null : Colors.grey[300],
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: ElevatedButton(
                      onPressed: canSubmit
                          ? () async {
                              final rating = _rating;
                              final reason = _feedbackController.text;
                              Navigator.pop(context);
                              await RecommendationService.saveDetailedFeedback(
                                  menuId, rating, reason, widget.request.jwtToken);
                              messenger.showSnackBar(
                                const SnackBar(content: Text('소중한 피드백 감사합니다!')),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: const StadiumBorder(),
                      ),
                      child: Text('피드백 제출하기',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: canSubmit ? Colors.white : Colors.grey[600])),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final aiPickIds = _aiResults.map((r) => r.menuId).toSet();

    return Scaffold(
      appBar: AppBar(
        title: const Text('맞춤 메뉴 추천', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                // ── AI 추천 섹션 ──────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: _AiPickSection(
                      loading: _aiLoading,
                      results: _aiResults,
                      error: _aiError,
                      onRetry: () {
                        setState(() { _aiLoading = true; _aiError = null; _aiResults.clear(); });
                        _fetchAiResult();
                      },
                      onDetailTap: (result) => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MenuDetailScreen(aiResult: result),
                        ),
                      ),
                      onFeedbackTap: (result) => _showFeedbackBottomSheet(result.menuId),
                    ),
                  ),
                ),

                // ── 후보 메뉴 헤더 ────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        const Icon(Icons.list_alt, size: 18, color: AppTheme.primaryColor),
                        const SizedBox(width: 6),
                        Text(
                          '후보 메뉴 ${_candidates.length}개',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        if (!_aiLoading) ...[
                          const SizedBox(width: 8),
                          Text(
                            '(마음에 드는 메뉴에 반응을 남겨보세요)',
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // ── 후보 메뉴 목록 ────────────────────────────
                _candidates.isEmpty
                    ? SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Text('후보 메뉴를 불러오지 못했습니다.',
                                style: TextStyle(color: Colors.grey[500])),
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) {
                            final c = _candidates[i];
                            final isAiPick = aiPickIds.contains(c.id);
                            bool? feedbackGiven;
                            if (_positiveFeedbackIds.contains(c.id)) feedbackGiven = true;
                            if (_negativeFeedbackIds.contains(c.id)) feedbackGiven = false;

                            return _CandidateCard(
                              candidate: c,
                              isAiPick: isAiPick,
                              showFeedback: !_aiLoading && !isAiPick,
                              feedbackGiven: feedbackGiven,
                              onFeedback: (isPos) => _onFeedback(c.id, isPos),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MenuDetailScreen(
                                    candidate: c,
                                    jwt: widget.request.jwtToken,
                                    request: _currentRequest,
                                  ),
                                ),
                              ),
                            );
                          },
                          childCount: _candidates.length,
                        ),
                      ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ],
            ),
          ),

        ],
      ),
    );
  }
}

// ── AI 추천 섹션 ─────────────────────────────────────────────
class _AiPickSection extends StatefulWidget {
  final bool loading;
  final List<RecommendationResult> results;
  final String? error;
  final VoidCallback onRetry;
  final void Function(RecommendationResult) onDetailTap;
  final void Function(RecommendationResult) onFeedbackTap;

  const _AiPickSection({
    required this.loading,
    required this.results,
    required this.error,
    required this.onRetry,
    required this.onDetailTap,
    required this.onFeedbackTap,
  });

  @override
  State<_AiPickSection> createState() => _AiPickSectionState();
}

class _AiPickSectionState extends State<_AiPickSection> {
  final PageController _pageController = PageController(viewportFraction: 0.92);
  int _currentPage = 0;

  @override
  void didUpdateWidget(_AiPickSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 로딩 완료 시 loading placeholder 페이지에 있었다면 마지막 결과 카드로 이동
    if (!widget.loading && oldWidget.loading && _currentPage >= widget.results.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.results.isNotEmpty) {
          _pageController.jumpToPage(widget.results.length - 1);
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasResults = widget.results.isNotEmpty;
    final pageCount = widget.results.length + (widget.loading ? 1 : 0);
    final displayCount = pageCount == 0 ? 1 : pageCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 헤더 ───────────────────────────────────────────
        Row(
          children: [
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (b) => AppTheme.aiGradient.createShader(b),
              child: const Icon(Icons.auto_awesome, size: 20),
            ),
            const SizedBox(width: 6),
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (b) => AppTheme.aiGradient.createShader(b),
              child: Text(
                widget.loading
                    ? 'AI 추천 분석 중 (${widget.results.length}/5)'
                    : 'AI 추천 ${widget.results.length}픽',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // ── 에러 (결과 없을 때) ─────────────────────────────
        if (!hasResults && !widget.loading && widget.error != null)
          _ErrorCard(error: widget.error!, onRetry: widget.onRetry)
        else
          // ── 카드 PageView ─────────────────────────────────
          SizedBox(
            height: 460,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemCount: displayCount,
              itemBuilder: (context, index) {
                if (!hasResults || index >= widget.results.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: _LoadingCard(),
                  );
                }
                final r = widget.results[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => widget.onDetailTap(r),
                    child: _ResultCard(
                      result: r,
                      onFeedbackTap: () => widget.onFeedbackTap(r),
                    ),
                  ),
                );
              },
            ),
          ),
        // ── 페이지 인디케이터 ──────────────────────────────
        if (displayCount > 1)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(displayCount, (i) {
                final isActive = i == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.primaryColor : Colors.grey[300],
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
        // ── 카드 탭 안내 ───────────────────────────────────
        if (hasResults)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app_rounded, size: 13, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text('카드를 누르면 레시피·재료 가격을 볼 수 있어요',
                    style: TextStyle(fontSize: 11, color: Colors.grey[400])),
              ],
            ),
          ),
        // ── 에러 (부분 결과 있을 때) ────────────────────────
        if (hasResults && widget.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _ErrorCard(error: widget.error!, onRetry: widget.onRetry),
          ),
      ],
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const SizedBox(
              width: 24, height: 24,
              child: CircularProgressIndicator(
                  color: AppTheme.primaryColor, strokeWidth: 2.5),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('AI가 최적 메뉴를 분석 중입니다...',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('후보 목록을 먼저 확인해보세요.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorCard({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 10),
            const Expanded(
                child: Text('AI 추천을 불러오지 못했습니다.',
                    style: TextStyle(fontSize: 13))),
            TextButton(onPressed: onRetry, child: const Text('재시도')),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final RecommendationResult result;
  final VoidCallback? onFeedbackTap;
  const _ResultCard({required this.result, this.onFeedbackTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (result.mainImg.isNotEmpty)
            Image.network(
              result.mainImg,
              height: 130,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                height: 130,
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                child: const Icon(Icons.restaurant, size: 48, color: AppTheme.primaryColor),
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(result.menuName,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(result.selectionReason,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.5)),
                  const SizedBox(height: 12),
                  _NutritionRow(info: result.nutritionInfo),
                  if (result.totalEstimatedCost > 0) ...[
                    const SizedBox(height: 10),
                    Row(children: [
                      const Icon(Icons.receipt_long_outlined,
                          size: 15, color: AppTheme.primaryColor),
                      const SizedBox(width: 4),
                      Text('예상 재료비 약 ${result.totalEstimatedCost.toInt()}원',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ]),
                  ],
                  const Spacer(),
                  const Divider(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onFeedbackTap,
                      icon: const Icon(Icons.star_outline_rounded, size: 15),
                      label: const Text('이 메뉴 피드백 남기기'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: const BorderSide(color: AppTheme.primaryColor, width: 1),
                        textStyle: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                        shape: const StadiumBorder(),
                      ),
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

// ── 영양 정보 칩 행 ───────────────────────────────────────────
class _NutritionRow extends StatelessWidget {
  final NutritionInfo info;
  const _NutritionRow({required this.info});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('열량', info.energy),
      ('단백질', info.protein),
      ('지방', info.fat),
      ('탄수화물', info.carbs),
      ('나트륨', info.sodium),
    ];
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: items.map((item) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text('${item.$1} ${item.$2}',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
      )).toList(),
    );
  }
}

// ── 후보 메뉴 카드 ────────────────────────────────────────────
class _CandidateCard extends StatelessWidget {
  final MenuCandidate candidate;
  final bool isAiPick;
  final bool showFeedback;
  final bool? feedbackGiven;
  final void Function(bool isPositive)? onFeedback;
  final VoidCallback? onTap;

  const _CandidateCard({
    required this.candidate,
    required this.isAiPick,
    required this.showFeedback,
    this.feedbackGiven,
    this.onFeedback,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: isAiPick
            ? Border.all(color: AppTheme.primaryColor, width: 2)
            : null,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: candidate.mainImageUrl != null &&
                      candidate.mainImageUrl!.isNotEmpty
                  ? Image.network(
                      candidate.mainImageUrl!,
                      width: 52, height: 52, fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(candidate.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 3),
                  Text(
                    [
                      if (candidate.calories != null)
                        '${candidate.calories!.toInt()} kcal',
                      if (candidate.protein != null)
                        '단백질 ${candidate.protein!.toStringAsFixed(1)}g',
                    ].join('  ·  '),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (isAiPick)
              _aiBadge()
            else if (showFeedback)
              _feedbackWidget(),
          ],
        ),
      ),
      ),
    );
  }

  Widget _aiBadge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          gradient: AppTheme.aiGradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text('AI 픽',
            style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold)),
      );

  Widget _feedbackWidget() {
    if (feedbackGiven != null) {
      return Icon(
        feedbackGiven! ? Icons.thumb_up_rounded : Icons.thumb_down_rounded,
        color: feedbackGiven! ? AppTheme.primaryColor : Colors.redAccent,
        size: 22,
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () => onFeedback?.call(true),
          icon: const Icon(Icons.thumb_up_outlined, size: 20),
          color: AppTheme.primaryColor,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
        IconButton(
          onPressed: () => onFeedback?.call(false),
          icon: const Icon(Icons.thumb_down_outlined, size: 20),
          color: Colors.grey,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
    );
  }

  Widget _placeholder() => Container(
        width: 52, height: 52,
        color: AppTheme.primaryColor.withValues(alpha: 0.08),
        child: const Icon(Icons.restaurant,
            size: 24, color: AppTheme.primaryColor),
      );
}

