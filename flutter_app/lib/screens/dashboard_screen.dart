import 'package:flutter/material.dart';
import 'package:flutter_app/models/recommendation_models.dart';
import 'package:flutter_app/models/user_profile_models.dart';
import 'package:flutter_app/services/recommendation_service.dart';
import 'package:flutter_app/services/token_storage.dart';
import 'package:flutter_app/services/user_profile_service.dart';
import 'recommendation_screen.dart';
import 'package:flutter_app/theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = false;

  static const Map<String, String> _fitnessGoalMap = {
    'DIET': '다이어트',
    'MUSCLE_GAIN': '근력운동',
    'MAINTAIN': '체중유지',
    'GENERAL': '일반식단',
  };

  Future<void> _requestRecommendation() async {
    setState(() => _isLoading = true);

    try {
      final profileResp = await UserProfileService.getProfile();
      if (!profileResp.success || profileResp.data == null) {
        _showError('프로필 정보를 불러오지 못했습니다.\n마이페이지에서 프로필을 먼저 입력해주세요.');
        return;
      }
      final UserProfileData profile = profileResp.data!;
      final jwt = await TokenStorage.getAccessToken();

      // 후보 목록 먼저 가져와서 화면에 즉시 표시하고, 동일한 ID를 AI agent에 전달
      final candidates = await RecommendationService.fetchCandidates(jwt);

      final request = RecommendationRequest(
        heightCm: profile.height ?? 170.0,
        weightKg: profile.weight ?? 65.0,
        location: '서울', // TODO: 사용자 위치 필드 추가 시 교체
        budget: (profile.mealBudget ?? 8000).toDouble(),
        fitnessGoal: _fitnessGoalMap[profile.fitnessGoal] ?? '일반식단',
        healthConditions: const [], // TODO: health_conditions 필드 추가 시 연결
        allergies: profile.allergies,
        preferences: profile.foodPreferences,
        jwtToken: jwt,
        candidateMenuIds: candidates.map((c) => c.id).toList(),
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecommendationScreen(
            candidates: candidates,
            request: request,
          ),
        ),
      );
    } catch (e) {
      _showError('추천 중 오류가 발생했습니다.\n$e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('오류', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (Rect bounds) => AppTheme.aiGradient.createShader(bounds),
              child: const Text(
                'NUTRI Agent',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(height: 24),

            // 날씨 및 브리핑 카드
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.wb_sunny, color: Colors.orangeAccent, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        '서울시 맑음, 22°C',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 30, thickness: 1, color: Color(0xFFEEEEEE)),
                  Text(
                    '오늘의 브리핑',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '상쾌한 날씨입니다. 매일 하시는 5km 러닝 후 근손실 방지를 위해 오늘은 단백질이 풍부하고 예산에 맞는 메뉴를 추천해 드릴 준비가 되었습니다.',
                    style: TextStyle(fontSize: 15, color: Colors.grey[700], height: 1.5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 예산 카드
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.account_balance_wallet,
                          color: Theme.of(context).primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '끼니당 목표 예산',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '8,000 원',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.edit_outlined, color: Colors.grey),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // 메뉴 추천 버튼
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: _isLoading ? null : AppTheme.aiGradient,
                color: _isLoading ? Colors.grey[300] : null,
                borderRadius: BorderRadius.circular(30),
                boxShadow: _isLoading
                    ? null
                    : [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _requestRecommendation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: const StadiumBorder(),
                  padding: EdgeInsets.zero,
                ),
                child: _isLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'AI가 메뉴를 분석 중...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.restaurant_menu, size: 24, color: Colors.white),
                          SizedBox(width: 12),
                          Text(
                            '맞춤 메뉴 추천 받기',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
