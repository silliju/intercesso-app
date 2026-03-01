import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/prayer_provider.dart';
import '../../config/theme.dart';
import '../../widgets/common_widgets.dart';
import '../../services/statistics_service.dart';
import '../main/main_tab_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;
  String? _loadError;
  final StatisticsService _statisticsService = StatisticsService();

  @override
  bool get wantKeepAlive => false; // 탭 전환 시 항상 새로 로드

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    debugPrint('[HomeScreen] _loadAll() 시작');
    await Future.wait([
      _loadDashboard(),
      _loadPrayers(),
    ]);
    debugPrint('[HomeScreen] _loadAll() 완료');
  }

  Future<void> _loadDashboard() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      debugPrint('[HomeScreen] 대시보드 로드 시작');
      final data = await _statisticsService.getDashboard();
      debugPrint('[HomeScreen] 대시보드 응답: $data');
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
        if (!mounted) return;
        setState(() {
          _dashboardData = {
            'stats': {
              'total_prayers': 0, 'answered_prayers': 0,
              'streak_days': 0, 'total_participations': 0, 'answer_rate': 0,
            },
          };
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      debugPrint('[HomeScreen] 대시보드 로드 오류: $e\n$stack');
      if (!mounted) return;
      setState(() {
        _dashboardData = {
          'stats': {
            'total_prayers': 0, 'answered_prayers': 0,
            'streak_days': 0, 'total_participations': 0, 'answer_rate': 0,
          },
        };
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPrayers() async {
    if (!mounted) return;
    try {
      debugPrint('[HomeScreen] 기도 목록 로드 시작');
      final provider = context.read<PrayerProvider>();
      // 공개 기도 목록 먼저 시도
      await provider.loadPrayers(refresh: true, scope: 'public');
      debugPrint('[HomeScreen] 공개 기도 목록: ${provider.prayers.length}개');

      // 공개 기도가 없으면 내 기도도 같이 표시
      if (provider.prayers.isEmpty && mounted) {
        debugPrint('[HomeScreen] 공개 기도 없음 → 내 기도 로드 시도');
        await provider.loadPrayers(refresh: true);
        debugPrint('[HomeScreen] 전체 기도 목록: ${provider.prayers.length}개');
      }
    } catch (e, stack) {
      debugPrint('[HomeScreen] 기도 목록 로드 오류: $e\n$stack');
      if (mounted) {
        setState(() => _loadError = e.toString());
      }
    }
  }

  // ─── 기도 탭으로 이동
  void _goToPrayersTab() {
    try {
      final mainState = context.findAncestorStateOfType<MainTabScreenState>();
      if (mainState != null) {
        debugPrint('[HomeScreen] 기도 탭으로 전환');
        mainState.switchToTab(1);
      } else {
        debugPrint('[HomeScreen] MainTabScreenState 찾지 못함 → push 사용');
        context.push('/prayers');
      }
    } catch (e) {
      debugPrint('[HomeScreen] 탭 전환 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final user = context.watch<AuthProvider>().user;
    final prayerProvider = context.watch<PrayerProvider>();
    final stats = _dashboardData?['stats'];

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () => _loadAll(),
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
                    // 통계 카드
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: AppTheme.cardDecoration,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem('${stats?['total_prayers'] ?? 0}', '내 기도'),
                              _buildDivider(),
                              _buildStatItem('${stats?['answered_prayers'] ?? 0}', '응답받음'),
                              _buildDivider(),
                              _buildStatItem('${stats?['total_participations'] ?? 0}', '함께 기도'),
                              _buildDivider(),
                              _buildStatItem('${stats?['streak_days'] ?? 0}일 🔥', '연속'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton(
                              onPressed: () {
                                debugPrint('[HomeScreen] 상세 통계 버튼 클릭');
                                context.push('/dashboard');
                              },
                              child: const Text(
                                '상세 통계 보기',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    // 전체보기 버튼 - GestureDetector로 터치 영역 확장
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        debugPrint('[HomeScreen] 전체보기 탭');
                        _goToPrayersTab();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: const Text(
                          '전체보기 >',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 에러 상태
            if (_loadError != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      '기도 목록을 불러오지 못했습니다: $_loadError',
                      style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                    ),
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
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      const EmptyWidget(
                        emoji: '🙏',
                        title: '아직 기도가 없어요',
                        subtitle: '첫 번째 기도를 작성해보세요',
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          debugPrint('[HomeScreen] 기도 작성하기 버튼 클릭');
                          context.push('/prayer/create');
                        },
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('기도 작성하기'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    // 최대 5개만 홈에서 표시
                    final displayPrayers = prayerProvider.prayers.take(5).toList();
                    if (index >= displayPrayers.length) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        child: OutlinedButton(
                          onPressed: _goToPrayersTab,
                          child: const Text('전체 기도 목록 보기'),
                        ),
                      );
                    }
                    final prayer = displayPrayers[index];
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
                      onTap: () {
                        debugPrint('[HomeScreen] 기도 카드 클릭: ${prayer.id}');
                        context.push('/prayer/${prayer.id}');
                      },
                    );
                  },
                  childCount: prayerProvider.prayers.take(5).length + 1,
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
    return Container(width: 1, height: 32, color: AppTheme.border);
  }
}
