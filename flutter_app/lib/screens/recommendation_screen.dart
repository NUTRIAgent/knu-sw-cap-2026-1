import 'package:flutter/material.dart';
import 'package:flutter_app/theme.dart';

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({super.key});

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  int _rating = 0;
  final TextEditingController _feedbackController = TextEditingController();

  final List<Map<String, dynamic>> _recommendedMenus = [
    {
      "id": 15,
      "name": "연어 포케",
      "price": 9500,
      "calories": 550,
      "reason": "예산 범위 내이며, 러닝 후 근손실 방지를 위한 고단백 메뉴입니다."
    },
    {
      "id": 42,
      "name": "닭가슴살 샐러드와 호밀빵",
      "price": 8000,
      "calories": 480,
      "reason": "현재 물가가 저렴한 양상추를 듬뿍 활용한 가성비 식단입니다."
    },
    {
      "id": 8,
      "name": "소고기 버섯 덮밥",
      "price": 9000,
      "calories": 620,
      "reason": "철분 보충에 좋으며 매운맛을 선호하지 않는 취향을 반영했습니다."
    }
  ];

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  // 메뉴 상세 팝업
  void _showMenuDetailDialog(Map<String, dynamic> menu) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // 💡 팝업 모서리 20px 라운딩
          title: Text(menu['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('💰 가격: ${menu['price']}원', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Text('🔥 칼로리: ${menu['calories']} kcal', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              const Text('🤖 AI 추천 사유:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(menu['reason'], style: TextStyle(color: Colors.grey[700], height: 1.4, fontSize: 15)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text('닫기', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))
            ),
            // 💡 선택 버튼에 그라데이션 캡슐 디자인 적용
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.aiGradient,
                borderRadius: BorderRadius.circular(30),
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${menu['name']} 선택 완료!')));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('선택', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        );
      },
    );
  }

  // 피드백 입력창 (바텀 시트)
  void _showFeedbackBottomSheet() {
    // 시트를 열 때 별점 초기화
    _rating = 0;
    _feedbackController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder( 
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 24, right: 24, top: 32,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24, 
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)), // 💡 시트 상단 부드러운 라운딩
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '이번 추천은 어떠셨나요?',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  
                  // 별점 선택
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 48, // 별 크기 약간 증가
                          color: index < _rating ? Colors.amber : Colors.grey[300],
                        ),
                        onPressed: () {
                          setModalState(() => _rating = index + 1);
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  
                  // 💡 피드백 텍스트 필드 디자인 적용 (16px 라운딩)
                  TextField(
                    controller: _feedbackController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: '아쉬운 점이 있다면 알려주세요...',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // 💡 피드백 제출 버튼 그라데이션 적용
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: AppTheme.aiGradient,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        // ignore: avoid_print
                        print('피드백: $_rating점, ${_feedbackController.text}');
                        Navigator.pop(context); 
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('소중한 피드백 감사합니다!')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: const StadiumBorder(),
                      ),
                      child: const Text('피드백 제출하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('맞춤 메뉴 추천', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. 추천 메뉴 리스트
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20.0),
                itemCount: _recommendedMenus.length,
                itemBuilder: (context, index) {
                  final menu = _recommendedMenus[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    // 💡 글로벌 테마가 적용되지만 혹시 몰라 명시적 처리
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20), // 💡 클릭 시 물결 효과 라운딩 통일
                      onTap: () => _showMenuDetailDialog(menu),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          children: [
                            Container(
                              width: 56, height: 56,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1), // 💡 AppTheme 색상 적용
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.restaurant, color: AppTheme.primaryColor, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(menu['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text('${menu['price']}원', style: TextStyle(color: Colors.grey[600], fontSize: 15)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // 2. 하단 고정 버튼 (피드백)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: OutlinedButton(
                onPressed: _showFeedbackBottomSheet, 
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.primaryColor, width: 1.5), // 💡 AppTheme 색상
                  minimumSize: const Size(double.infinity, 56),
                  shape: const StadiumBorder(), // 💡 캡슐 모양으로 통일
                ),
                child: const Text(
                  '메뉴 추천 결과 피드백 남기기',
                  style: TextStyle(color: AppTheme.primaryColor, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}