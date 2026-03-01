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
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (success && mounted) {
      context.go('/home');
    } else if (mounted && authProvider.error != null) {
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

              // ─── 타이틀
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

              // ─── 이메일/비밀번호 폼
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

              // ─── 로그인 버튼
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

              // ─── 아이디/비밀번호 찾기
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

              // ─── 회원가입 링크
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
