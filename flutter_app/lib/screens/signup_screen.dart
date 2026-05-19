import 'package:flutter/material.dart';
import 'package:flutter_app/services/auth_service.dart';
import 'onboarding_screen.dart';
import 'package:flutter_app/theme.dart';

// 직접 가입 선택 후 회원가입을 진행하는 페이지입니다.

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  String? _selectedGender = '남성';
  bool _isLoading = false;

  void _submitSignup() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final response = await AuthService.signup(
        email: _emailController.text,
        password: _passwordController.text,
        nickname: _nicknameController.text,
        gender: _mapGenderToApiValue(_selectedGender),
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원가입 성공! 로그인을 진행해 주세요.')), // 문구 수정
        );

        // 가입 성공 시 로그인 화면으로
        Navigator.pop(context); 
        
        /* 만약 pop()으로 안 되는 라우팅 구조라면 명시적으로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
        */
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.error ?? '회원가입 실패했습니다.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('이메일로 가입하기', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'NUTRI Agent 가입을 위해\n정보를 입력해 주세요.', 
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.4)
                ),
                const SizedBox(height: 40),

                _buildTextField(
                  controller: _emailController,
                  label: '이메일 (아이디)',
                  hint: 'example@email.com',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return '이메일을 입력해 주세요.';
                    // 💡 이메일 형식 정규식 검사
                    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(value)) return '올바른 이메일 형식이 아닙니다.';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                _buildTextField(
                  controller: _passwordController,
                  label: '비밀번호',
                  hint: '영문, 숫자 포함 8자 이상',
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) return '비밀번호를 입력해 주세요.';
                    if (value.length < 8) return '비밀번호는 8자 이상이어야 합니다.';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                _buildTextField(
                  controller: _passwordConfirmController,
                  label: '비밀번호 확인',
                  hint: '위에 입력한 비밀번호와 동일하게 입력해 주세요',
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) return '비밀번호 확인을 입력해 주세요.';
                    if (value != _passwordController.text) return '비밀번호가 일치하지 않습니다.';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                _buildTextField(
                  controller: _nicknameController,
                  label: '닉네임',
                  hint: '사용할 닉네임을 입력해 주세요',
                  validator: (value) {
                    if (value == null || value.isEmpty) return '닉네임을 입력해 주세요.';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: '성별',
                    hintText: '성별을 선택해 주세요',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    // 💡 라운딩 16px 통일
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    // 💡 포커스 시 테두리 색상을 AppTheme.primaryColor 로 통일
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                  value: _selectedGender,
                  onChanged: (v) => setState(() => _selectedGender = v),
                  items: const [
                    DropdownMenuItem(value: '남성', child: Text('남성')),
                    DropdownMenuItem(value: '여성', child: Text('여성')),
                  ],
                  validator: (v) {
                    if (v == null || v.isEmpty) return '성별을 선택해 주세요.';
                    return null;
                  },
                ),
                const SizedBox(height: 40),

                // 💡 가입 완료 버튼: 캡슐형 그라데이션 적용
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
                    onPressed: _isLoading ? null : _submitSignup,
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
                            '가입 완료하기', 
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 💡 TextField 공통 위젯도 16px 라운딩 및 AppTheme 색상으로 업데이트
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), 
          borderSide: BorderSide.none
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), 
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2)
        ),
      ),
      validator: validator,
    );
  }

  String? _mapGenderToApiValue(String? uiGender) {
    if (uiGender == null) return null;
    if (uiGender == '남성') return 'MALE';
    if (uiGender == '여성') return 'FEMALE';
    return null;
  }
}