import 'package:flutter/material.dart';
import 'package:flutter_app/models/recommendation_models.dart';
import 'package:flutter_app/models/user_profile_models.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadWeather();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadWeather();
    }
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
    if (w == null) return '날씨 정보를 불러오는 중입니다. 오늘도 건강한 식사를 추천해 드릴게요.';
    final temp = w.temperature;
    final pty = w.precipitationType;

    if (pty == 1 || pty == 5) return '비가 오는 날이에요. 따뜻한 국물 요리로 몸을 따뜻하게 해보세요.';
    if (pty == 2 || pty == 6) return '비와 눈이 섞여 내려요. 따뜻한 식사로 체온을 유지해보세요.';
    if (pty == 3 || pty == 7) return '눈이 내리는 날이에요. 따뜻한 국물 요리를 추천해 드릴게요.';
    if (temp >= 30) return '무더운 날씨입니다. 수분 보충에 좋은 시원한 음식을 추천해 드릴게요.';
    if (temp >= 23) return '따뜻하고 쾌적한 날씨입니다. 맛있는 한 끼를 추천해 드릴게요.';
    if (temp >= 10) return '선선한 날씨네요. 오늘 영양 균형 잡힌 메뉴를 추천해 드릴게요.';
    return '쌀쌀한 날씨입니다. 따뜻하고 든든한 메뉴를 추천해 드릴게요.';
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
                      Icon(
                        _weatherIcon(_weather),
                        color: _weatherIconColor(_weather),
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _weatherText(_weather, _isWeatherLoading, _weatherError),
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
                    _briefingText(_weather),
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
