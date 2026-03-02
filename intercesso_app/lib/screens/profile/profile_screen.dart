import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import '../../widgets/common_widgets.dart';
import '../../services/statistics_service.dart';
import '../main/main_tab_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final StatisticsService _statisticsService = StatisticsService();
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String _appVersion = '1.0.0';

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    // pubspec.yaml 버전을 동적으로 가져오기 (패키지 이름 하드코딩)
    // package_info_plus가 없으면 pubspec에서 정의한 단순 문자열 반환
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

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    final totalPrayers   = _stats?['total_prayers']       ?? 0;
    final answeredPrayers = _stats?['answered_prayers']   ?? 0;
    final totalParticipations = _stats?['total_participations'] ?? 0;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
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
                      // 프로필 이미지
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
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                      if (user?.bio != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          user!.bio!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      // 통계 - API에서 실제 값 사용
                      _isLoading
                          ? const SizedBox(
                              height: 40,
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.primary,
                                ),
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
                          child: const Text(
                            '프로필 수정',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 메뉴 카드
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: AppTheme.cardDecoration,
                  child: Column(
                    children: [
                      MenuItemTile(
                        icon: Icons.menu_book_outlined,
                        title: '내 기도 목록',
                        onTap: () {
                          // 기도 탭(index=1)으로 전환
                          final mainState = context.findAncestorStateOfType<MainTabScreenState>();
                          if (mainState != null) {
                            mainState.switchToTab(1);
                          }
                        },
                      ),
                      Divider(height: 1, indent: 64, color: AppTheme.border),
                      MenuItemTile(
                        icon: Icons.bar_chart_outlined,
                        title: '기도 통계',
                        onTap: () => context.push('/dashboard'),
                      ),
                      Divider(height: 1, indent: 64, color: AppTheme.border),
                      MenuItemTile(
                        icon: Icons.group_outlined,
                        title: '내 그룹',
                        onTap: () {
                          // 그룹 탭(index=3)으로 전환
                          final mainState = context.findAncestorStateOfType<MainTabScreenState>();
                          if (mainState != null) {
                            mainState.switchToTab(3);
                          }
                        },
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

              // 로그아웃
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: AppTheme.cardDecoration,
                  child: MenuItemTile(
                    icon: Icons.logout,
                    title: '로그아웃',
                    iconColor: AppTheme.error,
                    onTap: () => _confirmLogout(context),
                    trailing: const SizedBox.shrink(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Intercesso v\$_appVersion',
                style: TextStyle(fontSize: 12, color: AppTheme.textLight),
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
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '로그아웃',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text('정말 로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
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
}
