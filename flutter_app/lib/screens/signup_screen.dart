import 'package:flutter/material.dart';
import 'package:flutter_app/services/auth_service.dart';
import 'onboarding_screen.dart';
import 'package:flutter_app/theme.dart';

// 직접 가입 선택 후 회원가입을 진행하는 페이지입니다.

// 서버(SignupRequest) 비밀번호 정책과 동일하게 유지 — 입력 검증과 체크리스트가 공유
final RegExp _letterRegex = RegExp(r'[A-Za-z]');
final RegExp _digitRegex = RegExp(r'\d');
final RegExp _specialCharRegex = RegExp(r'[^A-Za-z0-9\s]');
final RegExp _whitespaceRegex = RegExp(r'\s');

// 이메일/닉네임 중복확인 상태
enum _DuplicateCheckStatus { unchecked, checking, available, taken }

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
  String? _selectedGender; // 명시적 선택 유도를 위해 기본값 없음
  bool _isLoading = false;

  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;
  String _password = ''; // 비밀번호 조건 체크리스트 실시간 갱신용

  _DuplicateCheckStatus _emailCheckStatus = _DuplicateCheckStatus.unchecked;
  String? _checkedEmail; // 중복확인을 통과한 시점의 값 (입력이 바뀌면 재확인 필요)
  _DuplicateCheckStatus _nicknameCheckStatus = _DuplicateCheckStatus.unchecked;
  String? _checkedNickname;

  bool _agreeServiceTerms = false;
  bool _agreePrivacyPolicy = false;

  static final RegExp _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  bool _isPasswordValid(String value) {
    return value.length >= 8 &&
        value.length <= 64 &&
        _letterRegex.hasMatch(value) &&
        _digitRegex.hasMatch(value) &&
        _specialCharRegex.hasMatch(value) &&
        !_whitespaceRegex.hasMatch(value);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _checkEmailDuplicate() async {
    final email = _emailController.text.trim();
    if (!_emailRegex.hasMatch(email)) {
      _showSnackBar('올바른 이메일을 먼저 입력해 주세요.');
      return;
    }

    setState(() => _emailCheckStatus = _DuplicateCheckStatus.checking);

    final exists = await AuthService.checkEmailExists(email);
    if (!mounted) return;

    if (exists == null) {
      setState(() => _emailCheckStatus = _DuplicateCheckStatus.unchecked);
      _showSnackBar('중복확인에 실패했습니다. 잠시 후 다시 시도해 주세요.');
      return;
    }

    setState(() {
      _emailCheckStatus =
          exists ? _DuplicateCheckStatus.taken : _DuplicateCheckStatus.available;
      _checkedEmail = email;
    });
  }

  Future<void> _checkNicknameDuplicate() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.length < 2 || nickname.length > 20) {
      _showSnackBar('닉네임은 2자 이상 20자 이하로 먼저 입력해 주세요.');
      return;
    }

    setState(() => _nicknameCheckStatus = _DuplicateCheckStatus.checking);

    final exists = await AuthService.checkNicknameExists(nickname);
    if (!mounted) return;

    if (exists == null) {
      setState(() => _nicknameCheckStatus = _DuplicateCheckStatus.unchecked);
      _showSnackBar('중복확인에 실패했습니다. 잠시 후 다시 시도해 주세요.');
      return;
    }

    setState(() {
      _nicknameCheckStatus =
          exists ? _DuplicateCheckStatus.taken : _DuplicateCheckStatus.available;
      _checkedNickname = nickname;
    });
  }

  bool get _isEmailCheckPassed =>
      _emailCheckStatus == _DuplicateCheckStatus.available &&
      _checkedEmail == _emailController.text.trim();

  bool get _isNicknameCheckPassed =>
      _nicknameCheckStatus == _DuplicateCheckStatus.available &&
      _checkedNickname == _nicknameController.text.trim();

  void _submitSignup() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreeServiceTerms || !_agreePrivacyPolicy) {
      _showSnackBar('필수 약관에 동의해 주세요.');
      return;
    }

    if (!_isEmailCheckPassed) {
      _showSnackBar('이메일 중복확인을 해주세요.');
      return;
    }
    if (!_isNicknameCheckPassed) {
      _showSnackBar('닉네임 중복확인을 해주세요.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final response = await AuthService.signup(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      nickname: _nicknameController.text.trim(),
      gender: _mapGenderToApiValue(_selectedGender),
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (response.success) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('회원가입 완료'),
          content: const Text('회원가입이 완료되었습니다.\n프로필 설정을 진행해 주세요.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('시작하기'),
            ),
          ],
        ),
      );

      if (!mounted) return;

      // 가입 시 발급된 토큰으로 자동 로그인 처리 → 신규 유저는 온보딩으로 이동 (뒤로 가기 방지)
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        (route) => false,
      );
    } else {
      _showSnackBar(response.error ?? '회원가입 실패했습니다.');
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
          // 검증은 각 필드의 autovalidateMode(onUserInteraction)에서 개별 수행
          // (Form 레벨 설정 시 한 필드 입력만으로 모든 필드가 검증되는 문제가 있음)
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

                _buildFieldWithCheckButton(
                  field: _buildTextField(
                    controller: _emailController,
                    label: '이메일 (아이디)',
                    hint: 'example@email.com',
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (value) {
                      // 입력이 바뀌면 중복확인 상태 초기화
                      if (_checkedEmail != value.trim() &&
                          _emailCheckStatus != _DuplicateCheckStatus.unchecked) {
                        setState(() => _emailCheckStatus = _DuplicateCheckStatus.unchecked);
                      }
                    },
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      if (email.isEmpty) return '이메일을 입력해 주세요.';
                      if (!_emailRegex.hasMatch(email)) return '올바른 이메일 형식이 아닙니다.';
                      return null;
                    },
                  ),
                  status: _emailCheckStatus,
                  isCheckPassed: _isEmailCheckPassed,
                  onCheck: _checkEmailDuplicate,
                ),
                _DuplicateCheckStatusText(
                  status: _emailCheckStatus,
                  availableText: '사용 가능한 이메일입니다.',
                  takenText: '이미 사용 중인 이메일입니다.',
                ),
                const SizedBox(height: 20),

                _buildTextField(
                  controller: _passwordController,
                  label: '비밀번호',
                  hint: '영문, 숫자, 특수문자 포함 8자 이상',
                  obscureText: _obscurePassword,
                  suffixIcon: _buildObscureToggle(
                    isObscured: _obscurePassword,
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  onChanged: (value) => setState(() => _password = value),
                  validator: (value) {
                    if (value == null || value.isEmpty) return '비밀번호를 입력해 주세요.';
                    if (_whitespaceRegex.hasMatch(value)) return '비밀번호에 공백은 사용할 수 없습니다.';
                    if (!_isPasswordValid(value)) return '아래 비밀번호 조건을 모두 충족해야 합니다.';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                _PasswordRequirementsChecklist(password: _password),
                const SizedBox(height: 20),

                _buildTextField(
                  controller: _passwordConfirmController,
                  label: '비밀번호 확인',
                  hint: '위에 입력한 비밀번호와 동일하게 입력해 주세요',
                  obscureText: _obscurePasswordConfirm,
                  suffixIcon: _buildObscureToggle(
                    isObscured: _obscurePasswordConfirm,
                    onPressed: () => setState(
                        () => _obscurePasswordConfirm = !_obscurePasswordConfirm),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return '비밀번호 확인을 입력해 주세요.';
                    if (value != _passwordController.text) return '비밀번호가 일치하지 않습니다.';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                _buildFieldWithCheckButton(
                  field: _buildTextField(
                    controller: _nicknameController,
                    label: '닉네임',
                    hint: '2~20자 닉네임을 입력해 주세요',
                    onChanged: (value) {
                      if (_checkedNickname != value.trim() &&
                          _nicknameCheckStatus != _DuplicateCheckStatus.unchecked) {
                        setState(() => _nicknameCheckStatus = _DuplicateCheckStatus.unchecked);
                      }
                    },
                    validator: (value) {
                      final nickname = value?.trim() ?? '';
                      if (nickname.isEmpty) return '닉네임을 입력해 주세요.';
                      if (nickname.length < 2 || nickname.length > 20) {
                        return '닉네임은 2자 이상 20자 이하여야 합니다.';
                      }
                      return null;
                    },
                  ),
                  status: _nicknameCheckStatus,
                  isCheckPassed: _isNicknameCheckPassed,
                  onCheck: _checkNicknameDuplicate,
                ),
                _DuplicateCheckStatusText(
                  status: _nicknameCheckStatus,
                  availableText: '사용 가능한 닉네임입니다.',
                  takenText: '이미 사용 중인 닉네임입니다.',
                ),
                const SizedBox(height: 20),

                DropdownButtonFormField<String>(
                  // 사용자가 직접 선택한 경우에만 실시간 검증
                  autovalidateMode: AutovalidateMode.onUserInteraction,
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
                  initialValue: _selectedGender,
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
                const SizedBox(height: 24),

                _TermsAgreementSection(
                  agreeServiceTerms: _agreeServiceTerms,
                  agreePrivacyPolicy: _agreePrivacyPolicy,
                  onServiceTermsChanged: (v) => setState(() => _agreeServiceTerms = v),
                  onPrivacyPolicyChanged: (v) => setState(() => _agreePrivacyPolicy = v),
                  onAllChanged: (v) => setState(() {
                    _agreeServiceTerms = v;
                    _agreePrivacyPolicy = v;
                  }),
                ),
                const SizedBox(height: 32),

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
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
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

  // 입력 필드 + 중복확인 버튼을 한 줄로 배치
  Widget _buildFieldWithCheckButton({
    required Widget field,
    required _DuplicateCheckStatus status,
    required bool isCheckPassed,
    required VoidCallback onCheck,
  }) {
    final isChecking = status == _DuplicateCheckStatus.checking;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: field),
        const SizedBox(width: 8),
        SizedBox(
          height: 56,
          child: OutlinedButton(
            onPressed: (isChecking || isCheckPassed) ? null : onCheck,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              side: const BorderSide(color: AppTheme.primaryColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: isChecking
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(isCheckPassed ? '확인 완료' : '중복확인'),
          ),
        ),
      ],
    );
  }

  Widget _buildObscureToggle({
    required bool isObscured,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(
        isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: Colors.grey,
      ),
      onPressed: onPressed,
    );
  }

  // 💡 TextField 공통 위젯도 16px 라운딩 및 AppTheme 색상으로 업데이트
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    ValueChanged<String>? onChanged,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      // 사용자가 직접 입력한 필드만 실시간 검증
      // (비밀번호 확인 일치 검사는 비밀번호 onChanged의 setState 리빌드로 함께 갱신됨)
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: suffixIcon,
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

// 약관 동의 섹션 — 전체 동의 + 필수 약관 2건
class _TermsAgreementSection extends StatelessWidget {
  final bool agreeServiceTerms;
  final bool agreePrivacyPolicy;
  final ValueChanged<bool> onServiceTermsChanged;
  final ValueChanged<bool> onPrivacyPolicyChanged;
  final ValueChanged<bool> onAllChanged;

  const _TermsAgreementSection({
    required this.agreeServiceTerms,
    required this.agreePrivacyPolicy,
    required this.onServiceTermsChanged,
    required this.onPrivacyPolicyChanged,
    required this.onAllChanged,
  });

  bool get _isAllAgreed => agreeServiceTerms && agreePrivacyPolicy;

  void _showTermsDialog(BuildContext context, String title, String content) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(content, style: const TextStyle(fontSize: 14, height: 1.6)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          _AgreementRow(
            label: '전체 동의',
            isBold: true,
            value: _isAllAgreed,
            onChanged: onAllChanged,
          ),
          const Divider(height: 1),
          _AgreementRow(
            label: '(필수) 서비스 이용약관 동의',
            value: agreeServiceTerms,
            onChanged: onServiceTermsChanged,
            onViewPressed: () =>
                _showTermsDialog(context, '서비스 이용약관', _serviceTermsContent),
          ),
          _AgreementRow(
            label: '(필수) 개인정보 수집·이용 동의',
            value: agreePrivacyPolicy,
            onChanged: onPrivacyPolicyChanged,
            onViewPressed: () =>
                _showTermsDialog(context, '개인정보 수집·이용 동의', _privacyPolicyContent),
          ),
        ],
      ),
    );
  }
}

class _AgreementRow extends StatelessWidget {
  final String label;
  final bool isBold;
  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onViewPressed;

  const _AgreementRow({
    required this.label,
    this.isBold = false,
    required this.value,
    required this.onChanged,
    this.onViewPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => onChanged(!value),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 22,
                    color: value ? AppTheme.primaryColor : Colors.grey.shade400,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (onViewPressed != null)
          TextButton(
            onPressed: onViewPressed,
            child: const Text('보기', style: TextStyle(fontSize: 13, color: Colors.grey)),
          ),
      ],
    );
  }
}

