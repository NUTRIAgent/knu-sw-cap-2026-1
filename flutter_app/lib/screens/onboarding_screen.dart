import 'package:flutter/material.dart';
import 'main_screen.dart'; 
import 'package:flutter_app/models/user_profile_models.dart';
import 'package:flutter_app/services/user_profile_service.dart';
import 'package:flutter_app/theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  // 1. 인바디 정보 컨트롤러
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _muscleController = TextEditingController();
  final TextEditingController _fatController = TextEditingController();
  final TextEditingController _bmrController = TextEditingController();
  final TextEditingController _inbodyScoreController = TextEditingController();

  // 2. 식습관 및 예산 컨트롤러
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _customNoteController = TextEditingController();
  String _selectedVegType = 'NONE';
  double _spicyLevel = 3;
  String _selectedFitnessGoal = 'GENERAL';
  final Set<String> _selectedFoodPreferences = {};

  // 3. 건강 상태
  final Set<String> _selectedHealthConditions = {};

  // 4. 알레르기 정보
  final Set<String> _selectedAllergies = {};

  final List<String> _healthConditionOptions = ['고혈압', '당뇨', '고지혈증', '비만', '신장질환', '간질환', '심장질환', '갑상선질환'];
  final List<String> _allergyOptions = ['땅콩', '갑각류', '대두', '우유', '밀가루', '계란', '견과류', '생선'];
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
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _muscleController.dispose();
    _fatController.dispose();
    _bmrController.dispose();
    _inbodyScoreController.dispose();
    _budgetController.dispose();
    _customNoteController.dispose();
    super.dispose();
  }

  // 💡 정보 저장 및 대시보드로 이동
  Future<void> _finishOnboarding() async {
    if (_isLoading) return;

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('입력하지 않은 필수 항목이 있습니다.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final request = UserProfileRequest(
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

      final result = await UserProfileService.saveProfile(request: request);
      if (!mounted) return;

      if (!result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error ?? '프로필 저장에 실패했습니다.')),
        );
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('기초 정보 입력', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '메밀(Memeal)에 오신 것을 환영합니다!\nAI가 완벽한 맞춤 식단을 추천해 드릴 수 있도록\n아래 정보를 정확하게 입력해 주세요.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.5),
                ),
                const SizedBox(height: 32),

                // 💡 기본 정보 섹션 완전 삭제, 인바디 정보부터 시작
                _buildSectionTitle('1. 체성분 (InBody) 정보'),
                Row(
                  children: [
                    Expanded(child: _buildTextField(_heightController, '키', suffix: 'cm', hint: '175')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField(_weightController, '몸무게', suffix: 'kg', hint: '70')),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildTextField(_muscleController, '골격근량', suffix: 'kg', hint: '35')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField(_fatController, '체지방률', suffix: '%', hint: '15')),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildTextField(_bmrController, '기초대사량', suffix: 'kcal', hint: '1600')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField(_inbodyScoreController, '인바디 점수', suffix: '점', hint: '80')),
                  ],
                ),
                const SizedBox(height: 32),

                _buildSectionTitle('2. 식습관 및 예산 설정'),
                _buildTextField(_budgetController, '끼니당 허용 예산', suffix: '원', hint: '8000'),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: '채식 유형 선택', 
                    filled: true, 
                    fillColor: Colors.white,
                    // 💡 theme.dart의 16px 라운딩이 자동으로 적용됨
                  ),
                  initialValue: _selectedVegType,
                  onChanged: (v) => setState(() => _selectedVegType = v!),
                  items: _vegOptions.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                ),
                const SizedBox(height: 24),
                Text('매운맛 선호도 (${_spicyLevel.toInt()}단계)', style: const TextStyle(fontWeight: FontWeight.bold)),
                Slider(
                  value: _spicyLevel,
                  min: 1, max: 5, divisions: 4,
                  activeColor: AppTheme.primaryColor,
                  onChanged: (v) => setState(() => _spicyLevel = v),
                ),
                const SizedBox(height: 24),

                const Text('식단 목표', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: _fitnessGoalOptions.entries.map((e) {
                    final isSelected = _selectedFitnessGoal == e.key;
                    return ChoiceChip(
                      label: Text(e.value),
                      selected: isSelected,
                      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                      checkmarkColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      onSelected: (_) => setState(() => _selectedFitnessGoal = e.key),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                const Text('선호하는 음식 스타일 (복수 선택 가능)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: _foodPreferenceOptions.map((pref) {
                    final isSelected = _selectedFoodPreferences.contains(pref);
                    return FilterChip(
                      label: Text(pref),
                      selected: isSelected,
                      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                      checkmarkColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      onSelected: (bool selected) {
                        setState(() {
                          selected ? _selectedFoodPreferences.add(pref) : _selectedFoodPreferences.remove(pref);
                        });
                      },
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
                  decoration: InputDecoration(
                    hintText: '예: 제육볶음 같은 고기 요리가 좋아요. 국물 요리는 별로예요.',
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 32),

                _buildSectionTitle('3. 건강 상태 (해당 시 선택)'),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: _healthConditionOptions.map((condition) {
                    final isSelected = _selectedHealthConditions.contains(condition);
                    return FilterChip(
                      label: Text(condition),
                      selected: isSelected,
                      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                      checkmarkColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      onSelected: (bool selected) {
                        setState(() {
                          selected ? _selectedHealthConditions.add(condition) : _selectedHealthConditions.remove(condition);
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),

                _buildSectionTitle('4. 알레르기 유발 물질 (해당 시 선택)'),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: _allergyOptions.map((allergy) {
                    final isSelected = _selectedAllergies.contains(allergy);
                    return FilterChip(
                      label: Text(allergy),
                      selected: isSelected,
                      selectedColor: AppTheme.primaryColor.withOpacity(0.2), // 💡 선택 시 배경색 적용
                      checkmarkColor: AppTheme.primaryColor,                 // 💡 체크마크 색상 적용
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      onSelected: (bool selected) {
                        setState(() {
                          selected ? _selectedAllergies.add(allergy) : _selectedAllergies.remove(allergy);
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 48),

                // 💡 완료 버튼을 캡슐형 그라데이션 디자인으로 교체
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _isLoading ? Colors.grey.shade400 : null,
                    gradient: _isLoading ? null : AppTheme.aiGradient,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      if (!_isLoading)
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _finishOnboarding,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent, // 투명 처리해 뒤쪽 그라데이션 노출
                      shadowColor: Colors.transparent,     // 기본 그림자 제거
                      shape: const StadiumBorder(),
                      padding: EdgeInsets.zero,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            '정보 저장하고 시작하기', 
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)
                          ),
                  ),
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
        style: const TextStyle(
          fontSize: 18, 
          fontWeight: FontWeight.w900, 
          color: AppTheme.primaryColor // 💡 섹션 타이틀에 포인트 컬러 적용
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {String? suffix, String? hint, bool isNumber = true}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        filled: true,
        fillColor: Colors.white,
        // 💡 theme.dart의 16px 라운딩 규칙이 전역으로 적용됨
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return '필수 입력 항목입니다.';
        if (isNumber && double.tryParse(value) == null) return '숫자만 입력해 주세요.';
        return null;
      },
    );
  }
}