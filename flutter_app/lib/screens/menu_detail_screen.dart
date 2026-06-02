import 'package:flutter/material.dart';
import 'package:flutter_app/models/recommendation_models.dart';
import 'package:flutter_app/services/cart_service.dart';
import 'package:flutter_app/services/recommendation_service.dart';
import 'package:flutter_app/theme.dart';

class MenuDetailScreen extends StatefulWidget {
  final MenuCandidate? candidate;
  final RecommendationResult? aiResult;
  final String? jwt;
  final RecommendationRequest? request; // 단일 AI 분석용 사용자 컨텍스트

  const MenuDetailScreen({
    super.key,
    this.candidate,
    this.aiResult,
    this.jwt,
    this.request,
  });

  @override
  State<MenuDetailScreen> createState() => _MenuDetailScreenState();
}

class _MenuDetailScreenState extends State<MenuDetailScreen> {
  MenuDetail? _detail;
  bool _loading = false;
  String? _error;

  // ── 단일 AI 분석 상태 ──
  RecommendationResult? _aiAnalysis;
  bool _aiLoading = false;
  String? _aiError;

  // ── 저장 상태 ──
  bool _saving = false;
  bool _saved = false;
  int? _savedLogId;

  // ── 피드백 상태 ──
  int _feedbackRating = 0;
  final TextEditingController _feedbackController = TextEditingController();

  bool get _isAiPick => widget.aiResult != null;

