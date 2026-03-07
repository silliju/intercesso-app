import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _nickCtrl = TextEditingController();
  final _churchCtrl = TextEditingController();
  bool _obscurePw = true;
  bool _agreeTerms = false;
  bool _agreePrivacy = false;

  static final String _termsUrl = AppConstants.termsUrl;
  static final String _privacyUrl = AppConstants.privacyUrl;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    _nickCtrl.dispose();
    _churchCtrl.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreeTerms || !_agreePrivacy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이용약관과 개인정보처리방침에 동의해주세요'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final ok = await auth.signUp(
      email: _emailCtrl.text.trim(),
      password: _pwCtrl.text,
      nickname: _nickCtrl.text.trim(),
      churchName: _churchCtrl.text.isEmpty ? null : _churchCtrl.text.trim(),
    );
    if (ok && mounted) {
      context.go('/home');
    } else if (mounted && auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error!),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      auth.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLoading = auth.state == AuthState.loading;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.go('/login'),
        ),
        title: const Text('회원가입'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        height: 1.3),
                    children: [
                      TextSpan(text: '계정을 '),
                      TextSpan(text: '만들어', style: TextStyle(color: AppTheme.primary)),
                      TextSpan(text: '\n기도를 시작해보세요'),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── 이메일
                      _label('이메일'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'example@email.com',
                          prefixIcon: Icon(Icons.email_outlined, color: AppTheme.textLight, size: 20),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return '이메일을 입력해주세요';
                          if (!v.contains('@')) return '올바른 이메일 형식이 아닙니다';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      // ── 비밀번호
                      _label('비밀번호'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _pwCtrl,
                        obscureText: _obscurePw,
                        decoration: InputDecoration(
                          hintText: '6자 이상',
                          prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.textLight, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                                _obscurePw
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppTheme.textLight,
                                size: 20),
                            onPressed: () => setState(() => _obscurePw = !_obscurePw),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return '비밀번호를 입력해주세요';
                          if (v.length < 6) return '비밀번호는 6자 이상이어야 합니다';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      // ── 닉네임
                      _label('닉네임'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nickCtrl,
                        decoration: const InputDecoration(
                          hintText: '앱에서 표시될 이름 (한글 OK)',
                          prefixIcon: Icon(Icons.person_outline, color: AppTheme.textLight, size: 20),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return '닉네임을 입력해주세요';
                          if (v.length < 2) return '닉네임은 2자 이상이어야 합니다';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      // ── 교회명 (선택)
                      Row(children: [
                        _label('교회명'),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                              color: AppTheme.primaryLight,
                              borderRadius: BorderRadius.circular(8)),
                          child: const Text('선택',
                              style: TextStyle(fontSize: 11, color: AppTheme.primary)),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _churchCtrl,
                        decoration: const InputDecoration(
                          hintText: '출석 교회 이름 (선택사항)',
                          prefixIcon: Icon(Icons.church_outlined, color: AppTheme.textLight, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── 약관 동의 섹션
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: (!_agreeTerms || !_agreePrivacy)
                          ? AppTheme.border
                          : AppTheme.primary.withOpacity(0.4),
                    ),
                  ),
                  child: Column(
                    children: [
                      // 전체 동의
                      InkWell(
                        onTap: () {
                          final allChecked = _agreeTerms && _agreePrivacy;
                          setState(() {
                            _agreeTerms = !allChecked;
                            _agreePrivacy = !allChecked;
                          });
                        },
                        child: Row(
                          children: [
                            Icon(
                              (_agreeTerms && _agreePrivacy)
                                  ? Icons.check_circle_rounded
                                  : Icons.check_circle_outline_rounded,
                              color: (_agreeTerms && _agreePrivacy)
                                  ? AppTheme.primary
                                  : AppTheme.textLight,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              '전체 동의',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 16),
                      // 이용약관 동의
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _agreeTerms = !_agreeTerms),
                            child: Icon(
                              _agreeTerms
                                  ? Icons.check_circle_rounded
                                  : Icons.check_circle_outline_rounded,
                              color: _agreeTerms ? AppTheme.primary : AppTheme.textLight,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                                children: [
                                  const TextSpan(text: '(필수) '),
                                  TextSpan(
                                    text: '이용약관',
                                    style: const TextStyle(
                                        color: AppTheme.primary,
                                        decoration: TextDecoration.underline,
                                        fontWeight: FontWeight.w600),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () => _launchUrl(_termsUrl),
                                  ),
                                  const TextSpan(text: ' 동의'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // 개인정보처리방침 동의
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _agreePrivacy = !_agreePrivacy),
                            child: Icon(
                              _agreePrivacy
                                  ? Icons.check_circle_rounded
                                  : Icons.check_circle_outline_rounded,
                              color: _agreePrivacy ? AppTheme.primary : AppTheme.textLight,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                                children: [
                                  const TextSpan(text: '(필수) '),
                                  TextSpan(
                                    text: '개인정보처리방침',
                                    style: const TextStyle(
                                        color: AppTheme.primary,
                                        decoration: TextDecoration.underline,
                                        fontWeight: FontWeight.w600),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () => _launchUrl(_privacyUrl),
                                  ),
                                  const TextSpan(text: ' 동의'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _handleSignup,
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : const Text('가입 완료'),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('이미 계정이 있으신가요?',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('로그인',
                          style: TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary));
}
