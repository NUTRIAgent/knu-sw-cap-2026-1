import 'package:flutter/material.dart';
import 'onboarding_screen.dart';

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
  final TextEditingController _nicknameController = TextEditingController();

  void _submitSignup() {
    if (_formKey.currentState!.validate()) {
      // 백엔드 전송용 데이터 맵핑 (이슈 명세 준수)
      final signupData = {
        'email': _emailController.text,
        'password': _passwordController.text,
        'nickname': _nicknameController.text,
        'role': 'USER', // 기본값
        'provider': null, // 직접 가입이므로 null
        'providerId': null,
      };

      print('회원가입 요청 데이터: $signupData');
      // TODO: 백엔드 API 연동 (POST /api/v1/auth/signup)

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('회원가입 성공! 추가 정보를 입력해주세요.')),
      );

      // 가입 성공 시 온보딩(기초 정보 입력) 페이지로 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
                const Text('NUTRI Agent 가입을 위해\n정보를 입력해 주세요.', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.4)),
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
                  controller: _nicknameController,
                  label: '닉네임',
                  hint: '사용할 닉네임을 입력해 주세요',
                  validator: (value) {
                    if (value == null || value.isEmpty) return '닉네임을 입력해 주세요.';
                    return null;
                  },
                ),
                const SizedBox(height: 40),

                ElevatedButton(
                  onPressed: _submitSignup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8CA384),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('가입 완료하기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF8CA384), width: 2)),
      ),
      validator: validator,
    );
  }
}