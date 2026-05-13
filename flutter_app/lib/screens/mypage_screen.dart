import 'package:flutter/material.dart';
import 'package:flutter_app/models/user_profile_models.dart';
import 'package:flutter_app/services/user_profile_service.dart';
import 'package:flutter_app/services/token_storage.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditMode = false;
  bool _isLoading = false;

  // 1. 기본 정보
  final TextEditingController _nicknameController = TextEditingController(
    text: "김철수",
  );
  String? _selectedGender = '남성';

  // 2. 인바디 정보
  final TextEditingController _heightController = TextEditingController(
    text: "175",
  );
  final TextEditingController _weightController = TextEditingController(
    text: "70",
  );
  final TextEditingController _muscleController = TextEditingController(
    text: "35",
  );
  final TextEditingController _fatController = TextEditingController(
    text: "15",
  );
  final TextEditingController _bmrController = TextEditingController(
    text: "1600",
  );
  final TextEditingController _inbodyScoreController = TextEditingController(
    text: "80",
  );

  // 3. 식습관 및 예산
  final TextEditingController _budgetController = TextEditingController(
    text: "8000",
  );
  String _selectedVegType = 'NONE';
  double _spicyLevel = 3;

  // 4. 알레르기 정보
  Set<String> _selectedAllergies = {'우유', '밀가루'};

  final List<String> _allergyOptions = [
    '땅콩',
    '갑각류',
    '대두',
    '우유',
    '밀가루',
    '계란',
    '견과류',
    '생선',
  ];
  final Map<String, String> _vegOptions = {
    'NONE': '해당 없음',
    'VEGAN': '비건 (완전 채식)',
    'LACTO': '락토 (우유 허용)',
    'OVO': '오보 (계란 허용)',
    'PESCO': '페스코 (해산물 허용)',
  };

  // 취소 버튼을 위한 데이터 백업 저장소
  late String _bkNickname;
  late String? _bkGender;
  late String _bkHeight,
      _bkWeight,
      _bkMuscle,
      _bkFat,
      _bkBmr,
      _bkScore,
      _bkBudget;
  late String _bkVegType;
  late double _bkSpicy;
  late Set<String> _bkAllergies;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadBasicUserInfoFromLocal();
  }

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
        if (normalizedGender != null) {
          _selectedGender = normalizedGender;
        }
      });
    } catch (_) {
      // 로컬 저장소 접근 실패는 조용히 무시
    }
  }

  String? _normalizeGender(String? raw) {
    if (raw == null) return null;
    final v = raw.trim();

    // 서버/로컬 값이 다양하게 올 수 있어서 UI 드롭다운 값으로 정규화
    if (v == '남성' || v == 'M' || v.toLowerCase() == 'male') return '남성';
    if (v == '여성' || v == 'F' || v.toLowerCase() == 'female') return '여성';

    // 이미 '남자/여자'로 저장된 케이스도 흡수
    if (v == '남자') return '남성';
    if (v == '여자') return '여성';

    return null;
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final result = await UserProfileService.getProfile();
      if (!mounted) return;
      if (!result.success || result.data == null) {
        // 서버가 아직 준비 안 된 경우를 고려해서 조용히 유지
        return;
      }
      _applyProfileToForm(result.data!);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyProfileToForm(UserProfileData data) {
    if (data.nickname != null && data.nickname!.isNotEmpty) {
      _nicknameController.text = data.nickname!;
      // 서버 값이 최신이면 로컬에도 동기화
      // ignore: discarded_futures
  TokenStorage.saveNickname(data.nickname!);
    }
    final normalizedGender = _normalizeGender(data.gender);
    if (normalizedGender != null) {
      _selectedGender = normalizedGender;
      // ignore: discarded_futures
      TokenStorage.saveGender(normalizedGender);
    }

    _heightController.text = data.height?.toString() ?? _heightController.text;
    _weightController.text = data.weight?.toString() ?? _weightController.text;
    _muscleController.text =
        data.skeletalMuscleMass?.toString() ?? _muscleController.text;
    _fatController.text =
        data.bodyFatPercentage?.toString() ?? _fatController.text;
    _bmrController.text = data.bmr?.toString() ?? _bmrController.text;
    _inbodyScoreController.text =
        data.inbodyScore?.toString() ?? _inbodyScoreController.text;
    _budgetController.text =
        data.mealBudget?.toString() ?? _budgetController.text;
    if (data.vegetarianType != null) {
      _selectedVegType = data.vegetarianType!;
    }
    if (data.spicyPreference != null) {
      _spicyLevel = data.spicyPreference!.toDouble();
    }
    _selectedAllergies = data.allergies.toSet();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _muscleController.dispose();
    _fatController.dispose();
    _bmrController.dispose();
    _inbodyScoreController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  // 수정 모드 켜기 (현재 데이터 백업)
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
    _bkAllergies = Set.from(_selectedAllergies);

    setState(() {
      _isEditMode = true;
    });
  }

  // 수정 취소하기 (백업 데이터로 원상 복구)
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
    _selectedAllergies = Set.from(_bkAllergies);

    setState(() {
      _isEditMode = false;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('수정이 취소되었습니다.')));
  }

  // 변경사항 저장하기
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
        allergies: _selectedAllergies.toList(),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('프로필 정보가 성공적으로 업데이트되었습니다!')));
      
      // 로컬 닉네임/성별 정보도 업데이트
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '마이페이지',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        actions: [
          if (!_isEditMode)
            TextButton(
              onPressed: _enableEditMode,
              child: Text(
                '수정',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
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
                    fillColor: _isEditMode
                        ? Colors.white
                        : Colors.grey.shade100,
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
                      child: _buildTextField(
                        _heightController,
                        '키',
                        suffix: 'cm',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        _weightController,
                        '몸무게',
                        suffix: 'kg',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        _muscleController,
                        '골격근량',
                        suffix: 'kg',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        _fatController,
                        '체지방률',
                        suffix: '%',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        _bmrController,
                        '기초대사량',
                        suffix: 'kcal',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        _inbodyScoreController,
                        '인바디 점수',
                        suffix: '점',
                      ),
                    ),
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
                    fillColor: _isEditMode
                        ? Colors.white
                        : Colors.grey.shade100,
                  ),
                  value: _selectedVegType,
                  onChanged: _isEditMode
                      ? (v) => setState(() => _selectedVegType = v!)
                      : null,
                  items: _vegOptions.entries
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ),
                      )
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
                        activeColor: Theme.of(context).primaryColor,
                        onChanged: _isEditMode
                            ? (v) => setState(() => _spicyLevel = v)
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                _buildSectionTitle('4. 알레르기 유발 물질'),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(_isEditMode ? 0 : 16.0),
                  decoration: BoxDecoration(
                    color: _isEditMode
                        ? Colors.transparent
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: _isEditMode
                        ? null
                        : Border.all(color: Colors.grey.shade300),
                  ),
                  child: IgnorePointer(
                    ignoring: !_isEditMode,
                    child: Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: _allergyOptions.map((allergy) {
                        final isSelected = _selectedAllergies.contains(allergy);
                        return FilterChip(
                          label: Text(
                            allergy,
                            style: TextStyle(
                              // 텍스트 색상도 읽기 전용일 땐 회색으로 변경
                              color: _isEditMode
                                  ? Colors.black87
                                  : Colors.grey.shade600,
                            ),
                          ),
                          selected: isSelected,
                          // 핵심 수정: 배경색과 선택된 색상 모두 음영 처리
                          backgroundColor: _isEditMode
                              ? Colors.white
                              : Colors.grey.shade200,
                          selectedColor: _isEditMode
                              ? Theme.of(context).primaryColor.withOpacity(0.2)
                              : Colors.grey.shade300,
                          checkmarkColor: _isEditMode
                              ? Theme.of(context).primaryColor
                              : Colors.grey.shade600,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              color: _isEditMode
                                  ? Colors.grey.shade300
                                  : Colors.transparent,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          onSelected: (bool selected) {
                            setState(() {
                              selected
                                  ? _selectedAllergies.add(allergy)
                                  : _selectedAllergies.remove(allergy);
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                if (_isEditMode)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _cancelEdit,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            side: BorderSide(color: Colors.grey.shade400),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            '취소',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveProfile,
                          child: const Text(
                            '변경사항 저장',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: Theme.of(context).primaryColor,
        ),
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
