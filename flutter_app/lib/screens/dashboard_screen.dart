import 'package:flutter/material.dart';
import 'package:flutter_app/models/market_price_models.dart';
import 'package:flutter_app/models/recommendation_models.dart';
import 'package:flutter_app/models/user_profile_models.dart';
import 'package:flutter_app/services/market_price_service.dart';
import 'package:flutter_app/services/recommendation_service.dart';
import 'package:flutter_app/services/token_storage.dart';
import 'package:flutter_app/services/user_profile_service.dart';
import 'package:flutter_app/services/weather_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'recommendation_screen.dart';
import 'package:flutter_app/theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  bool _isLoading = false;
  WeatherData? _weather;
  bool _isWeatherLoading = true;
  String? _weatherError;
  String _locationName = '현재위치';
  static String? _aiBriefing;

  // ── 정보 카드 공통 ────────────────────────────────
  final PageController _infoCardController = PageController();
  int _infoCardIndex = 0;

  // ── 카드 1: 저렴한 재료 ───────────────────────────
  List<IngredientPriceModel> _priceDrops = [];
  bool _isPriceLoading = true;

  // ── 카드 2: AI 픽 이력 ────────────────────────────
  List<AiPickItem> _aiPicks = [];
  bool _isAiPickLoading = true;

  // ── 카드 3: 프로필 요약 ───────────────────────────
  UserProfileData? _profileData;
  bool _isProfileLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadWeather();
    _loadPriceDrops();
    _loadAiPicks();
    _loadDashboardProfile();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _infoCardController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // if (state == AppLifecycleState.resumed) {
    //   _loadWeather();
    // }
  }

  Future<void> _loadWeather() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _weatherError = '위치 서비스가 꺼져 있습니다';
          _isWeatherLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _weatherError = '위치 권한이 거부되었습니다';
            _isWeatherLoading = false;
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _weatherError = '위치 권한이 영구 거부되었습니다\n설정에서 허용해주세요';
          _isWeatherLoading = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final results = await Future.wait([
        WeatherService.fetchWeather(position.latitude, position.longitude),
        placemarkFromCoordinates(position.latitude, position.longitude),
      ]);

      final weather = results[0] as WeatherData;
      final placemarks = results[1] as List<Placemark>;
      final place = placemarks.isNotEmpty ? placemarks.first : null;
      final locationName = place?.locality?.isNotEmpty == true
          ? place!.locality!
          : place?.subAdministrativeArea?.isNotEmpty == true
          ? place!.subAdministrativeArea!
          : place?.administrativeArea?.isNotEmpty == true
          ? place!.administrativeArea!
          : '현재위치';

      if (mounted) {
        setState(() {
          _weather = weather;
          _locationName = locationName;
          _isWeatherLoading = false;
        });

        // AI 브리핑 멘트 (실패해도 무시)
        final briefing = await WeatherService.fetchBriefing(
          weather,
          locationName: locationName,
        );
        if (mounted && briefing != null) {
          setState(() => _aiBriefing = briefing);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _weatherError = '날씨 정보를 불러올 수 없습니다';
          _isWeatherLoading = false;
        });
      }
    }
  }

  Future<void> _loadPriceDrops() async {
    try {
      final prices = await MarketPriceService.getAllPrices();
      final drops = prices
          .where((p) => p.dayChangeRate != null && p.dayChangeRate! < 0)
          .toList()
        ..sort((a, b) => a.dayChangeRate!.compareTo(b.dayChangeRate!));
      if (mounted) {
        setState(() {
          _priceDrops = drops.take(3).toList();
          _isPriceLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isPriceLoading = false);
    }
  }

  Future<void> _loadAiPicks() async {
    try {
      final jwt = await TokenStorage.getAccessToken();
      final items = await RecommendationService.fetchMyAiPicks(jwt);
      if (mounted) {
        setState(() {
          _aiPicks = items.take(3).toList();
          _isAiPickLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isAiPickLoading = false);
    }
  }

  Future<void> _loadDashboardProfile() async {
    try {
      final result = await UserProfileService.getProfile();
      if (mounted) {
        setState(() {
          _profileData = (result.success) ? result.data : null;
          _isProfileLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isProfileLoading = false);
    }
  }

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
        location: '현재위치',
        budget: (profile.mealBudget ?? 8000).toDouble(),
        fitnessGoal: _fitnessGoalMap[profile.fitnessGoal] ?? '일반식단',
        healthConditions: profile.healthConditions,
        allergies: profile.allergies,
        preferences: profile.foodPreferences,
        jwtToken: jwt,
        candidateMenuIds: candidates.map((c) => c.id).toList(),
        weatherTemp: _weather?.temperature, // ← 추가
        weatherCondition: _weather?.precipitationName, // ← 추가
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              RecommendationScreen(candidates: candidates, request: request),
        ),
      );
    } catch (e) {
      _showError('추천 중 오류가 발생했습니다.\n$e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _weatherText(WeatherData? w, bool loading, String? error) {
    if (loading) return '날씨 불러오는 중...';
    if (error != null) return '날씨 정보 없음';
    if (w == null) return '날씨 정보 없음';
    return '$_locationName ${w.precipitationName}, ${w.temperature.toStringAsFixed(1)}°C';
  }

  IconData _weatherIcon(WeatherData? w) {
    if (w == null) return Icons.cloud_off;
    return switch (w.precipitationType) {
      1 || 5 => Icons.umbrella,
      2 || 6 => Icons.grain,
      3 || 7 => Icons.ac_unit,
      _ => w.temperature >= 28 ? Icons.wb_sunny : Icons.wb_cloudy,
    };
  }

  Color _weatherIconColor(WeatherData? w) {
    if (w == null) return Colors.grey;
    return switch (w.precipitationType) {
      1 || 5 => Colors.blueAccent,
      2 || 6 => Colors.blueGrey,
      3 || 7 => Colors.lightBlue,
      _ => Colors.orangeAccent,
    };
  }

  String _briefingText(WeatherData? w) {
    if (_aiBriefing != null) return _aiBriefing!;
    return 'ai가 날씨를 브리핑 중입니다...';
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

  // ── 정보 카드 영역 ────────────────────────────────

  Widget _buildInfoCards() {
    return Column(
      children: [
        // PageView: 저렴한 재료 ↔ AI 픽 이력 (2장)
        SizedBox(
          height: 175,
          child: PageView(
            controller: _infoCardController,
            onPageChanged: (i) => setState(() => _infoCardIndex = i),
            children: [
              _buildPriceDropCard(),
              _buildAiPickCard(),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(2, (i) {
            final active = _infoCardIndex == i;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active ? AppTheme.primaryColor : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        // 프로필 카드: 항상 표시 (고정 높이로 Expanded 제약 보장)
        SizedBox(height: 115, child: _buildProfileCard()),
      ],
    );
  }

  Widget _buildInfoCardShell({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget body,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
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
              Icon(icon, size: 15, color: iconColor),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(child: body),
        ],
      ),
    );
  }

  // ── 카드 1: 저렴한 재료 ───────────────────────────

  Widget _buildPriceDropCard() {
    return _buildInfoCardShell(
      icon: Icons.trending_down_rounded,
      iconColor: Colors.green.shade600,
      title: '오늘의 저렴한 재료',
      body: _isPriceLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _priceDrops.isEmpty
              ? Center(
                  child: Text(
                    '가격 하락 재료 데이터 없음',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _priceDrops.map(_buildPriceDropRow).toList(),
                ),
    );
  }

  Widget _buildPriceDropRow(IngredientPriceModel p) {
    final rate = p.dayChangeRate!;
    return Row(
      children: [
        Expanded(
          child: Text(
            p.ingredientName,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          p.displayPrice,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
        const SizedBox(width: 8),
        Text(
          '${rate.toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade600,
          ),
        ),
      ],
    );
  }

  // ── 카드 2: AI 픽 이력 ────────────────────────────

  Widget _buildAiPickCard() {
    return _buildInfoCardShell(
      icon: Icons.auto_awesome_rounded,
      iconColor: AppTheme.primaryColor,
      title: 'AI 픽 이력',
      body: _isAiPickLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _aiPicks.isEmpty
              ? Center(
                  child: Text(
                    '아직 AI 픽 이력이 없어요',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _aiPicks.map(_buildAiPickRow).toList(),
                ),
    );
  }

  Widget _buildAiPickRow(AiPickItem item) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: item.menuImageUrl != null && item.menuImageUrl!.isNotEmpty
              ? Image.network(
                  item.menuImageUrl!,
                  width: 26,
                  height: 26,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, st) => _miniMenuIcon(),
                )
              : _miniMenuIcon(),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            item.menuName,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (item.starRating != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, size: 13, color: Colors.amber),
              const SizedBox(width: 2),
              Text(
                '${item.starRating}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
      ],
    );
  }

  Widget _miniMenuIcon() => Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(Icons.restaurant, color: Colors.grey.shade400, size: 14),
      );

  // ── 카드 3: 프로필 요약 ───────────────────────────

  Widget _buildProfileCard() {
    return _buildInfoCardShell(
      icon: Icons.person_outline_rounded,
      iconColor: AppTheme.primaryColor,
      title: '내 식단 프로필',
      body: _isProfileLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _profileData == null
              ? Center(
                  child: Text(
                    '프로필을 불러올 수 없습니다',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildProfileKVRow(
                      '식단 목표',
                      _fitnessGoalMap[_profileData!.fitnessGoal] ?? '일반식단',
                    ),
                    _buildProfileKVRow(
                      '매운맛',
                      '${_profileData!.spicyPreference ?? 3}단계',
                    ),
                    _buildProfileAllergyRow(_profileData!.allergies),
                  ],
                ),
    );
  }

  Widget _buildProfileKVRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildProfileAllergyRow(List<String> allergies) {
    return Row(
      children: [
        Text(
          '알레르기',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        const Spacer(),
        if (allergies.isEmpty)
          const Text(
            '없음',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          )
        else
          Row(
            children: allergies.take(3).map((a) => Container(
              margin: const EdgeInsets.only(left: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Text(
                a,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )).toList(),
          ),
      ],
    );
  }

  // ── 빌드 ─────────────────────────────────────────

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
              shaderCallback: (Rect bounds) =>
                  AppTheme.aiGradient.createShader(bounds),
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
                      Icon(
                        _weatherIcon(_weather),
                        color: _weatherIconColor(_weather),
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _weatherText(
                          _weather,
                          _isWeatherLoading,
                          _weatherError,
                        ),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const Divider(
                    height: 30,
                    thickness: 1,
                    color: Color(0xFFEEEEEE),
                  ),
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
                    _briefingText(_weather),
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 정보 카드 (스와이프)
            _buildInfoCards(),

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
                          Icon(
                            Icons.restaurant_menu,
                            size: 24,
                            color: Colors.white,
                          ),
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
