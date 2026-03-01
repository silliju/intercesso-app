// ============================================================
// login_screen.dart - 로그인 화면
// ============================================================
// 역할: 이메일/비밀번호 로그인 + 구글/카카오 소셜 로그인 UI
// - 이메일/비밀번호: 기존 로그인 방식
// - 구글 로그인: google_sign_in 패키지 사용
// - 카카오 로그인: kakao_flutter_sdk 패키지 사용
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 폼 유효성 검사를 위한 키
  final _formKey = GlobalKey<FormState>();
  // 이메일 입력 컨트롤러
  final _emailController = TextEditingController();
  // 비밀번호 입력 컨트롤러
  final _passwordController = TextEditingController();
  // 비밀번호 표시/숨김 토글 상태
  bool _obscurePassword = true;

  @override
  void dispose() {
    // 메모리 누수 방지를 위해 컨트롤러 해제
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// 이메일/비밀번호 로그인 처리
  Future<void> _handleLogin() async {
    // 폼 유효성 검사 실패 시 중단
    if (!_formKey.currentState!.validate()) return;
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (success && mounted) {
      // 로그인 성공 → 홈 화면으로 이동
      context.go('/home');
    } else if (mounted && authProvider.error != null) {
      // 로그인 실패 → 오류 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error!),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      authProvider.clearError();
    }
  }

  /// 구글 소셜 로그인 처리
  Future<void> _handleGoogleLogin() async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.loginWithGoogle();
    if (success && mounted) {
      // 구글 로그인 성공 → 홈 화면으로 이동
      context.go('/home');
    } else if (mounted && authProvider.error != null) {
      // 구글 로그인 실패 → 오류 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error!),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      authProvider.clearError();
    }
  }

  /// 카카오 소셜 로그인 처리
  Future<void> _handleKakaoLogin() async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.loginWithKakao();
    if (success && mounted) {
      // 카카오 로그인 성공 → 홈 화면으로 이동
      context.go('/home');
    } else if (mounted && authProvider.error != null) {
      // 카카오 로그인 실패 → 오류 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error!),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      authProvider.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 인증 상태 감시 (로딩 중 버튼 비활성화)
    final authProvider = context.watch<AuthProvider>();
    final isLoading = authProvider.state == AuthState.loading;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.go('/onboarding'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // ─── 타이틀 (하늘색 강조 스타일) ─────────────────
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    height: 1.3,
                  ),
                  children: [
                    TextSpan(
                      text: '로그인',
                      style: TextStyle(color: AppTheme.primary),
                    ),
                    TextSpan(text: '하고\n기도를 나눠보세요'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '함께 기도하는 공동체에 오신 것을 환영합니다',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 32),

              // ─── 소셜 로그인 버튼 영역 ──────────────────────
              // 구글 로그인 버튼
              _SocialLoginButton(
                onPressed: isLoading ? null : _handleGoogleLogin,
                icon: _GoogleIcon(),
                label: '구글로 계속하기',
                backgroundColor: Colors.white,
                textColor: const Color(0xFF1F2937),
                borderColor: const Color(0xFFE5E7EB),
              ),
              const SizedBox(height: 12),

              // 카카오 로그인 버튼 (카카오 브랜드 색상 #FEE500)
              _SocialLoginButton(
                onPressed: isLoading ? null : _handleKakaoLogin,
                icon: const Text('💬', style: TextStyle(fontSize: 20)),
                label: '카카오로 계속하기',
                backgroundColor: const Color(0xFFFEE500),
                textColor: const Color(0xFF191919),
                borderColor: const Color(0xFFFEE500),
              ),
              const SizedBox(height: 24),

              // ─── 구분선 ─────────────────────────────────────
              Row(
                children: [
                  const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '또는 이메일로 로그인',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
                ],
              ),
              const SizedBox(height: 24),

              // ─── 이메일/비밀번호 폼 ─────────────────────────
              Container(
                padding: const EdgeInsets.all(24),
                decoration: AppTheme.cardDecoration,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('이메일'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'example@email.com',
                          prefixIcon: Icon(Icons.email_outlined,
                              color: AppTheme.textLight, size: 20),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return '이메일을 입력해주세요';
                          if (!v.contains('@')) return '올바른 이메일 형식을 입력해주세요';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildLabel('비밀번호'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: '비밀번호를 입력하세요',
                          prefixIcon: const Icon(Icons.lock_outline,
                              color: AppTheme.textLight, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppTheme.textLight,
                              size: 20,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return '비밀번호를 입력해주세요';
                          if (v.length < 6) return '비밀번호는 6자 이상이어야 합니다';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ─── 이메일 로그인 버튼 ─────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _handleLogin,
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text('로그인'),
                ),
              ),
              const SizedBox(height: 16),

              // ─── 아이디/비밀번호 찾기 링크 ───────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => context.push('/find-account',
                        extra: {'showPasswordTab': false}),
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8)),
                    child: const Text('아이디 찾기',
                        style: TextStyle(color: AppTheme.primary,
                            fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                  Container(
                    width: 1, height: 12,
                    color: const Color(0xFFE5E7EB),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  TextButton(
                    onPressed: () => context.push('/find-account',
                        extra: {'showPasswordTab': true}),
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8)),
                    child: const Text('비밀번호 찾기',
                        style: TextStyle(color: AppTheme.primary,
                            fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ─── 회원가입 링크 ───────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '아직 계정이 없으신가요?',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/signup'),
                    child: const Text(
                      '회원가입',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// 폼 라벨 텍스트 위젯
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 소셜 로그인 버튼 공통 위젯
// 구글/카카오 버튼의 공통 레이아웃을 재사용하기 위한 컴포넌트
// ─────────────────────────────────────────────────────────────
class _SocialLoginButton extends StatelessWidget {
  final VoidCallback? onPressed;  // 버튼 클릭 핸들러 (null이면 비활성화)
  final Widget icon;              // 소셜 아이콘 (구글 SVG, 카카오 이모지 등)
  final String label;             // 버튼 텍스트
  final Color backgroundColor;   // 버튼 배경색
  final Color textColor;          // 텍스트 색상
  final Color borderColor;        // 테두리 색상

  const _SocialLoginButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: BorderSide(color: borderColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50), // 완전 둥근 pill 스타일
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 구글 아이콘 위젯 (G 로고를 색상으로 표현)
// 실제 구글 로고는 컬러 규정이 있으므로 텍스트로 표현합니다
// ─────────────────────────────────────────────────────────────
class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: const Center(
        child: Text(
          'G',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF4285F4), // 구글 브랜드 블루 색상
          ),
        ),
      ),
    );
  }
}