  @override
  void initState() {
    super.initState();
    if (!_isAiPick) _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    if (widget.candidate == null) return;
    setState(() { _loading = true; _error = null; });
    final detail = await RecommendationService.fetchMenuDetail(
        widget.candidate!.id, widget.jwt);
    if (!mounted) return;
    if (detail != null) {
      setState(() { _detail = detail; _loading = false; });
    } else {
      setState(() { _loading = false; _error = '상세 정보를 불러오지 못했습니다.'; });
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _showFeedbackBottomSheet(int menuId) {
    _feedbackRating = 0;
    _feedbackController.clear();
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 28,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('이번 추천은 어떠셨나요?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (i) => IconButton(
                    icon: Icon(
                      i < _feedbackRating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 44,
                      color: i < _feedbackRating
                          ? Colors.amber
                          : Colors.grey[300],
                    ),
                    onPressed: () =>
                        setModal(() => _feedbackRating = i + 1),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _feedbackController,
                maxLines: 3,
                onChanged: (_) => setModal(() {}),
                decoration: InputDecoration(
                  hintText: '아쉬운 점이 있다면 알려주세요...',
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
              const SizedBox(height: 20),
              Builder(builder: (_) {
                final canSubmit = _feedbackRating > 0 &&
                    _feedbackController.text.trim().isNotEmpty;
                return SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: canSubmit
                        ? () async {
                            final rating = _feedbackRating;
                            final reason = _feedbackController.text;
                            Navigator.pop(ctx);
                            await RecommendationService.saveDetailedFeedback(
                                menuId, rating, reason, widget.jwt);
                            messenger.showSnackBar(const SnackBar(
                                content: Text('소중한 피드백 감사합니다!')));
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      disabledBackgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('제출',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleSave(RecommendationResult result) async {
    if (_saving || widget.jwt == null) return;
    setState(() => _saving = true);
    if (_saved && _savedLogId != null) {
      final ok = await RecommendationService.deleteFeedback(_savedLogId!, widget.jwt);
      if (!mounted) return;
      setState(() { _saving = false; if (ok) { _saved = false; _savedLogId = null; } });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? '저장이 취소됐습니다' : '취소에 실패했습니다'),
        duration: const Duration(seconds: 2),
      ));
    } else {
      final id = await RecommendationService.saveAiResult(result, widget.jwt);
      if (!mounted) return;
      setState(() { _saving = false; _saved = id != null; _savedLogId = id; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(id != null ? '추천 이력에 저장됐습니다' : '저장에 실패했습니다'),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  Future<void> _requestAiAnalysis() async {
    if (widget.request == null || widget.candidate == null) return;
    setState(() { _aiLoading = true; _aiError = null; });
    try {
      final result = await RecommendationService.analyzeSelected(
        SelectMenuRequest.fromRecommendation(
            widget.request!, widget.candidate!.id),
      );
      if (!mounted) return;
      setState(() { _aiAnalysis = result; _aiLoading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _aiLoading = false; _aiError = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final shownAi = widget.aiResult ?? _aiAnalysis;
    final title = shownAi?.menuName ?? (widget.candidate?.name ?? '메뉴 상세');

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (shownAi != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (b) =>
                          AppTheme.aiGradient.createShader(b),
                      child: const Icon(Icons.auto_awesome, size: 11),
                    ),
                    const SizedBox(width: 3),
                    ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (b) =>
                          AppTheme.aiGradient.createShader(b),
                      child: const Text('AI 픽',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              Text(
                title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        centerTitle: false,
        toolbarHeight: 64,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        actions: shownAi != null && widget.jwt != null
            ? [
                IconButton(
                  onPressed: () => _showFeedbackBottomSheet(shownAi.menuId),
                  tooltip: 'AI 픽 별점',
                  icon: const Icon(Icons.star_outline_rounded),
                  color: Colors.grey[600],
                ),
                _saving
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppTheme.primaryColor),
                        ),
                      )
                    : IconButton(
                        onPressed: () => _toggleSave(shownAi),
                        tooltip: _saved ? '저장 취소' : '추천 결과 저장',
                        icon: Icon(_saved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_add_outlined),
                        color: _saved ? AppTheme.primaryColor : Colors.grey[600],
                      ),
                const SizedBox(width: 4),
              ]
            : null,
      ),
      body: shownAi != null
          ? AiPickBody(result: shownAi)
          : _CandidateBody(
              candidate: widget.candidate!,
              detail: _detail,
              loading: _loading,
              error: _error,
              onRetry: _fetchDetail,
              canRequestAi: widget.request != null,
              aiLoading: _aiLoading,
              aiError: _aiError,
              onRequestAi: _requestAiAnalysis,
            ),
    );
  }
}

// ── AI 픽 상세 본문 ──────────────────────────────────────────
class AiPickBody extends StatelessWidget {
  final RecommendationResult result;
  const AiPickBody({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeroImage(url: result.mainImg),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionCard(
                  icon: Icons.format_quote_rounded,
                  title: 'AI 선택 이유',
                  content: result.selectionReason,
                ),
                const SizedBox(height: 16),
                _NutritionSection(info: result.nutritionInfo),
                if (result.personalizedRecipeTip.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _PersonalizedTip(tip: result.personalizedRecipeTip),
                ],
                if (result.recipeSteps.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _RecipeSteps(steps: result.recipeSteps),
                ],
                if (result.naTip.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _SectionCard(
                    icon: Icons.water_drop_outlined,
                    title: '나트륨 관리 팁',
                    content: result.naTip,
                    iconColor: Colors.blue,
                  ),
                ],
                if (result.marketPrices.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _AiIngredientsCart(
                    prices: result.marketPrices,
                    menuName: result.menuName,
                  ),
                  const SizedBox(height: 16),
                  _MarketPricesTable(
                    prices: result.marketPrices,
                    total: result.totalEstimatedCost,
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 후보 메뉴 상세 본문 ──────────────────────────────────────
class _CandidateBody extends StatelessWidget {
  final MenuCandidate candidate;
  final MenuDetail? detail;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  // ── AI 분석 관련 ──
  final bool canRequestAi;
  final bool aiLoading;
  final String? aiError;
  final VoidCallback onRequestAi;

  const _CandidateBody({
    required this.candidate,
    required this.detail,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.canRequestAi,
    required this.aiLoading,
    required this.aiError,
    required this.onRequestAi,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeroImage(url: detail?.mainImageUrl ?? candidate.mainImageUrl ?? ''),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (canRequestAi) ...[
                  _AiAnalyzeButton(loading: aiLoading, onPressed: onRequestAi),
                  if (aiError != null) ...[
                    const SizedBox(height: 8),
                    Text(aiError!,
                        style: TextStyle(color: Colors.red[400], fontSize: 12)),
                  ],
                  const SizedBox(height: 16),
                ],
                if (detail != null) ...[
                  if ((detail!.category ?? '').isNotEmpty ||
                      (detail!.cookingMethod ?? '').isNotEmpty)
                    _Chips(labels: [
                      if ((detail!.category ?? '').isNotEmpty) detail!.category!,
                      if ((detail!.cookingMethod ?? '').isNotEmpty)
                        detail!.cookingMethod!,
                    ]),
                  const SizedBox(height: 16),
                ],
                if (loading)
                  const _LoadingSection()
                else if (error != null)
                  _ErrorSection(error: error!, onRetry: onRetry)
                else if (detail != null) ...[
                  _DetailNutrition(detail: detail!),
                  if ((detail!.ingredientsText ?? '').isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _Ingredients(
                      text: detail!.ingredientsText!,
                      menuName: candidate.name,
                    ),
                  ],
                  if ((detail!.healthTip ?? '').isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _SectionCard(
                      icon: Icons.health_and_safety_outlined,
                      title: '건강 팁',
                      content: detail!.healthTip!,
                      iconColor: Colors.green,
                    ),
                  ],
                  if (detail!.basePrice != null && detail!.basePrice! > 0) ...[
                    const SizedBox(height: 12),
                    _PriceRow(price: detail!.basePrice!),
                  ],
                ] else
                  _BasicNutrition(candidate: candidate),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 공통 위젯들 ──────────────────────────────────────────────

class _HeroImage extends StatelessWidget {
  final String url;
  const _HeroImage({required this.url});

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _placeholder();
    return Image.network(
      url,
      height: 220,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _placeholder(),
    );
  }

  Widget _placeholder() => Container(
        height: 220,
        color: AppTheme.primaryColor.withValues(alpha: 0.08),
        child: const Center(
          child: Icon(Icons.restaurant, size: 64, color: AppTheme.primaryColor),
        ),
      );
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  final Color? iconColor;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.content,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon,
                size: 16, color: iconColor ?? AppTheme.primaryColor),
            const SizedBox(width: 6),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14)),
          ]),
          const SizedBox(height: 8),
          Text(content,
              style: TextStyle(
                  fontSize: 13, color: Colors.grey[700], height: 1.5)),
        ],
      ),
    );
  }
}

class _NutritionSection extends StatelessWidget {
  final NutritionInfo info;
  const _NutritionSection({required this.info});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('열량', info.energy),
      ('단백질', info.protein),
      ('지방', info.fat),
      ('탄수화물', info.carbs),
      ('나트륨', info.sodium),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('영양 정보',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: items
              .map((e) => _NutritionChip(label: e.$1, value: e.$2))
              .toList(),
        ),
      ],
    );
  }
}

class _DetailNutrition extends StatelessWidget {
  final MenuDetail detail;
  const _DetailNutrition({required this.detail});

  @override
  Widget build(BuildContext context) {
    final items = <(String, String)>[
      if (detail.calories != null)
        ('열량', '${detail.calories!.toInt()} kcal'),
      if (detail.protein != null)
        ('단백질', '${detail.protein!.toStringAsFixed(1)}g'),
      if (detail.fat != null)
        ('지방', '${detail.fat!.toStringAsFixed(1)}g'),
      if (detail.carbs != null)
        ('탄수화물', '${detail.carbs!.toStringAsFixed(1)}g'),
      if (detail.sodium != null)
        ('나트륨', '${detail.sodium!.toStringAsFixed(0)}mg'),
    ];
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('영양 정보',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children:
              items.map((e) => _NutritionChip(label: e.$1, value: e.$2)).toList(),
        ),
      ],
    );
  }
}

class _BasicNutrition extends StatelessWidget {
  final MenuCandidate candidate;
  const _BasicNutrition({required this.candidate});

  @override
  Widget build(BuildContext context) {
    final items = <(String, String)>[
      if (candidate.calories != null)
        ('열량', '${candidate.calories!.toInt()} kcal'),
      if (candidate.protein != null)
        ('단백질', '${candidate.protein!.toStringAsFixed(1)}g'),
      if (candidate.sodium != null)
        ('나트륨', '${candidate.sodium!.toStringAsFixed(0)}mg'),
    ];
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('영양 정보',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children:
              items.map((e) => _NutritionChip(label: e.$1, value: e.$2)).toList(),
        ),
      ],
    );
  }
}

class _NutritionChip extends StatelessWidget {
  final String label;
  final String value;
  const _NutritionChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
                text: '$label ',
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            TextSpan(
                text: value,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
          ],
        ),
      ),
    );
  }
}