// 서비스 이용약관 (NUTRI Agent — AI 식단/레시피 추천 서비스)
const String _serviceTermsContent = '''
제1조 (목적)
본 약관은 NUTRI Agent(이하 "서비스")가 제공하는 AI 기반 식단·레시피 추천 서비스의 이용 조건 및 절차를 규정합니다.

제2조 (회원의 의무)
1. 회원은 가입 시 본인의 정확한 정보를 제공해야 하며, 타인의 정보를 도용할 수 없습니다.
2. 계정 및 비밀번호의 관리 책임은 회원 본인에게 있습니다.

제3조 (서비스 내용)
1. 서비스는 회원의 신체 정보와 식품 선호를 바탕으로 맞춤형 식단·레시피 추천, 식재료 시세 및 날씨 기반 정보를 제공합니다.
2. AI가 제공하는 추천 결과는 참고용 정보이며, 의학적 진단·처방을 대체하지 않습니다. 질환이 있거나 특수한 식이 관리가 필요한 경우 전문가와 상담하시기 바랍니다.

제4조 (서비스 이용 제한)
부정한 방법으로 서비스를 이용하거나 서비스 운영을 방해하는 경우 이용이 제한될 수 있습니다.
''';

// 개인정보 수집·이용 동의 문구
const String _privacyPolicyContent = '''
NUTRI Agent는 회원가입 및 서비스 제공을 위해 아래와 같이 개인정보를 수집·이용합니다.

1. 수집 항목
- 필수: 이메일, 비밀번호, 닉네임, 성별
- 서비스 이용 과정에서 수집: 신체 정보(키, 몸무게 등), 식품 선호·알레르기 정보, 위치 정보(날씨·주변 시세 연동 시)

2. 수집 목적
- 회원 식별 및 계정 관리
- 맞춤형 식단·레시피 추천 제공
- 식재료 가격, 날씨 등 생활 정보 제공

3. 보유 및 이용 기간
- 회원 탈퇴 시까지 보유하며, 탈퇴 시 지체 없이 파기합니다. (관계 법령에 따라 보관이 필요한 정보는 해당 기간 동안 보관)

4. 동의 거부 권리
- 동의를 거부할 권리가 있으나, 필수 항목 동의를 거부할 경우 회원가입이 제한됩니다.
''';

