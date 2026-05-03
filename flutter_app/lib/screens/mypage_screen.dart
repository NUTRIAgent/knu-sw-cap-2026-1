import 'package:flutter/material.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  final _formKey = GlobalKey<FormState>();

  // 1. 기본 정보 컨트롤러
  final TextEditingController _nicknameController = TextEditingController(text: "김철수"); // 초기값 예시
  String? _selectedGender = '남성';

  // 2. 인바디 정보 컨트롤러
  final TextEditingController _heightController = TextEditingController(text: "175");
  final TextEditingController _weightController = TextEditingController(text: "70");
  final TextEditingController _muscleController = TextEditingController(text: "35");
  final TextEditingController _fatController = TextEditingController(text: "15");
  final TextEditingController _bmrController = TextEditingController(text: "1600");
  final TextEditingController _inbodyScoreController = TextEditingController(text: "80");

  // 3. 식습관 및 예산 컨트롤러
  final TextEditingController _budgetController = TextEditingController(text: "8000");
  String _selectedVegType = 'NONE';
  double _spicyLevel = 3;

  // 4. 알레르기 정보
  final Set<String> _selectedAllergies = {'우유', '밀가루'}; // 초기값 예시
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

  // 수정된 정보 저장 로직
  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      final updatedData = {
        'nickname': _nicknameController.text,
        'gender': _selectedGender,
        'health': {
          'height': _heightController.text,
          'weight': _weightController.text,
          'muscle': _muscleController.text,
          'fat': _fatController.text,
          'bmr': _bmrController.text,
          'score': _inbodyScoreController.text,
        },
        'preference': {
          'budget': _budgetController.text,
          'vegType': _selectedVegType,
          'spicy': _spicyLevel.toInt(),
        },
        'allergies': _selectedAllergies.toList(),
      };

      print('수정된 프로필 데이터: $updatedData');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('프로필 정보가 수정되었습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('마이페이지', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text('저장', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('기본 정보 수정'),
              _buildTextField(_nicknameController, '닉네임', isNumber: false),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: '성별'),
                value: _selectedGender,
                items: ['남성', '여성'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => _selectedGender = v),
              ),
              const SizedBox(height: 32),

              _buildSectionTitle('인바디 정보 수정'),
              Row(
                children: [
                  Expanded(child: _buildTextField(_heightController, '키', suffix: 'cm')),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField(_weightController, '몸무게', suffix: 'kg')),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildTextField(_muscleController, '골격근량', suffix: 'kg')),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField(_fatController, '체지방률', suffix: '%')),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildTextField(_bmrController, '기초대사량', suffix: 'kcal')),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField(_inbodyScoreController, '인바디 점수', suffix: '점')),
                ],
              ),
              const SizedBox(height: 32),

              _buildSectionTitle('식습관 및 예산 수정'),
              _buildTextField(_budgetController, '끼니당 예산', suffix: '원'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: '채식 유형'),
                value: _selectedVegType,
                items: _vegOptions.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                onChanged: (v) => setState(() => _selectedVegType = v!),
              ),
              const SizedBox(height: 16),
              Text('매운맛 선호도 (${_spicyLevel.toInt()}단계)', style: const TextStyle(fontWeight: FontWeight.w500)),
              Slider(
                value: _spicyLevel,
                min: 1, max: 5, divisions: 4,
                onChanged: (v) => setState(() => _spicyLevel = v),
              ),
              const SizedBox(height: 32),

              _buildSectionTitle('알레르기 정보 수정'),
              Wrap(
                spacing: 8,
                children: _allergyOptions.map((allergy) {
                  final isSelected = _selectedAllergies.contains(allergy);
                  return FilterChip(
                    label: Text(allergy),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() {
                        selected ? _selectedAllergies.add(allergy) : _selectedAllergies.remove(allergy);
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),
              
              ElevatedButton(
                onPressed: _saveProfile,
                child: const Text('수정완료', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {String? suffix, bool isNumber = true}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(labelText: label, suffixText: suffix),
      validator: (v) => (v == null || v.isEmpty) ? '필수 입력 항목입니다.' : null,
    );
  }
}