class _PersonalizedTip extends StatelessWidget {
  final String tip;
  const _PersonalizedTip({required this.tip});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [
            AppTheme.gradientStart.withValues(alpha: 0.15),
            AppTheme.gradientEnd.withValues(alpha: 0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (b) => AppTheme.aiGradient.createShader(b),
              child: const Icon(Icons.tips_and_updates_rounded, size: 18),
            ),
            const SizedBox(width: 6),
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (b) => AppTheme.aiGradient.createShader(b),
              child: const Text('나의 맞춤 레시피 변주',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ]),
          const SizedBox(height: 10),
          Text(tip,
              style: TextStyle(
                  fontSize: 13, color: Colors.grey[800], height: 1.6)),
        ],
      ),
    );
  }
}

class _RecipeSteps extends StatelessWidget {
  final List<RecipeStep> steps;
  const _RecipeSteps({required this.steps});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('조리 방법',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 10),
        ...steps.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                        color: AppTheme.primaryColor, shape: BoxShape.circle),
                    child: Center(
                      child: Text('${s.stepNo}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(s.content,
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[800],
                            height: 1.5)),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

class _MarketPricesTable extends StatelessWidget {
  final List<MarketPriceItem> prices;
  final num total;
  const _MarketPricesTable({required this.prices, required this.total});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('재료별 가격',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(children: [
                  Expanded(
                      flex: 3,
                      child: Text('재료',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600))),
                  Expanded(
                      flex: 2,
                      child: Text('사용량',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600))),
                  Expanded(
                      flex: 2,
                      child: Text('비용',
                          textAlign: TextAlign.end,
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600))),
                ]),
              ),
              const Divider(height: 1),
              ...prices.asMap().entries.map((entry) {
                final i = entry.key;
                final p = entry.value;
                return Column(children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Row(children: [
                      Expanded(
                          flex: 3,
                          child: Text(p.name,
                              style: const TextStyle(fontSize: 13))),
                      Expanded(
                          flex: 2,
                          child: Text(p.recipeAmount,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]))),
                      Expanded(
                          flex: 2,
                          child: Text('${p.calculatedCost.toInt()}원',
                              textAlign: TextAlign.end,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500))),
                    ]),
                  ),
                  if (i < prices.length - 1)
                    const Divider(height: 1, indent: 12, endIndent: 12),
                ]);
              }),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('예상 총 재료비',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('약 ${total.toInt()}원',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppTheme.primaryColor)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── AI 픽 재료 → 얇은 래퍼 ───────────────────────────────────
class _AiIngredientsCart extends StatelessWidget {
  final List<MarketPriceItem> prices;
  final String menuName;
  const _AiIngredientsCart({required this.prices, required this.menuName});

  @override
  Widget build(BuildContext context) {
    final items = prices
        .map((p) => '${p.name} ${p.recipeAmount}'.trim())
        .toList();
    return _CartSelector(items: items, menuName: menuName);
  }
}

// ── 후보 재료 → 얇은 래퍼 ────────────────────────────────────
class _Ingredients extends StatelessWidget {
  final String text;
  final String menuName;
  const _Ingredients({required this.text, required this.menuName});

  @override
  Widget build(BuildContext context) {
    final items = text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return _CartSelector(items: items, menuName: menuName);
  }
}

// ── 공통 재료 선택 + 장바구니 담기 위젯 ─────────────────────
class _CartSelector extends StatefulWidget {
  final List<String> items;
  final String menuName;
  const _CartSelector({required this.items, required this.menuName});

  @override
  State<_CartSelector> createState() => _CartSelectorState();
}

class _CartSelectorState extends State<_CartSelector> {
  final Set<int> _selected = {};

  bool get _allSelected => _selected.length == widget.items.length;

  void _toggleAll() {
    setState(() {
      if (_allSelected) {
        _selected.clear();
      } else {
        _selected.addAll(Iterable.generate(widget.items.length));
      }
    });
  }

  Future<void> _addToCart() async {
    final toAdd = _selected.map((i) => widget.items[i]).toList();
    await CartService.addItems(toAdd, menuName: widget.menuName);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${toAdd.length}개 재료를 장바구니에 담았습니다'),
        action: SnackBarAction(label: '확인', onPressed: () {}),
      ),
    );
    setState(() => _selected.clear());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('재료',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const Spacer(),
            TextButton(
              onPressed: _toggleAll,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                _allSelected ? '전체 해제' : '전체 선택',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ...widget.items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return CheckboxListTile(
            value: _selected.contains(i),
            onChanged: (v) => setState(() {
              if (v == true) {
                _selected.add(i);
              } else {
                _selected.remove(i);
              }
            }),
            title: Text(
              item,
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
            activeColor: AppTheme.primaryColor,
          );
        }),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: AnimatedOpacity(
            opacity: _selected.isEmpty ? 0.4 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: ElevatedButton.icon(
              onPressed: _selected.isEmpty ? null : _addToCart,
              icon: const Icon(Icons.shopping_cart_outlined, size: 18),
              label: Text(
                _selected.isEmpty
                    ? '재료를 선택하세요'
                    : '${_selected.length}개 장바구니에 담기',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                disabledForegroundColor: Colors.grey[500],
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  final int price;
  const _PriceRow({required this.price});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const Icon(Icons.attach_money, size: 16, color: AppTheme.primaryColor),
      const SizedBox(width: 4),
      Text('기본 가격 약 $price원',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
    ]);
  }
}

class _Chips extends StatelessWidget {
  final List<String> labels;
  const _Chips({required this.labels});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: labels
          .map((l) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(l,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500)),
              ))
          .toList(),
    );
  }
}

class _LoadingSection extends StatelessWidget {
  const _LoadingSection();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: CircularProgressIndicator(
            color: AppTheme.primaryColor, strokeWidth: 2.5),
      ),
    );
  }
}

class _ErrorSection extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorSection({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(error,
            style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        const SizedBox(height: 8),
        TextButton(
          onPressed: onRetry,
          child: const Text('다시 시도'),
        ),
      ],
    );
  }
}

// ── 이 메뉴 AI 분석 받기 버튼 ─────────────────────────────────
class _AiAnalyzeButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onPressed;
  const _AiAnalyzeButton({required this.loading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: AppTheme.aiGradient,
        borderRadius: BorderRadius.circular(26),
      ),
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: const StadiumBorder(),
        ),
        child: loading
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.2)),
                  SizedBox(width: 10),
                  Text('AI가 이 메뉴를 분석 중...',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('이 메뉴 AI 분석 받기',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                ],
              ),
      ),
    );
  }
}
