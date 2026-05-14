import 'package:flutter/material.dart';
import 'main_screen.dart'; 
import 'package:flutter_app/models/user_profile_models.dart';
import 'package:flutter_app/services/user_profile_service.dart';

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
  String _selectedVegType = 'NONE';
  double _spicyLevel = 3;

  // 3. 알레르기 정보
  final Set<String> _selectedAllergies = {};
  
  final List<String> _allergyOptions = ['땅콩', '갑각류', '대두', '우유', '밀가루', '계란', '견과류', '생선'];
  final Map<String, String> _vegOptions = {
    'NONE': '해당 없음',
    'VEGAN': '비건 (완전 채식)',
    'LACTO': '락토 (우유 허용)',
    'OVO': '오보 (계란 허용)',
    'PESCO': '페스코 (해산물 허용)'
  };

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _muscleController.dispose();
    _fatController.dispose();
    _bmrController.dispose();
    _inbodyScoreController.dispose();
    _budgetController.dispose();
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
        allergies: _selectedAllergies.toList(),
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
                  'NUTRI Agent에 오신 것을 환영합니다!\nAI가 완벽한 맞춤 식단을 추천해 드릴 수 있도록\n아래 정보를 정확하게 입력해 주세요.',
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
                  decoration: const InputDecoration(labelText: '채식 유형 선택', filled: true, fillColor: Colors.white),
                  value: _selectedVegType,
                  onChanged: (v) => setState(() => _selectedVegType = v!),
                  items: _vegOptions.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                ),
                const SizedBox(height: 24),
                Text('매운맛 선호도 (${_spicyLevel.toInt()}단계)', style: const TextStyle(fontWeight: FontWeight.bold)),
                Slider(
                  value: _spicyLevel,
                  min: 1, max: 5, divisions: 4,
                  activeColor: Theme.of(context).primaryColor,
                  onChanged: (v) => setState(() => _spicyLevel = v),
                ),
                const SizedBox(height: 32),

                _buildSectionTitle('3. 알레르기 유발 물질 (해당 시 선택)'),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: _allergyOptions.map((allergy) {
                    final isSelected = _selectedAllergies.contains(allergy);
                    return FilterChip(
                      label: Text(allergy),
                      selected: isSelected,
                      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                      checkmarkColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300),
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

                ElevatedButton(
                  onPressed: _isLoading ? null : _finishOnboarding,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('정보 저장하고 시작하기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Theme.of(context).primaryColor),
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
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return '필수 입력 항목입니다.';
        if (isNumber && double.tryParse(value) == null) return '숫자만 입력해 주세요.';
        return null;
      },
    );
  }
}