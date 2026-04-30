import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();

  // 1. users 테이블 정보
  final TextEditingController _nicknameController = TextEditingController();

  // 2. user_health_profiles 테이블 정보 (인바디)
  final TextEditingController _heightController = TextEditingController(); 
  final TextEditingController _weightController = TextEditingController(); 
  final TextEditingController _muscleController = TextEditingController(); 
  final TextEditingController _fatController = TextEditingController(); 
  final TextEditingController _bmrController = TextEditingController(); 
  final TextEditingController _inbodyScoreController = TextEditingController(); 

  // 3. user_preferences 테이블 정보 (예산)
  final TextEditingController _budgetController = TextEditingController(); 

  // 식습관 및 취향 상태 관리
  String _selectedVegType = 'NONE'; 
  double _spicyLevel = 3; 
  
  // 성별 선택 관리
  String? _selectedGender;
  
  // 알레르기 다중 선택 (user_allergies 테이블 매핑용)
  final Set<String> _selectedAllergies = {};
  
  // DB 도메인에 맞춘 마스터 데이터 옵션
  final Map<String, String> _vegOptions = {
    'NONE': '해당 없음',
    'VEGAN': '비건 (완전 채식)',
    'LACTO': '락토 (우유 허용)',
    'OVO': '오보 (계란 허용)',
    'PESCO': '페스코 (해산물 허용)'
  };
  
  final List<String> _allergyOptions = ['땅콩', '갑각류', '대두', '우유', '밀가루', '계란', '견과류', '생선'];

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

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final Map<String, dynamic> requestData = {
        'user': {
          'nickname': _nicknameController.text,
          'gender': _selectedGender == '남성' ? 'MALE' : 'FEMALE',
        },
        'health_profile': {
          'height': double.parse(_heightController.text),
          'weight': double.parse(_weightController.text),
          'skeletal_muscle_mass': double.parse(_muscleController.text),
          'body_fat_percentage': double.parse(_fatController.text),
          'bmr': int.parse(_bmrController.text),
          'inbody_score': int.parse(_inbodyScoreController.text),
        },
        'preference': {
          'meal_budget': int.parse(_budgetController.text),
          'vegetarian_type': _selectedVegType,
          'spicy_preference': _spicyLevel.toInt(),
        },
        'allergies': _selectedAllergies.toList(),
      };

      print('서버로 전송될 통합 데이터: $requestData');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('맞춤 추천을 위한 설정이 완료되었습니다!')),
      );

      // TODO: 저장 완료 후 홈 화면 이동 로직 추가
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필 및 설정', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('1. 기본 정보'),
                _buildTextField(
                  controller: _nicknameController,
                  label: '닉네임',
                  validatorMsg: '닉네임을 입력하세요',
                  isNumber: false,
                ),
                const SizedBox(height: 16),
                
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: '성별'),
                  value: _selectedGender,
                  items: ['남성', '여성'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedGender = newValue;
                    });
                  },
                  validator: (value) => value == null ? '성별을 선택해주세요' : null,
                ),

                const SizedBox(height: 30),

                _buildSectionHeader('2. 체성분 (InBody) 정보'),
                Row(
                  children: [
                    Expanded(child: _buildTextField(controller: _heightController, label: '키', suffixText: 'cm', validatorMsg: '입력 요망')),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField(controller: _weightController, label: '몸무게', suffixText: 'kg', validatorMsg: '입력 요망')),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildTextField(controller: _muscleController, label: '골격근량', suffixText: 'kg', validatorMsg: '입력 요망')),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField(controller: _fatController, label: '체지방률', suffixText: '%', validatorMsg: '입력 요망')),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildTextField(controller: _bmrController, label: '기초대사량', suffixText: 'kcal', validatorMsg: '입력 요망')),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField(controller: _inbodyScoreController, label: '인바디 점수', suffixText: '점', validatorMsg: '입력 요망')),
                  ],
                ),
                const SizedBox(height: 30),

                _buildSectionHeader('3. 식습관 및 예산 설정'),
                _buildTextField(
                  controller: _budgetController,
                  label: '끼니당 허용 예산',
                  suffixText: '원',
                  validatorMsg: '예산을 입력하세요 (예: 8000)',
                ),
                const SizedBox(height: 20),

                const Text('채식주의 단계 (Vegetarian Type)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: '채식 유형 선택'),
                  value: _selectedVegType,
                  items: _vegOptions.entries.map((entry) {
                    return DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedVegType = newValue!;
                    });
                  },
                ),
                const SizedBox(height: 24),

                const Text('매운맛 선호도 (1: 진라면 순한맛 ~ 5: 불닭볶음면)', style: TextStyle(fontWeight: FontWeight.bold)),
                Slider(
                  value: _spicyLevel,
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: _spicyLevel.toInt().toString(),
                  activeColor: Theme.of(context).primaryColor,
                  onChanged: (double value) {
                    setState(() {
                      _spicyLevel = value;
                    });
                  },
                ),
                const SizedBox(height: 30),

                _buildSectionHeader('4. 알레르기 유발 물질 (다중 선택)'),
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
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            _selectedAllergies.add(allergy);
                          } else {
                            _selectedAllergies.remove(allergy);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 40),

                // 최종 제출 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    child: const Text('가입 및 설정 완료', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 섹션 제목 위젯
  Widget _buildSectionHeader(String title) {
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

  // 텍스트 필드 공통 생성기 (숫자/문자 겸용)
  // suffixText를 선택적 파라미터로 변경 --> 닉네임 입력 시 빈 문자열을 넣지 않아도 됨
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? suffixText, 
    required String validatorMsg,
    bool isNumber = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffixText,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return validatorMsg;
        }
        if (isNumber && double.tryParse(value) == null) {
          return '숫자만 입력';
        }
        return null;
      },
    );
  }
}