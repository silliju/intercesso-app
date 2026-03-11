import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../models/church_model.dart';
import '../../services/church_service.dart';

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
  final _churchSearchCtrl = TextEditingController();
  bool _obscurePw = true;
  bool _agreeTerms = false;
  bool _agreePrivacy = false;

  ChurchModel? _selectedChurch;
  List<ChurchModel> _searchResults = [];
  bool _searchLoading = false;
  Timer? _searchDebounce;

  final _churchService = ChurchService();

  static final String _termsUrl = AppConstants.termsUrl;
  static final String _privacyUrl = AppConstants.privacyUrl;

  @override
  void initState() {
    super.initState();
    _churchSearchCtrl.addListener(_onChurchSearchChanged);
  }

  void _onChurchSearchChanged() {
    if (_selectedChurch != null) return;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _performSearch();
    });
  }

  Future<void> _performSearch() async {
    final q = _churchSearchCtrl.text.trim();
    if (q.isEmpty) {
      setState(() {
        _searchResults = [];
        _searchLoading = false;
      });
      return;
    }
    setState(() => _searchLoading = true);
    try {
      final list = await _churchService.search(q);
      if (mounted) setState(() {
        _searchResults = list;
        _searchLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() {
        _searchResults = [];
        _searchLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    _nickCtrl.dispose();
    _churchSearchCtrl.dispose();
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
      churchId: _selectedChurch?.churchId,
      churchName: _selectedChurch?.name,
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
                      // ── 교회 (검색 후 선택 또는 직접 등록)
                      Row(children: [
                        _label('교회'),
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
                      if (_selectedChurch != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.church, color: AppTheme.primary, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _selectedChurch!.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () => setState(() {
                                  _selectedChurch = null;
                                  _churchSearchCtrl.clear();
                                  _searchResults = [];
                                }),
                                child: const Text('취소', style: TextStyle(fontSize: 13)),
                              ),
                            ],
                          ),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _churchSearchCtrl,
                              decoration: InputDecoration(
                                hintText: '교회명 또는 지역으로 검색',
                                prefixIcon: const Icon(Icons.search, color: AppTheme.textLight, size: 20),
                                suffixIcon: _searchLoading
                                    ? const Padding(
                                        padding: EdgeInsets.all(12),
                                        child: SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            if (_searchResults.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxHeight: 160),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: _searchResults.length,
                                  itemBuilder: (context, i) {
                                    final c = _searchResults[i];
                                    return ListTile(
                                      dense: true,
                                      leading: const Icon(Icons.church_outlined, size: 20, color: AppTheme.textSecondary),
                                      title: Text(c.name, style: const TextStyle(fontSize: 14)),
                                      subtitle: c.addressLine.isNotEmpty
                                          ? Text(c.addressLine, style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)
                                          : null,
                                      onTap: () => setState(() {
                                        _selectedChurch = c;
                                        _churchSearchCtrl.clear();
                                        _searchResults = [];
                                      }),
                                    );
                                  },
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () async {
                                final church = await context.push<ChurchModel?>('/signup/register-church');
                                if (church != null && mounted) setState(() => _selectedChurch = church);
                              },
                              icon: const Icon(Icons.add_circle_outline, size: 18),
                              label: const Text('교회가 없어요. 직접 등록하기'),
                            ),
                          ],
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
