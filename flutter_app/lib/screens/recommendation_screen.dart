import 'package:flutter/material.dart';

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

  // 메뉴 상세 팝업 (기존과 동일)
  void _showMenuDetailDialog(Map<String, dynamic> menu) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(menu['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('💰 가격: ${menu['price']}원'),
              const SizedBox(height: 8),
              Text('🔥 칼로리: ${menu['calories']} kcal'),
              const SizedBox(height: 16),
              const Text('🤖 AI 추천 사유:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(menu['reason'], style: TextStyle(color: Colors.grey[700], height: 1.4)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('닫기')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${menu['name']} 선택 완료!')));
              },
              child: const Text('선택'),
            ),
          ],
        );
      },
    );
  }

  // 💡 핵심: 피드백 입력창을 바텀 시트로 띄우는 함수
  void _showFeedbackBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 키보드가 올라올 때 시트도 같이 올라가게 설정
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder( // 시트 안에서 별점 상태를 변경하기 위해 필요
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 24, right: 24, top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24, // 키보드 높이만큼 여백 추가
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '이번 추천은 어떠셨나요?',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  // 별점 선택
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 40,
                          color: index < _rating ? Colors.amber : Colors.grey[300],
                        ),
                        onPressed: () {
                          setModalState(() => _rating = index + 1);
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  
                  // 피드백 텍스트
                  TextField(
                    controller: _feedbackController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: '아쉬운 점이 있다면 알려주세요...',
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  ElevatedButton(
                    onPressed: () {
                      print('피드백: $_rating점, ${_feedbackController.text}');
                      Navigator.pop(context); // 시트 닫기
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('소중한 피드백 감사합니다!')),
                      );
                    },
                    child: const Text('피드백 제출하기'),
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
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. 추천 메뉴 리스트 (화면 대부분을 차지)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _recommendedMenus.length,
                itemBuilder: (context, index) {
                  final menu = _recommendedMenus[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _showMenuDetailDialog(menu),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              width: 50, height: 50,
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.restaurant, color: Theme.of(context).primaryColor),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(menu['name'], style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                                  Text('${menu['price']}원', style: TextStyle(color: Colors.grey[600])),
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
            
            // 2. 하단 고정 버튼 (피드백을 필요할 때만 띄우기 위함)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: OutlinedButton(
                onPressed: _showFeedbackBottomSheet, // 버튼 클릭 시 바텀 시트 호출
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Theme.of(context).primaryColor),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  '메뉴 추천 결과 피드백 남기기',
                  style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}