// 중복확인 결과를 필드 아래에 색상으로 표시
class _DuplicateCheckStatusText extends StatelessWidget {
  final _DuplicateCheckStatus status;
  final String availableText;
  final String takenText;

  const _DuplicateCheckStatusText({
    required this.status,
    required this.availableText,
    required this.takenText,
  });

  @override
  Widget build(BuildContext context) {
    if (status != _DuplicateCheckStatus.available &&
        status != _DuplicateCheckStatus.taken) {
      return const SizedBox.shrink();
    }

    final isAvailable = status == _DuplicateCheckStatus.available;
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Text(
        isAvailable ? availableText : takenText,
        style: TextStyle(
          fontSize: 13,
          color: isAvailable ? Colors.green : Colors.red,
        ),
      ),
    );
  }
}

// 비밀번호 조건 체크리스트 — 입력하면서 충족된 항목의 색이 바뀜
class _PasswordRequirementsChecklist extends StatelessWidget {
  final String password;

  const _PasswordRequirementsChecklist({required this.password});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RequirementRow(
          label: '8자 이상 (최대 64자)',
          isMet: password.length >= 8 && password.length <= 64,
        ),
        _RequirementRow(
          label: '영문 포함',
          isMet: _letterRegex.hasMatch(password),
        ),
        _RequirementRow(
          label: '숫자 포함',
          isMet: _digitRegex.hasMatch(password),
        ),
        _RequirementRow(
          label: '특수문자 포함',
          isMet: _specialCharRegex.hasMatch(password),
        ),
      ],
    );
  }
}

class _RequirementRow extends StatelessWidget {
  final String label;
  final bool isMet;

  const _RequirementRow({required this.label, required this.isMet});

  @override
  Widget build(BuildContext context) {
    final color = isMet ? Colors.green : Colors.grey;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 13, color: color)),
        ],
      ),
    );
  }
}
