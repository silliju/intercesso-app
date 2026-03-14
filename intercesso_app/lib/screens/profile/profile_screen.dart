import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../widgets/common_widgets.dart';
import '../../services/statistics_service.dart';
import '../../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final StatisticsService _statisticsService = StatisticsService();
  final ApiService _api = ApiService();
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String _appVersion = '1.0.0';

  static final String _privacyUrl = AppConstants.privacyUrl;
  static final String _termsUrl = AppConstants.termsUrl;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    const version = String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0');
    if (mounted) setState(() => _appVersion = version.isEmpty ? '1.0.0' : version);
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final res = await _statisticsService.getDashboard();
      if (mounted && res['success'] == true && res['data'] != null) {
        setState(() {
          _stats = res['data']['stats'] as Map<String, dynamic>? ?? {};
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() { _stats = {}; _isLoading = false; });
      }
    } catch (e) {
      debugPrint('[Profile] 통계 로드 오류: $e');
      if (mounted) setState(() { _stats = {}; _isLoading = false; });
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('페이지를 열 수 없습니다')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    final totalPrayers        = _stats?['total_prayers']        ?? 0;
    final answeredPrayers     = _stats?['answered_prayers']     ?? 0;
    final totalParticipations = _stats?['total_participations'] ?? 0;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              )
            : null,
        title: const Text('마이페이지'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/profile/edit'),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // 프로필 카드
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: AppTheme.cardDecoration,
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppTheme.primaryLight,
                        backgroundImage: user?.profileImageUrl != null
                            ? NetworkImage(user!.profileImageUrl!)
                            : null,
                        child: user?.profileImageUrl == null
                            ? Text(
                                user?.nickname.isNotEmpty == true
                                    ? user!.nickname[0]
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user?.nickname ?? '',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (user?.churchName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '⛪ ${user!.churchName}',
                          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                        ),
                      ],
                      if (user?.bio != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          user!.bio!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                        ),
                      ],
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      _isLoading
                          ? const SizedBox(
                              height: 40,
                              child: Center(
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildProfileStat('$totalPrayers', '내 기도'),
                                Container(width: 1, height: 32, color: AppTheme.border),
                                _buildProfileStat('$answeredPrayers', '응답받음'),
                                Container(width: 1, height: 32, color: AppTheme.border),
                                _buildProfileStat('$totalParticipations', '함께 기도'),
                              ],
                            ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => context.push('/profile/edit'),
                          child: const Text('프로필 수정',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 기능 메뉴 (찬양대 포함)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: AppTheme.cardDecoration,
                  child: Column(
                    children: [
                      MenuItemTile(
                        icon: Icons.menu_book_outlined,
                        title: '내 기도 목록',
                        onTap: () => context.go('/home', extra: {'tabIndex': 1}),
                      ),
                      Divider(height: 1, indent: 64, color: AppTheme.border),
                      MenuItemTile(
                        icon: Icons.bar_chart_outlined,
                        title: '기도 통계',
                        onTap: () => context.push('/dashboard'),
                      ),
                      Divider(height: 1, indent: 64, color: AppTheme.border),
                      MenuItemTile(
                        icon: Icons.music_note_outlined,
                        title: '찬양대',
                        onTap: () => context.push('/choir'),
                      ),
                      Divider(height: 1, indent: 64, color: AppTheme.border),
                      MenuItemTile(
                        icon: Icons.group_outlined,
                        title: '내 그룹',
                        onTap: () => context.go('/home', extra: {'tabIndex': 4}),
                      ),
                      Divider(height: 1, indent: 64, color: AppTheme.border),
                      MenuItemTile(
                        icon: Icons.notifications_outlined,
                        title: '알림 설정',
                        onTap: () => context.push('/notifications'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 정보 메뉴 (약관 & 개인정보)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: AppTheme.cardDecoration,
                  child: Column(
                    children: [
                      MenuItemTile(
                        icon: Icons.description_outlined,
                        title: '이용약관',
                        onTap: () => _launchUrl(_termsUrl),
                      ),
                      Divider(height: 1, indent: 64, color: AppTheme.border),
                      MenuItemTile(
                        icon: Icons.privacy_tip_outlined,
                        title: '개인정보처리방침',
                        onTap: () => _launchUrl(_privacyUrl),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 계정 관리 메뉴
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: AppTheme.cardDecoration,
                  child: Column(
                    children: [
                      MenuItemTile(
                        icon: Icons.logout,
                        title: '로그아웃',
                        iconColor: AppTheme.textSecondary,
                        onTap: () => _confirmLogout(context),
                        trailing: const SizedBox.shrink(),
                      ),
                      Divider(height: 1, indent: 64, color: AppTheme.border),
                      MenuItemTile(
                        icon: Icons.delete_forever_outlined,
                        title: '계정 삭제',
                        iconColor: AppTheme.error,
                        titleColor: AppTheme.error,
                        onTap: () => _confirmDeleteAccount(context),
                        trailing: const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Intercesso v$_appVersion',
                style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileStat(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.primary)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('로그아웃', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('정말 로그아웃 하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthProvider>().logout();
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 22),
            SizedBox(width: 8),
            Text('계정 삭제', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.red)),
          ],
        ),
        content: const Text(
          '계정을 삭제하면 모든 기도, 댓글, 그룹 데이터가\n영구적으로 삭제됩니다.\n\n이 작업은 되돌릴 수 없습니다.',
          style: TextStyle(fontSize: 14, height: 1.6),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteAccount();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    // 로딩 다이얼로그 표시
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
            SizedBox(width: 16),
            Text('계정을 삭제하는 중...'),
          ],
        ),
      ),
    );

    try {
      await _api.delete('/users/me');
      if (mounted) {
        Navigator.pop(context); // 로딩 다이얼로그 닫기
        context.read<AuthProvider>().logout();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('계정이 삭제되었습니다'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // 로딩 다이얼로그 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('계정 삭제 실패: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }
}
