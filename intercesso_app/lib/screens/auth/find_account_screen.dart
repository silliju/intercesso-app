// lib/screens/auth/find_account_screen.dart
// 아이디(이메일) 찾기 & 비밀번호 재설정 요청 화면
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';

class FindAccountScreen extends StatefulWidget {
  final bool showPasswordTab; // true면 비밀번호찾기 탭 먼저 표시
  const FindAccountScreen({super.key, this.showPasswordTab = false});

  @override
  State<FindAccountScreen> createState() => _FindAccountScreenState();
}

class _FindAccountScreenState extends State<FindAccountScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _api = ApiService();

  // ── 아이디 찾기 ──
  final _nickController = TextEditingController();
  final _churchController = TextEditingController();
  bool _findLoading = false;
  List<Map<String, dynamic>> _foundAccounts = [];
  String? _findError;

  // ── 비밀번호 찾기 ──
  final _emailController = TextEditingController();
  bool _fpLoading = false;
  bool _fpSent = false;
  String? _fpError;
  String _sentEmail = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.showPasswordTab ? 1 : 0,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nickController.dispose();
    _churchController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // ── 아이디 찾기 API 호출 ──
  Future<void> _findAccount() async {
    final nick = _nickController.text.trim();
    if (nick.isEmpty) {
      setState(() => _findError = '닉네임을 입력해주세요');
      return;
    }
    setState(() { _findLoading = true; _findError = null; _foundAccounts = []; });

    try {
      final body = <String, dynamic>{'nickname': nick};
      final church = _churchController.text.trim();
      if (church.isNotEmpty) body['church_name'] = church;

      final res = await _api.post('/auth/find-email', body: body);
      if (res['success'] == true) {
        final users = (res['data']?['users'] as List?) ?? [];
        setState(() {
          _foundAccounts = users.cast<Map<String, dynamic>>();
          if (_foundAccounts.isEmpty) _findError = '일치하는 계정을 찾을 수 없습니다';
        });
      } else {
        setState(() => _findError = res['message'] ?? '계정을 찾을 수 없습니다');
      }
    } catch (e) {
      setState(() => _findError = '서버 연결에 실패했습니다');
    } finally {
      setState(() => _findLoading = false);
    }
  }

  // ── 비밀번호 재설정 이메일 발송 ──
  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _fpError = '이메일을 입력해주세요');
      return;
    }
    if (!email.contains('@')) {
      setState(() => _fpError = '올바른 이메일 형식을 입력해주세요');
      return;
    }
    setState(() { _fpLoading = true; _fpError = null; });

    try {
      final res = await _api.post('/auth/forgot-password', body: {'email': email});
      if (res['success'] == true) {
        setState(() { _fpSent = true; _sentEmail = email; });
      } else {
        setState(() => _fpError = res['message'] ?? '이메일 발송에 실패했습니다');
      }
    } catch (e) {
      setState(() => _fpError = '서버 연결에 실패했습니다');
    } finally {
      setState(() => _fpLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.go('/login'),
        ),
        title: const Text('계정 찾기',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          tabs: const [
            Tab(text: '아이디 찾기'),
            Tab(text: '비밀번호 찾기'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFindIdTab(),
          _buildForgotPwTab(),
        ],
      ),
    );
  }

  // ────────────────────────────────
  // 탭 1: 아이디 찾기
  // ────────────────────────────────
  Widget _buildFindIdTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary, height: 1.4),
              children: [
                TextSpan(text: '닉네임으로\n'),
                TextSpan(text: '이메일을 찾아드릴게요',
                    style: TextStyle(color: AppTheme.primary)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Text('가입 시 사용한 닉네임을 입력해주세요',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('닉네임'),
                const SizedBox(height: 8),
                TextField(
                  controller: _nickController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: '가입 시 사용한 닉네임',
                    prefixIcon: Icon(Icons.person_outline,
                        color: AppTheme.textLight, size: 20),
                  ),
                  onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                ),
                const SizedBox(height: 16),
                _label('교회명 (선택 - 동명이인 구분)'),
                const SizedBox(height: 8),
                TextField(
                  controller: _churchController,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    hintText: '교회명 입력 (선택사항)',
                    prefixIcon: Icon(Icons.church_outlined,
                        color: AppTheme.textLight, size: 20),
                  ),
                  onSubmitted: (_) => _findAccount(),
                ),
              ],
            ),
          ),

          // 에러 메시지
          if (_findError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline, color: AppTheme.error, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(_findError!,
                    style: const TextStyle(color: AppTheme.error, fontSize: 13))),
              ]),
            ),
          ],

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _findLoading ? null : _findAccount,
              child: _findLoading
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Text('이메일 찾기'),
            ),
          ),

          // 결과 표시
          if (_foundAccounts.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🎉 계정을 찾았습니다',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 12),
                  ..._foundAccounts.map((u) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('이메일',
                            style: TextStyle(fontSize: 12,
                                color: AppTheme.textSecondary)),
                        const SizedBox(height: 4),
                        Text('✉️  ${u['email']}',
                            style: const TextStyle(fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary)),
                        if (u['church_name'] != null) ...[
                          const SizedBox(height: 4),
                          Text('⛪  ${u['church_name']}',
                              style: const TextStyle(fontSize: 12,
                                  color: AppTheme.textSecondary)),
                        ],
                        const SizedBox(height: 4),
                        Text('가입일: ${_formatDate(u['created_at'])}',
                            style: const TextStyle(fontSize: 11,
                                color: AppTheme.textLight)),
                      ],
                    ),
                  )),
                  const Divider(),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('로그인하러 가기 →',
                          style: TextStyle(color: AppTheme.primary,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => _tabController.animateTo(1),
              child: const Text(
                '비밀번호를 잊으셨나요? 비밀번호 찾기',
                style: TextStyle(color: AppTheme.primary,
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ────────────────────────────────
  // 탭 2: 비밀번호 찾기
  // ────────────────────────────────
  Widget _buildForgotPwTab() {
    if (_fpSent) return _buildFpDoneView();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary, height: 1.4),
              children: [
                TextSpan(text: '가입한 이메일로\n'),
                TextSpan(text: '재설정 링크를 보내드릴게요',
                    style: TextStyle(color: AppTheme.primary)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Text('이메일로 비밀번호 재설정 링크가 발송됩니다',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('이메일'),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    hintText: '가입 시 사용한 이메일',
                    prefixIcon: Icon(Icons.email_outlined,
                        color: AppTheme.textLight, size: 20),
                  ),
                  onSubmitted: (_) => _forgotPassword(),
                ),
              ],
            ),
          ),

          // 에러
          if (_fpError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline, color: AppTheme.error, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(_fpError!,
                    style: const TextStyle(color: AppTheme.error, fontSize: 13))),
              ]),
            ),
          ],

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _fpLoading ? null : _forgotPassword,
              child: _fpLoading
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Text('재설정 이메일 보내기'),
            ),
          ),

          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => _tabController.animateTo(0),
              child: const Text(
                '이메일이 기억나지 않나요? 아이디 찾기',
                style: TextStyle(color: AppTheme.primary,
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── 발송 완료 뷰 ──
  Widget _buildFpDoneView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.cardDecoration,
            child: Column(
              children: [
                const Text('📬', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 16),
                const Text('이메일을 확인해주세요',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 8),
                Text(_sentEmail,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                        color: AppTheme.primary)),
                const SizedBox(height: 12),
                const Text(
                  '비밀번호 재설정 링크가 발송되었습니다.\n이메일의 링크를 클릭하여\n새 비밀번호를 설정하세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.6),
                ),
                const SizedBox(height: 4),
                const Text('스팸함도 확인해주세요',
                    style: TextStyle(fontSize: 12, color: AppTheme.textLight)),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => setState(() { _fpSent = false; _emailController.clear(); }),
                      child: const Text('다른 이메일로 재시도',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    ),
                    const Text('|', style: TextStyle(color: Color(0xFFE5E7EB))),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('로그인하러 가기 →',
                          style: TextStyle(color: AppTheme.primary,
                              fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary));

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
    } catch (_) { return ''; }
  }
}
