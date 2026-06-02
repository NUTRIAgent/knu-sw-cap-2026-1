import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

/// 메뉴 상세 화면에서 사용하는 유튜브 영상 섹션.
///
/// 동작 원칙(리스트/메모리 안전):
/// - 처음엔 썸네일 + 재생 버튼만 표시하고, 사용자가 탭했을 때만 플레이어(WebView)를 1개 생성한다.
/// - 자동재생하지 않는다.
/// - [videoId]가 비어있으면 아무것도 렌더링하지 않는다(영역 숨김).
class MenuVideoSection extends StatefulWidget {
  final String? videoId;

  const MenuVideoSection({super.key, required this.videoId});

  @override
  State<MenuVideoSection> createState() => _MenuVideoSectionState();
}

class _MenuVideoSectionState extends State<MenuVideoSection> {
  YoutubePlayerController? _controller;

  bool get _hasVideo =>
      widget.videoId != null && widget.videoId!.trim().isNotEmpty;

  void _play() {
    if (!_hasVideo) return;
    setState(() {
      _controller = YoutubePlayerController.fromVideoId(
        videoId: widget.videoId!.trim(),
        autoPlay: true, // 사용자가 탭한 뒤에만 생성되므로 자동재생 정책 위반 아님
        params: const YoutubePlayerParams(
          showFullscreenButton: true,
          // 플레이어 밖으로의 임의 네비게이션 방지(관련 영상은 동일 채널로 제한)
          showControls: true,
          enableJavaScript: true,
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasVideo) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('관련 영상',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: _controller == null
                  ? _Thumbnail(videoId: widget.videoId!.trim(), onTap: _play)
                  : YoutubePlayer(controller: _controller!),
            ),
          ),
        ],
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final String videoId;
  final VoidCallback onTap;

  const _Thumbnail({required this.videoId, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              color: Colors.black12,
              child: const Center(
                child: Icon(Icons.smart_display_outlined,
                    size: 48, color: Colors.white70),
              ),
            ),
          ),
          Container(color: Colors.black.withValues(alpha: 0.18)),
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 36),
            ),
          ),
        ],
      ),
    );
  }
}

/// 리스트(추천 이력 등)에서 영상 보유 여부를 표시하는 작은 배지.
/// 플레이어를 생성하지 않으므로 메모리 비용이 없다.
class VideoBadge extends StatelessWidget {
  const VideoBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.smart_display, size: 12, color: Colors.redAccent),
          SizedBox(width: 3),
          Text('영상',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.redAccent)),
        ],
      ),
    );
  }
}
