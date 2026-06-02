import 'package:flutter/material.dart';
import 'package:flutter_app/models/recommendation_models.dart';
import 'package:flutter_app/models/user_profile_models.dart';
import 'package:flutter_app/notifiers.dart';
import 'package:flutter_app/services/recommendation_service.dart';
import 'package:flutter_app/services/user_profile_service.dart';
import 'package:flutter_app/screens/price_alert_screen.dart';
import 'package:flutter_app/screens/recommendation_history_screen.dart';
import 'package:flutter_app/services/token_storage.dart';
import 'package:flutter_app/theme.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // ── 프로필 탭 상태 ──────────────────────────────
  final _formKey = GlobalKey<FormState>();
  bool _isEditMode = false;
  bool _isLoading = false;

  final TextEditingController _nicknameController =
      TextEditingController(text: "김철수");
  String? _selectedGender = '남성';

  final TextEditingController _heightController =
      TextEditingController(text: "175");
  final TextEditingController _weightController =
      TextEditingController(text: "70");
  final TextEditingController _muscleController =
      TextEditingController(text: "35");
  final TextEditingController _fatController =
      TextEditingController(text: "15");
  final TextEditingController _bmrController =
      TextEditingController(text: "1600");
  final TextEditingController _inbodyScoreController =
      TextEditingController(text: "80");
  final TextEditingController _budgetController =
      TextEditingController(text: "8000");
  final TextEditingController _customNoteController = TextEditingController();

  String _selectedVegType = 'NONE';
  double _spicyLevel = 3;
  String _selectedFitnessGoal = 'GENERAL';
  Set<String> _selectedFoodPreferences = {};
  Set<String> _selectedHealthConditions = {};
  Set<String> _selectedAllergies = {'우유', '밀가루'};

  late String _bkNickname;
  late String? _bkGender;
  late String _bkHeight, _bkWeight, _bkMuscle, _bkFat, _bkBmr, _bkScore,
      _bkBudget;
  late String _bkVegType;
  late double _bkSpicy;
  late String _bkFitnessGoal;
  late Set<String> _bkFoodPreferences;
  late Set<String> _bkAllergies;
  late Set<String> _bkHealthConditions;
  late String _bkCustomNote;

  // ── 피드백 탭 상태 ──────────────────────────────
  List<FeedbackHistoryItem> _feedbackItems = [];
  List<AiPickItem> _aiPickFeedbackItems = [];
  bool _feedbackLoading = false;
  bool _feedbackPending = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _feedbackTab = 0; // 0=좋아요, 1=싫어요, 2=AI피드백

  // ── 옵션 상수 ────────────────────────────────────
  final List<String> _healthConditionOptions = [
    '고혈압', '당뇨', '고지혈증', '비만', '신장질환', '간질환', '심장질환', '갑상선질환',
  ];
  final List<String> _allergyOptions = [
    '땅콩', '갑각류', '대두', '우유', '밀가루', '계란', '견과류', '생선',
  ];
  final Map<String, String> _vegOptions = {
    'NONE': '해당 없음',
    'VEGAN': '비건 (완전 채식)',
    'LACTO': '락토 (우유 허용)',
    'OVO': '오보 (계란 허용)',
    'PESCO': '페스코 (해산물 허용)',
  };
  final Map<String, String> _fitnessGoalOptions = {
    'GENERAL': '일반식단',
    'DIET': '다이어트',
    'MUSCLE_GAIN': '근력증가',
    'MAINTAIN': '체중유지',
  };
  final List<String> _foodPreferenceOptions = [
    '한식', '양식', '일식', '중식', '분식', '동남아식',
    '매운맛', '담백한맛', '달콤한맛', '고단백', '저칼로리',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
        // 피드백 탭으로 전환될 때 최신 데이터 로드
        if (_tabController.index == 1) _loadFeedbacks();
      }
    });
    feedbackRefreshNotifier.addListener(_loadFeedbacks);
    _loadProfile();
    _loadBasicUserInfoFromLocal();
    _loadFeedbacks();
  }

  @override
  void dispose() {
    feedbackRefreshNotifier.removeListener(_loadFeedbacks);
    _tabController.dispose();
    _nicknameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _muscleController.dispose();
    _fatController.dispose();
    _bmrController.dispose();
    _inbodyScoreController.dispose();
    _budgetController.dispose();
    _customNoteController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── 프로필 로드 ──────────────────────────────────

  Future<void> _loadBasicUserInfoFromLocal() async {
    try {
      final nickname = await TokenStorage.getUserNickname();
      final gender = await TokenStorage.getGender();
      if (!mounted) return;
      setState(() {
        if (nickname != null && nickname.isNotEmpty) {
          _nicknameController.text = nickname;
        }
        final normalizedGender = _normalizeGender(gender);
        if (normalizedGender != null) _selectedGender = normalizedGender;
      });
    } catch (_) {}
  }

  String? _normalizeGender(String? raw) {
    if (raw == null) return null;
    final v = raw.trim();
    if (v == '남성' || v == 'M' || v.toLowerCase() == 'male') return '남성';
    if (v == '여성' || v == 'F' || v.toLowerCase() == 'female') return '여성';
    if (v == '남자') return '남성';
    if (v == '여자') return '여성';
    return null;
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final result = await UserProfileService.getProfile();
      if (!mounted) return;
      if (!result.success || result.data == null) return;
      _applyProfileToForm(result.data!);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyProfileToForm(UserProfileData data) {
    if (data.nickname != null && data.nickname!.isNotEmpty) {
      _nicknameController.text = data.nickname!;
      // ignore: discarded_futures
      TokenStorage.saveNickname(data.nickname!);
    }
    final normalizedGender = _normalizeGender(data.gender);
    if (normalizedGender != null) {
      _selectedGender = normalizedGender;
      // ignore: discarded_futures
      TokenStorage.saveGender(normalizedGender);
    }
    _heightController.text =
        data.height?.toString() ?? _heightController.text;
    _weightController.text =
        data.weight?.toString() ?? _weightController.text;
    _muscleController.text =
        data.skeletalMuscleMass?.toString() ?? _muscleController.text;
    _fatController.text =
        data.bodyFatPercentage?.toString() ?? _fatController.text;
    _bmrController.text = data.bmr?.toString() ?? _bmrController.text;
    _inbodyScoreController.text =
        data.inbodyScore?.toString() ?? _inbodyScoreController.text;
    _budgetController.text =
        data.mealBudget?.toString() ?? _budgetController.text;
    if (data.vegetarianType != null) _selectedVegType = data.vegetarianType!;
    if (data.spicyPreference != null) {
      _spicyLevel = data.spicyPreference!.toDouble();
    }
    if (data.fitnessGoal != null) _selectedFitnessGoal = data.fitnessGoal!;
    _selectedFoodPreferences = data.foodPreferences.toSet();
    _selectedAllergies = data.allergies.toSet();
    _selectedHealthConditions = data.healthConditions.toSet();
    _customNoteController.text = data.customNote ?? '';
  }

  void _enableEditMode() {
    _bkNickname = _nicknameController.text;
    _bkGender = _selectedGender;
    _bkHeight = _heightController.text;
    _bkWeight = _weightController.text;
    _bkMuscle = _muscleController.text;
    _bkFat = _fatController.text;
    _bkBmr = _bmrController.text;
    _bkScore = _inbodyScoreController.text;
    _bkBudget = _budgetController.text;
    _bkVegType = _selectedVegType;
    _bkSpicy = _spicyLevel;
    _bkFitnessGoal = _selectedFitnessGoal;
    _bkFoodPreferences = Set.from(_selectedFoodPreferences);
    _bkAllergies = Set.from(_selectedAllergies);
    _bkHealthConditions = Set.from(_selectedHealthConditions);
    _bkCustomNote = _customNoteController.text;
    setState(() => _isEditMode = true);
  }

  void _cancelEdit() {
    _nicknameController.text = _bkNickname;
    _selectedGender = _bkGender;
    _heightController.text = _bkHeight;
    _weightController.text = _bkWeight;
    _muscleController.text = _bkMuscle;
    _fatController.text = _bkFat;
    _bmrController.text = _bkBmr;
    _inbodyScoreController.text = _bkScore;
    _budgetController.text = _bkBudget;
    _selectedVegType = _bkVegType;
    _spicyLevel = _bkSpicy;
    _selectedFitnessGoal = _bkFitnessGoal;
    _selectedFoodPreferences = Set.from(_bkFoodPreferences);
    _selectedAllergies = Set.from(_bkAllergies);
    _selectedHealthConditions = Set.from(_bkHealthConditions);
    _customNoteController.text = _bkCustomNote;
    setState(() => _isEditMode = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('수정이 취소되었습니다.')));
  }

  Future<void> _saveProfile() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final request = UserProfileRequest(
        nickname: _nicknameController.text,
        gender: _mapGenderToApiValue(_selectedGender),
        height: double.tryParse(_heightController.text),
        weight: double.tryParse(_weightController.text),
        skeletalMuscleMass: double.tryParse(_muscleController.text),
        bodyFatPercentage: double.tryParse(_fatController.text),
        bmr: int.tryParse(_bmrController.text),
        inbodyScore: int.tryParse(_inbodyScoreController.text),
        measurementDate: DateTime.now().toIso8601String().substring(0, 10),
        mealBudget: int.tryParse(_budgetController.text),
        vegetarianType: _selectedVegType,
        spicyPreference: _spicyLevel.toInt(),
        proteinLevel: 'NORMAL',
        fitnessGoal: _selectedFitnessGoal,
        foodPreferences: _selectedFoodPreferences.toList(),
        allergies: _selectedAllergies.toList(),
        healthConditions: _selectedHealthConditions.toList(),
        customNote: _customNoteController.text.trim().isEmpty ? null : _customNoteController.text.trim(),
      );
      final result = await UserProfileService.updateProfile(request: request);
      if (!mounted) return;
      if (!result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error ?? '프로필 저장에 실패했습니다.')),
        );
        return;
      }
      setState(() => _isEditMode = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('프로필 정보가 성공적으로 업데이트되었습니다!')),
      );
      await TokenStorage.saveNickname(_nicknameController.text);
      if (_selectedGender != null) {
        await TokenStorage.saveGender(_selectedGender!);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _mapGenderToApiValue(String? gender) {
    if (gender == '남성') return 'MALE';
    if (gender == '여성') return 'FEMALE';
    return null;
  }

  bool get _hasChanges {
    if (!_isEditMode) return false;
    return _nicknameController.text != _bkNickname ||
        _selectedGender != _bkGender ||
        _heightController.text != _bkHeight ||
        _weightController.text != _bkWeight ||
        _muscleController.text != _bkMuscle ||
        _fatController.text != _bkFat ||
        _bmrController.text != _bkBmr ||
        _inbodyScoreController.text != _bkScore ||
        _budgetController.text != _bkBudget ||
        _selectedVegType != _bkVegType ||
        _spicyLevel != _bkSpicy ||
        _selectedFitnessGoal != _bkFitnessGoal ||
        _selectedFoodPreferences.length != _bkFoodPreferences.length ||
        !_selectedFoodPreferences.containsAll(_bkFoodPreferences) ||
        _selectedAllergies.length != _bkAllergies.length ||
        !_selectedAllergies.containsAll(_bkAllergies) ||
        _selectedHealthConditions.length != _bkHealthConditions.length ||
        !_selectedHealthConditions.containsAll(_bkHealthConditions) ||
        _customNoteController.text != _bkCustomNote;
  }

  // ── 피드백 탭 로직 ────────────────────────────────

  Future<void> _loadFeedbacks() async {
    if (_feedbackLoading) {
      _feedbackPending = true; // 로딩 중 재요청 — 완료 후 한 번 더 실행
      return;
    }
    _feedbackPending = false;
    setState(() => _feedbackLoading = true);
    try {
      final jwt = await TokenStorage.getAccessToken();
      final feedbackFuture = RecommendationService.fetchMyFeedbacks(jwt);
      final aiPickFuture = RecommendationService.fetchMyAiPicks(jwt);
      final feedbacks = await feedbackFuture;
      final aiPicks = await aiPickFuture;
      if (!mounted) return;
      setState(() {
        _feedbackItems = feedbacks;
        _aiPickFeedbackItems =
            aiPicks.where((i) => i.starRating != null || i.isDisliked).toList();
      });
    } finally {
      if (mounted) setState(() => _feedbackLoading = false);
      if (_feedbackPending) _loadFeedbacks();
    }
  }

  Future<void> _confirmDeleteFeedback(FeedbackHistoryItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('피드백 삭제'),
        content: Text('"${item.menuName}" 피드백을 삭제할까요?'),
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
    if (confirmed == true) await _deleteFeedback(item.id);
  }

  Future<void> _deleteFeedback(int logId) async {
    final jwt = await TokenStorage.getAccessToken();
    final success = await RecommendationService.deleteFeedback(logId, jwt);
    if (!mounted) return;
    if (success) {
      setState(() => _feedbackItems.removeWhere((i) => i.id == logId));
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('피드백이 삭제되었습니다.')));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('삭제에 실패했습니다.')));
    }
  }

  // ── 빌드 ─────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isProfileTab = _tabController.index == 0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('마이페이지',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        actions: isProfileTab
            ? [
                if (!_isEditMode)
                  TextButton(
                    onPressed: _enableEditMode,
                    child: const Text('수정',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.primaryColor)),
                  )
                else ...[
                  TextButton(
                    onPressed: _cancelEdit,
                    child: const Text('취소',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.grey)),
                  ),
                  TextButton(
                    onPressed: (_hasChanges && !_isLoading) ? _saveProfile : null,
                    child: Text('저장',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: (_hasChanges && !_isLoading)
                                ? AppTheme.primaryColor
                                : Colors.grey.shade400)),
                  ),
                ],
              ]
            : null,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: '프로필'),
            Tab(text: '피드백'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProfileTab(),
          _buildFeedbackTab(),
        ],
      ),
    );
  }

  // ── 프로필 탭 (뷰/편집 분기) ──────────────────────

  Widget _buildProfileTab() {
    return _isEditMode ? _buildEditForm() : _buildProfileView();
  }

  // ── 뷰 모드 ───────────────────────────────────────

  Widget _buildProfileView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeaderCard(),
            const SizedBox(height: 16),
            _buildViewCard(
              '체성분',
              Column(children: [
                Row(children: [
                  Expanded(child: _buildStat('키', _fmtVal(_heightController, 'cm'))),
                  Expanded(child: _buildStat('체중', _fmtVal(_weightController, 'kg'))),
                  Expanded(child: _buildStat('체지방률', _fmtVal(_fatController, '%'))),
                ]),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: _buildStat('골격근량', _fmtVal(_muscleController, 'kg'))),
                  Expanded(child: _buildStat('기초대사량', _fmtVal(_bmrController, 'kcal'))),
                  Expanded(child: _buildStat('인바디', _fmtVal(_inbodyScoreController, '점'))),
                ]),
              ]),
            ),
            const SizedBox(height: 12),
            _buildViewCard(
              '식습관',
              Column(children: [
                _buildKVRow('끼니 예산', _fmtBudget()),
                _buildKVRow('채식 유형', _vegOptions[_selectedVegType] ?? '해당 없음'),
                _buildKVRow('매운맛', '${_spicyLevel.toInt()}단계'),
                _buildKVRow('식단 목표', _fitnessGoalOptions[_selectedFitnessGoal] ?? '일반식단',
                    isLast: true),
              ]),
            ),
            const SizedBox(height: 12),
            _buildViewCard(
              '음식 스타일',
              _buildTagChips(
                _selectedFoodPreferences.toList(),
                chipColor: AppTheme.primaryColor.withValues(alpha: 0.08),
                borderColor: AppTheme.primaryColor.withValues(alpha: 0.3),
                textColor: AppTheme.primaryColor,
                emptyText: '설정된 스타일 없음',
              ),
            ),
            const SizedBox(height: 12),
            _buildViewCard(
              '알레르기',
              _buildTagChips(
                _selectedAllergies.toList(),
                chipColor: Colors.orange.shade50,
                borderColor: Colors.orange.shade200,
                textColor: Colors.orange.shade800,
                emptyText: '설정된 알레르기 없음',
              ),
            ),
            const SizedBox(height: 12),
            _buildViewCard(
              '건강 상태',
              _buildTagChips(
                _selectedHealthConditions.toList(),
                chipColor: Colors.blue.shade50,
                borderColor: Colors.blue.shade200,
                textColor: Colors.blue.shade800,
                emptyText: '설정된 건강 상태 없음',
              ),
            ),
            const SizedBox(height: 12),
            _buildViewCard(
              '추가 선호사항',
              Text(
                _customNoteController.text.trim().isEmpty
                    ? '입력된 내용 없음'
                    : _customNoteController.text.trim(),
                style: TextStyle(
                    fontSize: 14, color: Colors.grey[800], height: 1.5),
              ),
            ),
            const SizedBox(height: 12),
            _buildHistoryButton(),
            const SizedBox(height: 10),
            _buildPriceAlertButton(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryButton() {
    return GestureDetector(
      onTap: () async {
        final jwt = await TokenStorage.getAccessToken();
        if (!mounted || jwt == null || jwt.isEmpty) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RecommendationHistoryScreen(jwt: jwt),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
        child: Row(
          children: [
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) =>
                  AppTheme.aiGradient.createShader(bounds),
              child: const Icon(Icons.bookmark_rounded, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'AI 추천 이력',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded,
                color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceAlertButton() {
    return GestureDetector(
      onTap: () async {
        final jwt = await TokenStorage.getAccessToken();
        if (!mounted || jwt == null || jwt.isEmpty) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PriceAlertScreen(jwt: jwt),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
        child: Row(
          children: [
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) =>
                  AppTheme.aiGradient.createShader(bounds),
              child: const Icon(Icons.notifications_active_rounded, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              '가격 변동 알림',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded,
                color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeaderCard() {
    final nickname = _nicknameController.text.trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.18),
            child: Icon(Icons.person_rounded, size: 38, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nickname.isEmpty ? '닉네임 없음' : nickname,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                if (_selectedGender != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _selectedGender!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
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

  Widget _buildViewCard(String title, Widget body) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade500,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 12),
          body,
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        const SizedBox(height: 3),
        Text(value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildKVRow(String key, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Row(
        children: [
          Text(key,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildTagChips(
    List<String> items, {
    required Color chipColor,
    required Color borderColor,
    required Color textColor,
    required String emptyText,
  }) {
    if (items.isEmpty) {
      return Text(emptyText,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade400));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: items
          .map((item) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: chipColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                ),
                child: Text(item,
                    style: TextStyle(
                        fontSize: 13,
                        color: textColor,
                        fontWeight: FontWeight.w500)),
              ))
          .toList(),
    );
  }

  String _fmtVal(TextEditingController c, String suffix) {
    final v = c.text.trim();
    return v.isEmpty ? '-' : '$v$suffix';
  }

  String _fmtBudget() {
    final v = _budgetController.text.trim();
    if (v.isEmpty) return '-';
    final n = int.tryParse(v);
    if (n == null) return '-';
    return '${n.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}원';
  }

  // ── 편집 모드 ─────────────────────────────────────

  Widget _buildEditForm() {
    return SafeArea(
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('기본 정보'),
              _buildTextField(_nicknameController, '닉네임', isNumber: false),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: '성별',
                  filled: true,
                  fillColor: Colors.white,
                ),
                value: _selectedGender,
                onChanged: (v) => setState(() => _selectedGender = v!),
                items: ['남성', '여성']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
              ),
              const SizedBox(height: 32),

              _buildSectionTitle('체성분 정보'),
              Row(children: [
                Expanded(
                    child: _buildTextField(_heightController, '키',
                        suffix: 'cm')),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildTextField(_weightController, '몸무게',
                        suffix: 'kg')),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: _buildTextField(_muscleController, '골격근량',
                        suffix: 'kg')),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildTextField(_fatController, '체지방률',
                        suffix: '%')),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: _buildTextField(_bmrController, '기초대사량',
                        suffix: 'kcal')),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildTextField(_inbodyScoreController, '인바디 점수',
                        suffix: '점')),
              ]),
              const SizedBox(height: 32),

              _buildSectionTitle('식습관 설정'),
              _buildTextField(_budgetController, '끼니당 허용 예산', suffix: '원'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: '채식 유형',
                  filled: true,
                  fillColor: Colors.white,
                ),
                value: _selectedVegType,
                onChanged: (v) => setState(() => _selectedVegType = v!),
                items: _vegOptions.entries
                    .map((e) =>
                        DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
              ),
              const SizedBox(height: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '매운맛 선호도 (${_spicyLevel.toInt()}단계)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Slider(
                    value: _spicyLevel,
                    min: 1,
                    max: 5,
                    divisions: 4,
                    activeColor: AppTheme.primaryColor,
                    onChanged: (v) => setState(() => _spicyLevel = v),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('식단 목표',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: _fitnessGoalOptions.entries.map((e) {
                  final isSelected = _selectedFitnessGoal == e.key;
                  return ChoiceChip(
                    label: Text(e.value,
                        style: const TextStyle(color: Colors.black87)),
                    selected: isSelected,
                    selectedColor:
                        AppTheme.primaryColor.withValues(alpha: 0.2),
                    checkmarkColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onSelected: (_) =>
                        setState(() => _selectedFitnessGoal = e.key),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const Text('선호하는 음식 스타일',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildChipBox(
                children: _foodPreferenceOptions.map((pref) {
                  final isSelected = _selectedFoodPreferences.contains(pref);
                  return FilterChip(
                    label: Text(pref,
                        style: const TextStyle(color: Colors.black87)),
                    selected: isSelected,
                    backgroundColor: Colors.white,
                    selectedColor:
                        AppTheme.primaryColor.withValues(alpha: 0.2),
                    checkmarkColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onSelected: (selected) => setState(() => selected
                        ? _selectedFoodPreferences.add(pref)
                        : _selectedFoodPreferences.remove(pref)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text('추가 선호사항 (선택)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _customNoteController,
                maxLength: 200,
                maxLines: 3,
                enabled: _isEditMode,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: '예: 제육볶음 같은 고기 요리가 좋아요. 국물 요리는 별로예요.',
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 32),

              _buildSectionTitle('건강 상태'),
              _buildChipBox(
                children: _healthConditionOptions.map((cond) {
                  final isSelected = _selectedHealthConditions.contains(cond);
                  return FilterChip(
                    label: Text(cond,
                        style: const TextStyle(color: Colors.black87)),
                    selected: isSelected,
                    backgroundColor: Colors.white,
                    selectedColor:
                        AppTheme.primaryColor.withValues(alpha: 0.2),
                    checkmarkColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onSelected: (selected) => setState(() => selected
                        ? _selectedHealthConditions.add(cond)
                        : _selectedHealthConditions.remove(cond)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              _buildSectionTitle('알레르기'),
              _buildChipBox(
                children: _allergyOptions.map((allergy) {
                  final isSelected = _selectedAllergies.contains(allergy);
                  return FilterChip(
                    label: Text(allergy,
                        style: const TextStyle(color: Colors.black87)),
                    selected: isSelected,
                    backgroundColor: Colors.white,
                    selectedColor:
                        AppTheme.primaryColor.withValues(alpha: 0.2),
                    checkmarkColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onSelected: (selected) => setState(() => selected
                        ? _selectedAllergies.add(allergy)
                        : _selectedAllergies.remove(allergy)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ── 피드백 탭 ─────────────────────────────────────

  Widget _buildFeedbackTab() {
    if (_feedbackLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final likedTotal =
        _feedbackItems.where((i) => i.feedbackScore == 1).length;
    final dislikedTotal =
        _feedbackItems.where((i) => i.feedbackScore == -1).length;
    final aiTotal = _aiPickFeedbackItems.length;

    // 현재 탭에 맞는 목록 계산
    List<Widget> listItems;
    if (_feedbackTab == 2) {
      final filtered = _searchQuery.isEmpty
          ? _aiPickFeedbackItems
          : _aiPickFeedbackItems
              .where((i) => i.menuName.contains(_searchQuery))
              .toList();
      listItems = filtered.isEmpty
          ? [_buildFeedbackEmpty()]
          : filtered.map(_buildAiPickFeedbackItem).toList();
    } else {
      final targetScore = _feedbackTab == 0 ? 1 : -1;
      final filtered = (_searchQuery.isEmpty
              ? _feedbackItems
              : _feedbackItems
                  .where((i) => i.menuName.contains(_searchQuery))
                  .toList())
          .where((i) => i.feedbackScore == targetScore)
          .toList();
      listItems = filtered.isEmpty
          ? [_buildFeedbackEmpty()]
          : filtered.map(_buildFeedbackItem).toList();
    }

    return Column(
      children: [
        // ── 검색 바 ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: '메뉴 이름으로 검색',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ),
        // ── 3-버튼 토글 ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: _buildToggleButton(
                  label: '좋아요',
                  count: likedTotal,
                  icon: Icons.thumb_up,
                  isActive: _feedbackTab == 0,
                  activeColor: AppTheme.primaryColor,
                  onTap: () => setState(() => _feedbackTab = 0),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildToggleButton(
                  label: '싫어요',
                  count: dislikedTotal,
                  icon: Icons.thumb_down,
                  isActive: _feedbackTab == 1,
                  activeColor: Colors.redAccent,
                  onTap: () => setState(() => _feedbackTab = 1),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildToggleButton(
                  label: 'AI피드백',
                  count: aiTotal,
                  icon: Icons.auto_awesome_rounded,
                  isActive: _feedbackTab == 2,
                  activeColor: AppTheme.primaryColor,
                  activeGradient: AppTheme.aiGradient,
                  onTap: () => setState(() => _feedbackTab = 2),
                ),
              ),
            ],
          ),
        ),
        // ── 목록 ──
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadFeedbacks,
            child: ListView(
              children: [...listItems, const SizedBox(height: 16)],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackEmpty() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Center(
        child: Text(
          _searchQuery.isEmpty ? '아직 피드백한 메뉴가 없습니다.' : '검색 결과가 없습니다.',
          style: TextStyle(color: Colors.grey.shade500),
        ),
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required int count,
    required IconData icon,
    required bool isActive,
    required Color activeColor,
    LinearGradient? activeGradient,
    required VoidCallback onTap,
  }) {
    final useGradient = isActive && activeGradient != null;
    final contentColor = useGradient ? activeGradient.colors.last : activeColor;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: useGradient
              ? LinearGradient(
                  colors: activeGradient.colors
                      .map((c) => c.withValues(alpha: 0.15))
                      .toList(),
                  begin: activeGradient.begin,
                  end: activeGradient.end,
                )
              : null,
          color: useGradient
              ? null
              : isActive
                  ? activeColor.withValues(alpha: 0.1)
                  : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? contentColor : Colors.grey.shade300,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            useGradient
                ? ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (b) => activeGradient.createShader(b),
                    child: Icon(icon, size: 16),
                  )
                : Icon(icon,
                    size: 16,
                    color: isActive ? activeColor : Colors.grey.shade500),
            const SizedBox(width: 6),
            useGradient
                ? ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (b) => activeGradient.createShader(b),
                    child: Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  )
                : Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isActive ? activeColor : Colors.grey.shade500,
                    ),
                  ),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                color: isActive ? contentColor : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAiPickEditSheet(AiPickItem item) async {
    int starRating = item.starRating ?? 0;
    final reasonController =
        TextEditingController(text: item.feedbackReason ?? '');
    bool submitting = false; // 빌더 밖에서 선언 — rebuild 시 리셋 방지
    bool? result;

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
                24, 20, 24, MediaQuery.of(sheetCtx).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(item.menuName,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('이 추천은 어떠셨나요?',
                    style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                const SizedBox(height: 16),
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
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: submitting || starRating == 0
                        ? null
                        : () async {
                            setSheetState(() => submitting = true);
                            final jwt = await TokenStorage.getAccessToken();
                            final ok =
                                await RecommendationService.updateFeedback(
                              item.id,
                              starRating,
                              reasonController.text.trim(),
                              jwt,
                            );
                            result = ok;
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
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
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

    WidgetsBinding.instance.addPostFrameCallback((_) => reasonController.dispose());
    if (!mounted) return;
    if (result == true) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('피드백이 수정됐습니다')));
      await _loadFeedbacks();
    } else if (result == false) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('저장에 실패했습니다')));
    }
  }

  Widget _buildAiPickFeedbackItem(AiPickItem item) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: () => _showAiPickEditSheet(item),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: item.menuImageUrl != null && item.menuImageUrl!.isNotEmpty
            ? Image.network(
                item.menuImageUrl!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, e, s) => _defaultMenuIcon(),
              )
            : _defaultMenuIcon(),
      ),
      title: Text(item.menuName,
          style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 2),
          if (item.isDisliked)
            Row(
              children: [
                Icon(Icons.block_rounded, size: 13, color: Colors.red.shade300),
                const SizedBox(width: 4),
                Text(
                  '다시 추천 안함',
                  style: TextStyle(fontSize: 12, color: Colors.red.shade300),
                ),
              ],
            )
          else
            Row(
              children: List.generate(
                5,
                (i) => Icon(
                  i < (item.starRating ?? 0)
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: 14,
                  color: Colors.amber,
                ),
              ),
            ),
          if (!item.isDisliked &&
              item.feedbackReason != null &&
              item.feedbackReason!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              item.feedbackReason!,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (item.createdAt != null) ...[
            const SizedBox(height: 2),
            Text(
              item.createdAt!,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
          ],
        ],
      ),
      isThreeLine: true,
      trailing: item.isDisliked
          ? null
          : Icon(Icons.edit_outlined, size: 16, color: Colors.grey.shade400),
    );
  }

  Widget _buildFeedbackItem(FeedbackHistoryItem item) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: item.menuImageUrl != null && item.menuImageUrl!.isNotEmpty
            ? Image.network(
                item.menuImageUrl!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _defaultMenuIcon(),
              )
            : _defaultMenuIcon(),
      ),
      title: Text(item.menuName,
          style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: item.createdAt != null
          ? Text(item.createdAt!,
              style:
                  TextStyle(fontSize: 12, color: Colors.grey.shade500))
          : null,
      trailing: IconButton(
        icon: Icon(Icons.delete_outline, color: Colors.grey.shade400),
        onPressed: () => _confirmDeleteFeedback(item),
      ),
    );
  }

  Widget _defaultMenuIcon() => Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.restaurant, color: Colors.grey.shade400),
      );

  // ── 공통 위젯 헬퍼 ────────────────────────────────

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildChipBox({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Wrap(spacing: 8.0, runSpacing: 8.0, children: children),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    String? suffix,
    bool isNumber = true,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: _isLoading,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return '필수 입력 항목입니다.';
        if (isNumber && double.tryParse(value) == null) return '올바른 숫자를 입력해주세요';
        return null;
      },
    );
  }
}
