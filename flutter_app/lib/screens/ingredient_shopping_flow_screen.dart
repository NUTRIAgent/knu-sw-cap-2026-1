import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class IngredientShoppingItem {
  final String name;
  final String? note;

  const IngredientShoppingItem({
    required this.name,
    this.note,
  });
}

class IngredientShoppingFlowScreen extends StatefulWidget {
  final String menuName;
  final List<IngredientShoppingItem> ingredients;

  const IngredientShoppingFlowScreen({
    super.key,
    required this.menuName,
    required this.ingredients,
  });

  @override
  State<IngredientShoppingFlowScreen> createState() => _IngredientShoppingFlowScreenState();
}

class _IngredientShoppingFlowScreenState extends State<IngredientShoppingFlowScreen> {
  late final WebViewController _controller;
  int _index = 0;
  bool _isPageLoading = true;
  bool _showBlockedFallback = false;
  Uri? _lastCommittedUrl;

  // 네이버 계열 서비스에서 임베디드 웹뷰를 차단하는 경우가 있어,
  // UA를 모바일 크롬처럼 맞춰 우회 가능성을 높입니다(불안정할 수 있음).
  static const String _mobileChromeUserAgent =
      'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) '
      'AppleWebKit/605.1.15 (KHTML, like Gecko) '
      'CriOS/124.0.0.0 Mobile/15E148 Safari/604.1';

  IngredientShoppingItem get _current => widget.ingredients[_index];

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setUserAgent(_mobileChromeUserAgent)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() => _isPageLoading = true);
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() => _isPageLoading = false);
            _detectBlockedPage();
          },
          onUrlChange: (change) {
            _lastCommittedUrl = change.url != null ? Uri.tryParse(change.url!) : null;
          },
        ),
      );

    _loadCurrentIngredient();
  }

  Uri _naverShoppingSearchUrl(String query) {
    // 네이버쇼핑 검색 URL (모바일/앱 환경에서도 동작 확인용)
    final encoded = Uri.encodeQueryComponent(query);
    return Uri.parse('https://search.shopping.naver.com/search/all?query=$encoded');
  }

  Future<void> _loadCurrentIngredient() async {
    final query = '${widget.menuName} ${_current.name}'.trim();
    final url = _naverShoppingSearchUrl(query);
    setState(() {
      _showBlockedFallback = false;
      _lastCommittedUrl = url;
    });
    await _controller.loadRequest(url);
  }

  Future<void> _detectBlockedPage() async {
    // 네이버가 WebView/임베디드 접근을 차단하는 경우가 있어, 대표 문구를 감지해 폴백 UI를 노출합니다.
    // (사이트 문구가 바뀔 수 있으므로 100% 보장은 아님)
    try {
      final html = await _controller.runJavaScriptReturningResult(
        'document.documentElement.innerText || "";',
      );

      final text = (html is String) ? html : html.toString();
      final normalized = text.replaceAll('\\n', ' ').toLowerCase();

      final blockedSignals = <String>[
        '부적절한 접근',
        '비정상적인 접근',
        '접근이 제한',
        'blocked',
        'access denied',
      ];

      final isBlocked = blockedSignals.any((s) => normalized.contains(s.toLowerCase()));
      if (!mounted) return;
      if (isBlocked) {
        setState(() => _showBlockedFallback = true);
      }
    } catch (_) {
      // 감지 실패 시엔 조용히 무시
    }
  }

  Future<void> _openExternally() async {
    final url = _lastCommittedUrl ?? _naverShoppingSearchUrl('${widget.menuName} ${_current.name}'.trim());
    final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('외부 브라우저를 열 수 없어요.')),
      );
    }
  }

  void _next({required bool skipped}) {
    final label = skipped ? '스킵' : '완료';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_current.name} $label')),
    );

    if (_index >= widget.ingredients.length - 1) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _index += 1;
      _isPageLoading = true;
    });
    _loadCurrentIngredient();
  }

  Future<void> _reload() async {
    await _controller.reload();
  }

  Future<void> _openCartHint() async {
    // 네이버 장바구니는 로그인/세션/앱딥링크 등 환경 변수가 많아서
    // 우선은 쇼핑 검색 -> 사용자 직접 담기 UX를 유도.
    // 필요 시 추후 네이버페이/장바구니 URL로 전환 가능.
    final cartUrl = Uri.parse('https://shopping.naver.com/cart');
    await _controller.loadRequest(cartUrl);
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.ingredients.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('재료 구매하기 (${_index + 1}/$total)'),
        actions: [
          IconButton(
            tooltip: '새로고침',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: '장바구니(시도)',
            onPressed: _openCartHint,
            icon: const Icon(Icons.shopping_cart_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _TopInfoBar(
              menuName: widget.menuName,
              ingredientName: _current.name,
              note: _current.note,
              stepText: '${_index + 1} / $total',
            ),
            Expanded(
              child: Stack(
                children: [
                  WebViewWidget(controller: _controller),
                  if (_showBlockedFallback)
                    Positioned.fill(
                      child: ColoredBox(
                        color: Colors.white,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Icon(Icons.warning_amber_rounded, size: 42),
                                const SizedBox(height: 12),
                                const Text(
                                  '네이버쇼핑이 앱 내 웹뷰 접근을 제한했어요.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '외부 브라우저(또는 네이버 앱)로 열면 계속 진행할 수 있어요.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey.shade700, height: 1.4),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _openExternally,
                                  icon: const Icon(Icons.open_in_new),
                                  label: const Text('외부로 열기'),
                                ),
                                const SizedBox(height: 10),
                                OutlinedButton(
                                  onPressed: () => _next(skipped: true),
                                  child: const Text('이번 재료는 스킵하고 다음으로'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (_isPageLoading)
                    const Positioned.fill(
                      child: ColoredBox(
                        color: Colors.white,
                        child: Center(
                          child: SizedBox(
                            height: 28,
                            width: 28,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _next(skipped: true),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text('다음(스킵)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _next(skipped: false),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text('담았어요(다음)'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopInfoBar extends StatelessWidget {
  final String menuName;
  final String ingredientName;
  final String? note;
  final String stepText;

  const _TopInfoBar({
    required this.menuName,
    required this.ingredientName,
    required this.note,
    required this.stepText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$menuName • $ingredientName',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  stepText,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (note != null && note!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              note!,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12, height: 1.3),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
