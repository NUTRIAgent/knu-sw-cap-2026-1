import 'package:flutter/material.dart';
import 'package:flutter_app/services/auth_service.dart';
import 'package:flutter_app/theme.dart';

// 비밀번호 찾기(재설정) — 이메일 인증코드 확인 후 새 비밀번호를 설정하는 페이지입니다.
// 단계: 1) 이메일 입력 → 코드 발송  2) 인증코드 확인  3) 새 비밀번호 설정
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController = TextEditingController();

  bool _isLoading = false;
  bool _codeSent = false; // 인증코드 발송 완료
  bool _codeVerified = false; // 인증코드 확인 완료 → 새 비밀번호 입력 단계

  // 회원가입과 동일한 비밀번호 정책
  static final RegExp _passwordRegex =
      RegExp(r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[^A-Za-z0-9\s])\S+$');

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showSnackBar('올바른 이메일을 먼저 입력해 주세요.');
      return;
    }

    setState(() => _isLoading = true);
    final error = await AuthService.requestPasswordCode(email);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (error == null) _codeSent = true;
    });

    _showSnackBar(error ?? '인증코드를 발송했습니다. 메일함을 확인해 주세요.');
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      _showSnackBar('인증코드를 입력해 주세요.');
      return;
    }

    setState(() => _isLoading = true);
    final error =
        await AuthService.verifyPasswordCode(_emailController.text.trim(), code);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (error == null) _codeVerified = true;
    });

    _showSnackBar(error ?? '인증이 완료되었습니다. 새 비밀번호를 입력해 주세요.');
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final error = await AuthService.resetPassword(
      _emailController.text.trim(),
      _codeController.text.trim(),
      _passwordController.text,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      _showSnackBar(error);
      return;
    }

    // 성공 — 로그인 화면으로 복귀
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('비밀번호 변경 완료'),
        content: const Text('비밀번호가 변경되었습니다.\n새 비밀번호로 로그인해 주세요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('확인'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('비밀번호 찾기', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  '가입한 이메일로 인증코드를 보내드려요.',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.4),
                ),
                const SizedBox(height: 40),

                // 1단계 — 이메일 입력 + 코드 발송
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !_codeVerified,
                        decoration: _inputDecoration('이메일', 'example@email.com'),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty) ? '이메일을 입력해 주세요.' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 56,
                      child: OutlinedButton(
                        onPressed: (_isLoading || _codeVerified) ? null : _sendCode,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          side: const BorderSide(color: AppTheme.primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(_codeSent ? '재발송' : '코드 발송'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 2단계 — 인증코드 입력 + 확인
                if (_codeSent && !_codeVerified) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: _inputDecoration('인증코드', '6자리 숫자')
                              .copyWith(counterText: ''),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 56,
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : _verifyCode,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                            side: const BorderSide(color: AppTheme.primaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('확인'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '인증코드는 5분간 유효합니다.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                ],

                // 3단계 — 새 비밀번호 입력
                if (_codeVerified) ...[
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration:
                        _inputDecoration('새 비밀번호', '영문, 숫자, 특수문자 포함 8자 이상'),
                    validator: (value) {
                      if (value == null || value.isEmpty) return '새 비밀번호를 입력해 주세요.';
                      if (value.length < 8 || value.length > 64) {
                        return '비밀번호는 8자 이상 64자 이하여야 합니다.';
                      }
                      if (!_passwordRegex.hasMatch(value)) {
                        return '영문, 숫자, 특수문자를 각각 1자 이상 포함해야 합니다.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordConfirmController,
                    obscureText: true,
                    decoration: _inputDecoration('새 비밀번호 확인', '동일하게 입력해 주세요'),
                    validator: (value) {
                      if (value == null || value.isEmpty) return '비밀번호 확인을 입력해 주세요.';
                      if (value != _passwordController.text) return '비밀번호가 일치하지 않습니다.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
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
                      onPressed: _isLoading ? null : _resetPassword,
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
                              '비밀번호 재설정',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }
}
