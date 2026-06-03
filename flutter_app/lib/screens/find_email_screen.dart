import 'package:flutter/material.dart';
import 'package:flutter_app/services/auth_service.dart';
import 'package:flutter_app/theme.dart';

// 아이디(이메일) 찾기 — 가입 시 등록한 휴대폰 번호로 마스킹된 이메일을 조회하는 페이지입니다.
class FindEmailScreen extends StatefulWidget {
  const FindEmailScreen({super.key});

  @override
  State<FindEmailScreen> createState() => _FindEmailScreenState();
}

class _FindEmailScreenState extends State<FindEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();

  bool _isLoading = false;
  String? _maskedEmail; // 조회 성공 시 마스킹된 이메일

  static final RegExp _phoneRegex = RegExp(r'^01[016789]\d{7,8}$');

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _maskedEmail = null;
    });

    final phone = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final result = await AuthService.findEmail(phone);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _maskedEmail = result.maskedEmail;
    });

    if (result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error!)),
      );
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('아이디 찾기', style: TextStyle(fontWeight: FontWeight.bold)),
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
                const Text(
                  '가입할 때 등록한 휴대폰 번호를\n입력해 주세요.',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.4),
                ),
                const SizedBox(height: 40),

                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: '휴대폰 번호',
                    hintText: '숫자만 입력 (예: 01012345678)',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    final phone = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                    if (phone.isEmpty) return '휴대폰 번호를 입력해 주세요.';
                    if (!_phoneRegex.hasMatch(phone)) return '올바른 휴대폰 번호 형식이 아닙니다.';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // 로그인 버튼과 동일한 그라데이션 캡슐형 디자인
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
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent, // 뒤쪽 그라데이션 노출
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
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
                            '아이디 찾기',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(height: 32),

                // 조회 결과 — 마스킹된 이메일 표시
                if (_maskedEmail != null)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '회원님의 아이디(이메일)는',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _maskedEmail!,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '입니다.',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
