import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/prayer_provider.dart';
import '../../config/theme.dart';
import '../../widgets/common_widgets.dart';
import '../../services/statistics_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;
  final StatisticsService _statisticsService = StatisticsService();

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    _loadPrayers();
  }

  Future<void> _loadDashboard() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // 실제 API에서 통계 데이터 로드
      final data = await _statisticsService.getDashboard();
      if (!mounted) return;
      if (data['success'] == true && data['data'] != null) {
        final apiStats = data['data']['stats'] as Map<String, dynamic>? ?? {};
        setState(() {
          _dashboardData = {
            'stats': {
              'total_prayers': apiStats['total_prayers'] ?? 0,
              'answered_prayers': apiStats['answered_prayers'] ?? 0,
              'streak_days': apiStats['streak_days'] ?? 0,
              'total_participations': apiStats['total_participations'] ?? 0,
              'answer_rate': apiStats['answer_rate'] ?? 0,
            },
          };
          _isLoading = false;
        });
      } else {
        // API 실패 시 0으로 초기화
        setState(() {
          _dashboardData = {
            'stats': {
              'total_prayers': 0,
              'answered_prayers': 0,
              'streak_days': 0,
              'total_participations': 0,
              'answer_rate': 0,
            },
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _dashboardData = {'stats': {'total_prayers': 0, 'answered_prayers': 0, 'streak_days': 0, 'total_participations': 0, 'answer_rate': 0}};
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPrayers() async {
    final provider = context.read<PrayerProvider>();
    await provider.loadPrayers(refresh: true, scope: 'public');
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final prayerProvider = context.watch<PrayerProvider>();
    final stats = _dashboardData?['stats'];

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () async {
          await _loadDashboard();
          await _loadPrayers();
        },
        child: CustomScrollView(
          slivers: [
            // 앱바
            SliverAppBar(
              floating: true,
              backgroundColor: AppTheme.surface,
              elevation: 0,
              titleSpacing: 20,
              title: const Text(
                'Intercesso',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  color: AppTheme.primary,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined,
                      color: AppTheme.textPrimary),
                  onPressed: () => context.push('/notifications'),
                ),
                const SizedBox(width: 4),
              ],
            ),

            // 인사말 + 통계 카드
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 타이틀 텍스트 (보닥 스타일)
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                          height: 1.3,
                        ),
                        children: [
                          TextSpan(
                            text: '${user?.nickname ?? ''}님',
                            style: const TextStyle(color: AppTheme.primary),
                          ),
                          const TextSpan(text: '\n오늘도 함께 기도해요 🙏'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 통계 카드 (흰색 카드)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: AppTheme.cardDecoration,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(
                                  '${stats?['total_prayers'] ?? 0}',
                                  '내 기도'),
                              _buildDivider(),
                              _buildStatItem(
                                  '${stats?['answered_prayers'] ?? 0}',
                                  '응답받음'),
                              _buildDivider(),
                              _buildStatItem(
                                  '${stats?['total_participations'] ?? 0}',
                                  '함께 기도'),
                              _buildDivider(),
                              _buildStatItem(
                                  '${stats?['streak_days'] ?? 0}일 🔥',
                                  '연속'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 42,
                            child: OutlinedButton(
                              onPressed: () => context.push('/dashboard'),
                              child: const Text('상세 통계 보기'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 섹션 헤더
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '최근 기도 목록',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        '전체보기 >',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 기도 목록
            if (prayerProvider.isLoading && prayerProvider.prayers.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: LoadingWidget(message: '기도 목록을 불러오는 중...'),
                ),
              )
            else if (prayerProvider.prayers.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: EmptyWidget(
                    emoji: '🙏',
                    title: '아직 기도가 없어요',
                    subtitle: '첫 번째 기도를 작성해보세요',
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= prayerProvider.prayers.length) {
                      return prayerProvider.hasMore
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppTheme.primary,
                                ),
                              ),
                            )
                          : const SizedBox(height: 80);
                    }
                    final prayer = prayerProvider.prayers[index];
                    return PrayerCard(
                      title: prayer.title,
                      content: prayer.content,
                      userNickname: prayer.user?.nickname,
                      userImage: prayer.user?.profileImageUrl,
                      status: prayer.status,
                      category: prayer.category,
                      prayerCount: prayer.prayerCount,
                      commentCount: prayer.commentCount,
                      createdAt: prayer.createdAt,
                      isParticipated: prayer.isParticipated,
                      onTap: () => context.push('/prayer/${prayer.id}'),
                    );
                  },
                  childCount: prayerProvider.prayers.length + 1,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.primary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 32,
      color: AppTheme.border,
    );
  }
}
