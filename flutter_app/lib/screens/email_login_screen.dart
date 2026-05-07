import 'package:flutter/material.dart';
import 'main_screen.dart';

// 직접 로그인을 진행하는 페이지입니다. (소셜로그인X)

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _submitLogin() {
    if (_formKey.currentState!.validate()) {
      final loginData = {
        'email': _emailController.text,
        'password': _passwordController.text,
      };

      print('로그인 요청: $loginData');
      // TODO: 백엔드 API 연동 (POST /api/v1/auth/login)
      
      // 로그인 성공 시 온보딩을 건너뛰고 바로 대시보드로 이동
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
        (route) => false, // 이전 로그인/가입 화면 라우팅 스택 모두 제거
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('로그인', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('다시 오신 것을 환영합니다!\n계정 정보를 입력해 주세요.', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.4)),
                const SizedBox(height: 40),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: '이메일',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  validator: (value) => (value == null || value.isEmpty) ? '이메일을 입력해 주세요.' : null,
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: '비밀번호',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  validator: (value) => (value == null || value.isEmpty) ? '비밀번호를 입력해 주세요.' : null,
                ),
                const SizedBox(height: 40),

                ElevatedButton(
                  onPressed: _submitLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8CA384),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('로그인하기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}