import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';

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
  final _profileIdCtrl = TextEditingController();
  final _churchCtrl = TextEditingController();
  bool _obscurePw = true;

  // profile_id 중복체크 상태
  bool? _profileIdAvailable;   // null=미확인, true=가능, false=불가
  String _profileIdMsg = '';
  Timer? _debounce;
  bool _checkingId = false;

  final _api = ApiService();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    _nickCtrl.dispose();
    _profileIdCtrl.dispose();
    _churchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // profile_id 실시간 중복체크 (디바운스 500ms)
  void _onProfileIdChanged(String val) {
    _debounce?.cancel();
    final v = val.trim().toLowerCase();
    if (v.isEmpty) {
      setState(() { _profileIdAvailable = null; _profileIdMsg = ''; _checkingId = false; });
      return;
    }
    final re = RegExp(r'^[a-z0-9_.]{3,30}$');
    if (!re.hasMatch(v)) {
      setState(() {
        _profileIdAvailable = false;
        _profileIdMsg = '영문 소문자·숫자·_(언더스코어)·.(점) / 3~30자';
        _checkingId = false;
      });
      return;
    }
    setState(() { _checkingId = true; _profileIdMsg = '확인 중...'; _profileIdAvailable = null; });
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final res = await _api.get('/auth/check-profile-id', queryParams: {'id': v});
        final data = res['data'] as Map<String, dynamic>? ?? {};
        final avail = data['available'] == true;
        if (mounted) {
          setState(() {
            _checkingId = false;
            _profileIdAvailable = avail;
            if (avail) {
              _profileIdMsg = '✓ 사용 가능한 ID입니다';
            } else {
              _profileIdMsg = data['reason'] == 'format'
                  ? '형식이 올바르지 않습니다'
                  : '이미 사용 중인 ID입니다';
            }
          });
        }
      } catch (_) {
        // 네트워크 오류 시 사용 가능으로 처리 (DB 마이그레이션 전 단계)
        if (mounted) setState(() { _checkingId = false; _profileIdAvailable = true; _profileIdMsg = '✓ 형식 OK'; });
      }
    });
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    final pid = _profileIdCtrl.text.trim().toLowerCase();
    if (pid.isNotEmpty && _profileIdAvailable == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('프로필 ID를 확인해주세요'), backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final ok = await auth.signUp(
      email: _emailCtrl.text.trim(),
      password: _pwCtrl.text,
      nickname: _nickCtrl.text.trim(),
      profileId: pid.isEmpty ? null : pid,
      churchName: _churchCtrl.text.isEmpty ? null : _churchCtrl.text.trim(),
    );
    if (ok && mounted) {
      context.go('/home');
    } else if (mounted && auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error!), backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary, height: 1.3),
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
                  decoration: AppTheme.cardDecoration,
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
                            icon: Icon(_obscurePw ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: AppTheme.textLight, size: 20),
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
                      // ── 프로필 ID
                      Row(children: [
                        _label('프로필 ID'),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(8)),
                          child: const Text('선택', style: TextStyle(fontSize: 11, color: AppTheme.primary)),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      const Text('검색 및 중보기도 요청 시 사용되는 고유 ID',
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _profileIdCtrl,
                        autocorrect: false,
                        textCapitalization: TextCapitalization.none,
                        onChanged: _onProfileIdChanged,
                        decoration: InputDecoration(
                          hintText: 'ex) gildong_hong (영문·숫자·_·.)',
                          prefixText: '@ ',
                          prefixStyle: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700),
                          suffixIcon: _checkingId
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(width: 18, height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2)))
                              : _profileIdAvailable == true
                                  ? const Icon(Icons.check_circle, color: AppTheme.success, size: 20)
                                  : _profileIdAvailable == false
                                      ? const Icon(Icons.cancel, color: AppTheme.error, size: 20)
                                      : null,
                        ),
                        validator: (v) {
                          final val = v?.trim().toLowerCase() ?? '';
                          if (val.isEmpty) return null; // 선택 필드
                          if (!RegExp(r'^[a-z0-9_.]{3,30}$').hasMatch(val)) {
                            return '영문 소문자·숫자·_·. 만 사용 가능 (3~30자)';
                          }
                          return null;
                        },
                      ),
                      if (_profileIdMsg.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6, left: 4),
                          child: Text(_profileIdMsg,
                              style: TextStyle(
                                fontSize: 12,
                                color: _profileIdAvailable == true ? AppTheme.success : AppTheme.error,
                              )),
                        ),
                      const SizedBox(height: 20),
                      // ── 교회명
                      Row(children: [
                        _label('교회명'),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(8)),
                          child: const Text('선택', style: TextStyle(fontSize: 11, color: AppTheme.primary)),
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
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _handleSignup,
                    child: isLoading
                        ? const SizedBox(width: 22, height: 22,
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
                          style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 14)),
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
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary));
}
