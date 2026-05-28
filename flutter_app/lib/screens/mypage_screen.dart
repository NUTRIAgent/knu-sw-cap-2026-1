import 'package:flutter/material.dart';
import 'package:flutter_app/models/recommendation_models.dart';
import 'package:flutter_app/models/user_profile_models.dart';
import 'package:flutter_app/services/recommendation_service.dart';
import 'package:flutter_app/services/user_profile_service.dart';
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

  // ── 피드백 탭 상태 ──────────────────────────────
  List<FeedbackHistoryItem> _feedbackItems = [];
  bool _feedbackLoading = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showLiked = true;

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
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _loadProfile();
    _loadBasicUserInfoFromLocal();
    _loadFeedbacks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nicknameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _muscleController.dispose();
    _fatController.dispose();
    _bmrController.dispose();
    _inbodyScoreController.dispose();
    _budgetController.dispose();
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
        !_selectedHealthConditions.containsAll(_bkHealthConditions);
  }

  // ── 피드백 탭 로직 ────────────────────────────────

  Future<void> _loadFeedbacks() async {
    setState(() => _feedbackLoading = true);
    try {
      final jwt = await TokenStorage.getAccessToken();
      final items = await RecommendationService.fetchMyFeedbacks(jwt);
      if (!mounted) return;
      setState(() => _feedbackItems = items);
    } finally {
      if (mounted) setState(() => _feedbackLoading = false);
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

  // ── 프로필 탭 ─────────────────────────────────────

  Widget _buildProfileTab() {
    return SafeArea(
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('1. 기본 정보'),
              _buildTextField(_nicknameController, '닉네임', isNumber: false),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: '성별',
                  filled: true,
                  fillColor:
                      _isEditMode ? Colors.white : Colors.grey.shade100,
                ),
                value: _selectedGender,
                onChanged: _isEditMode
                    ? (v) => setState(() => _selectedGender = v!)
                    : null,
                items: ['남성', '여성']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
              ),
              const SizedBox(height: 32),

              _buildSectionTitle('2. 체성분 (InBody) 정보'),
              Row(
                children: [
                  Expanded(
                      child:
                          _buildTextField(_heightController, '키', suffix: 'cm')),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildTextField(_weightController, '몸무게',
                          suffix: 'kg')),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: _buildTextField(_muscleController, '골격근량',
                          suffix: 'kg')),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildTextField(_fatController, '체지방률',
                          suffix: '%')),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: _buildTextField(_bmrController, '기초대사량',
                          suffix: 'kcal')),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildTextField(_inbodyScoreController, '인바디 점수',
                          suffix: '점')),
                ],
              ),
              const SizedBox(height: 32),

              _buildSectionTitle('3. 식습관 및 예산 설정'),
              _buildTextField(_budgetController, '끼니당 허용 예산', suffix: '원'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: '채식 유형 선택',
                  filled: true,
                  fillColor:
                      _isEditMode ? Colors.white : Colors.grey.shade100,
                ),
                value: _selectedVegType,
                onChanged: _isEditMode
                    ? (v) => setState(() => _selectedVegType = v!)
                    : null,
                items: _vegOptions.entries
                    .map((e) => DropdownMenuItem(
                        value: e.key, child: Text(e.value)))
                    .toList(),
              ),
              const SizedBox(height: 24),
              Opacity(
                opacity: _isEditMode ? 1.0 : 0.5,
                child: Column(
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
                      onChanged: _isEditMode
                          ? (v) => setState(() => _spicyLevel = v)
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('식단 목표',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              IgnorePointer(
                ignoring: !_isEditMode,
                child: Opacity(
                  opacity: _isEditMode ? 1.0 : 0.5,
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: _fitnessGoalOptions.entries.map((e) {
                      final isSelected = _selectedFitnessGoal == e.key;
                      return ChoiceChip(
                        label: Text(e.value,
                            style: TextStyle(
                                color: _isEditMode
                                    ? Colors.black87
                                    : Colors.grey.shade600)),
                        selected: isSelected,
                        selectedColor: _isEditMode
                            ? AppTheme.primaryColor.withValues(alpha: 0.2)
                            : Colors.grey.shade300,
                        checkmarkColor: _isEditMode
                            ? AppTheme.primaryColor
                            : Colors.grey.shade600,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                              color: _isEditMode
                                  ? Colors.grey.shade300
                                  : Colors.transparent),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        onSelected: (_) =>
                            setState(() => _selectedFitnessGoal = e.key),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('선호하는 음식 스타일 (복수 선택 가능)',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildChipBox(
                children: _foodPreferenceOptions.map((pref) {
                  final isSelected = _selectedFoodPreferences.contains(pref);
                  return FilterChip(
                    label: Text(pref,
                        style: TextStyle(
                            color: _isEditMode
                                ? Colors.black87
                                : Colors.grey.shade600)),
                    selected: isSelected,
                    backgroundColor:
                        _isEditMode ? Colors.white : Colors.grey.shade200,
                    selectedColor: _isEditMode
                        ? AppTheme.primaryColor.withValues(alpha: 0.2)
                        : Colors.grey.shade300,
                    checkmarkColor: _isEditMode
                        ? AppTheme.primaryColor
                        : Colors.grey.shade600,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                          color: _isEditMode
                              ? Colors.grey.shade300
                              : Colors.transparent),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onSelected: (selected) => setState(() => selected
                        ? _selectedFoodPreferences.add(pref)
                        : _selectedFoodPreferences.remove(pref)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              _buildSectionTitle('4. 건강 상태'),
              _buildChipBox(
                children: _healthConditionOptions.map((cond) {
                  final isSelected = _selectedHealthConditions.contains(cond);
                  return FilterChip(
                    label: Text(cond,
                        style: TextStyle(
                            color: _isEditMode
                                ? Colors.black87
                                : Colors.grey.shade600)),
                    selected: isSelected,
                    backgroundColor:
                        _isEditMode ? Colors.white : Colors.grey.shade200,
                    selectedColor: _isEditMode
                        ? AppTheme.primaryColor.withValues(alpha: 0.2)
                        : Colors.grey.shade300,
                    checkmarkColor: _isEditMode
                        ? AppTheme.primaryColor
                        : Colors.grey.shade600,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                          color: _isEditMode
                              ? Colors.grey.shade300
                              : Colors.transparent),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onSelected: (selected) => setState(() => selected
                        ? _selectedHealthConditions.add(cond)
                        : _selectedHealthConditions.remove(cond)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              _buildSectionTitle('5. 알레르기 유발 물질'),
              _buildChipBox(
                children: _allergyOptions.map((allergy) {
                  final isSelected = _selectedAllergies.contains(allergy);
                  return FilterChip(
                    label: Text(allergy,
                        style: TextStyle(
                            color: _isEditMode
                                ? Colors.black87
                                : Colors.grey.shade600)),
                    selected: isSelected,
                    backgroundColor:
                        _isEditMode ? Colors.white : Colors.grey.shade200,
                    selectedColor: _isEditMode
                        ? AppTheme.primaryColor.withValues(alpha: 0.2)
                        : Colors.grey.shade300,
                    checkmarkColor: _isEditMode
                        ? AppTheme.primaryColor
                        : Colors.grey.shade600,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                          color: _isEditMode
                              ? Colors.grey.shade300
                              : Colors.transparent),
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

    final filtered = _searchQuery.isEmpty
        ? _feedbackItems
        : _feedbackItems
            .where((item) => item.menuName.contains(_searchQuery))
            .toList();

    final liked = filtered.where((i) => i.feedbackScore == 1).toList();
    final disliked = filtered.where((i) => i.feedbackScore == -1).toList();
    final activeItems = _showLiked ? liked : disliked;

    final likedTotal = _feedbackItems.where((i) => i.feedbackScore == 1).length;
    final dislikedTotal =
        _feedbackItems.where((i) => i.feedbackScore == -1).length;

    return Column(
      children: [
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: _buildToggleButton(
                  label: '좋아요',
                  count: likedTotal,
                  icon: Icons.thumb_up,
                  isActive: _showLiked,
                  activeColor: AppTheme.primaryColor,
                  onTap: () => setState(() => _showLiked = true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildToggleButton(
                  label: '싫어요',
                  count: dislikedTotal,
                  icon: Icons.thumb_down,
                  isActive: !_showLiked,
                  activeColor: Colors.redAccent,
                  onTap: () => setState(() => _showLiked = false),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadFeedbacks,
            child: activeItems.isEmpty
                ? ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 80),
                        child: Center(
                          child: Text(
                            _searchQuery.isEmpty
                                ? '아직 피드백한 메뉴가 없습니다.'
                                : '검색 결과가 없습니다.',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    itemCount: activeItems.length,
                    itemBuilder: (_, i) => _buildFeedbackItem(activeItems[i]),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButton({
    required String label,
    required int count,
    required IconData icon,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withValues(alpha: 0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? activeColor : Colors.grey.shade300,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16,
                color: isActive ? activeColor : Colors.grey.shade500),
            const SizedBox(width: 6),
            Text(
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
                color: isActive ? activeColor : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
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
                errorBuilder: (context, error, stackTrace) => _defaultMenuIcon(),
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
      padding: EdgeInsets.all(_isEditMode ? 0 : 16.0),
      decoration: BoxDecoration(
        color: _isEditMode ? Colors.transparent : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border:
            _isEditMode ? null : Border.all(color: Colors.grey.shade300),
      ),
      child: IgnorePointer(
        ignoring: !_isEditMode,
        child: Wrap(spacing: 8.0, runSpacing: 8.0, children: children),
      ),
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
      readOnly: !_isEditMode || _isLoading,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      onChanged: (_) {
        if (_isEditMode) setState(() {});
      },
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        filled: true,
        fillColor: _isEditMode ? Colors.white : Colors.grey.shade100,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return '필수 입력 항목입니다.';
        if (isNumber && double.tryParse(value) == null) return '숫자만 입력';
        return null;
      },
    );
  }
}
