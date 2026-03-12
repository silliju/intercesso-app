import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/prayer_provider.dart';
import '../../providers/gratitude_provider.dart';
import '../../config/theme.dart';
import '../main/main_tab_screen.dart';
import '../gratitude/create_gratitude_screen.dart';
import 'bible_verses_data.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  bool _isPersonalMode = true;
  bool _showPrayerFeed = true;
  late Map<String, String> _todayVerse;

  @override
  bool get wantKeepAlive => false;

  @override
  void initState() {
    super.initState();
    _todayVerse = BibleVersesData.getTodayVerse();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  Future<void> _loadAll() async {
    if (!mounted) return;
    await Future.wait([_loadPrayers(), _loadGratitude()]);
  }

  Future<void> _loadPrayers() async {
    if (!mounted) return;
    try {
      await context.read<PrayerProvider>().loadHomePrayers();
    } catch (e) {
      debugPrint('[HomeScreen] 기도 로드 오류: $e');
    }
  }

  Future<void> _loadGratitude() async {
    if (!mounted) return;
    try {
      final g = context.read<GratitudeProvider>();
      await Future.wait([
        g.loadTodayJournal(),
        g.loadStreak(),
        g.loadFeed('group'),
      ]);
    } catch (e) {
      debugPrint('[HomeScreen] 감사 로드 오류: $e');
    }
  }

  void _goToPrayersTab() {
    final mainState = context.findAncestorStateOfType<MainTabScreenState>();
    if (mainState != null) {
      mainState.switchToTab(1);
    } else {
      context.push('/prayers');
    }
  }

  void _goToGratitudeTab() {
    final mainState = context.findAncestorStateOfType<MainTabScreenState>();
    if (mainState != null) {
      mainState.switchToTab(3);
    } else {
      context.push('/gratitude');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final user = context.watch<AuthProvider>().user;
    final gratProvider = context.watch<GratitudeProvider>();
    final prayerProvider = context.watch<PrayerProvider>();
    final streak = gratProvider.streak;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: _loadAll,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── 앱바
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: AppTheme.surface,
              elevation: 0,
              centerTitle: true,
              title: const Text(
                'Intercesso',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: AppTheme.primary,
                  letterSpacing: -0.5,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined,
                      color: AppTheme.textPrimary, size: 24),
                  onPressed: () => context.push('/notifications'),
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(
                  height: 1,
                  color: AppTheme.border,
                ),
              ),
            ),

            // ── 개인/교회 모드 토글
            SliverToBoxAdapter(child: _buildModeToggle()),

            // ── 인사말 카드
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _buildGreetingCard(user, streak),
              ),
            ),

            // ── 빠른 액션 버튼
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _buildQuickActions(gratProvider),
              ),
            ),

            // ── 오늘의 말씀
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _buildTodayVerse(),
              ),
            ),

            // ── 피드 탭 전환
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: _buildFeedTabToggle(),
              ),
            ),

            // ── 피드 컨텐츠
            if (_showPrayerFeed)
              _buildPrayerFeedSliver(prayerProvider)
            else
              _buildGratitudeFeedSliver(gratProvider),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  // ── 개인/교회 모드 토글 (디자인 가이드 적용)
  Widget _buildModeToggle() {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Expanded(child: _modeTab('🙏 개인모드', true)),
            Expanded(child: _modeTab('⛪ 교회모드', false)),
          ],
        ),
      ),
    );
  }

  Widget _modeTab(String label, bool isPersonal) {
    final isSelected = _isPersonalMode == isPersonal;
    return GestureDetector(
      onTap: () {
        setState(() => _isPersonalMode = isPersonal);
        // 교회모드 선택 시 찬양대 홈으로 이동, 돌아오면 개인모드 복귀
        if (!isPersonal) {
          context.push('/choir').then((_) {
            if (mounted) setState(() => _isPersonalMode = true);
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }

  // ── 인사말 카드 (디자인 가이드 그라디언트 헤더)
  Widget _buildGreetingCard(dynamic user, dynamic streak) {
    final hour = DateTime.now().hour;
    final greeting =
        hour < 12 ? '좋은 아침이에요' : hour < 18 ? '안녕하세요' : '좋은 저녁이에요';
    final name = user?.nickname ?? '사용자';
    final initial = name.isNotEmpty ? name[0] : '?';
    final streakDays =
        (streak != null && streak.currentStreak != null)
            ? streak.currentStreak as int
            : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332F6FED),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // 아바타
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.25),
              border: Border.all(
                color: Colors.white.withOpacity(0.4),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: user?.profileImageUrl != null
                  ? Image.network(user!.profileImageUrl!, fit: BoxFit.cover)
                  : Center(
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          // 인사말
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, $name님 👋',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '오늘도 함께 기도해요 🙏',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.85),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          // 스트릭 배지
          if (streakDays > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 22)),
                  const SizedBox(height: 2),
                  Text(
                    '${streakDays}일',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── 빠른 액션 버튼 (디자인 가이드 카드 스타일)
  Widget _buildQuickActions(GratitudeProvider gratProvider) {
    final hasTodayGratitude = gratProvider.todayJournal != null;

    return Row(
      children: [
        // 기도 제목 쓰기
        Expanded(
          child: GestureDetector(
            onTap: () => context.push('/prayer/create'),
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x292F6FED),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('✏️', style: TextStyle(fontSize: 22)),
                  SizedBox(width: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '기도 제목 쓰기',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        '오늘의 기도',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // 감사일기 쓰기
        Expanded(
          child: GestureDetector(
            onTap: () async {
              if (!hasTodayGratitude) {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const CreateGratitudeScreen()),
                );
                if (result == true && mounted) {
                  context.read<GratitudeProvider>().loadTodayJournal();
                }
              } else {
                _goToGratitudeTab();
              }
            },
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                gradient: hasTodayGratitude
                    ? const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : AppTheme.gamsaGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (hasTodayGratitude
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF59E0B))
                        .withOpacity(0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    hasTodayGratitude ? '✅' : '🌷',
                    style: const TextStyle(fontSize: 22),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasTodayGratitude ? '감사일기 완료' : '감사일기 쓰기',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        hasTodayGratitude ? '오늘 작성 완료 ✓' : '오늘의 감사',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── 오늘의 말씀 (디자인 가이드 카드)
  Widget _buildTodayVerse() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('📖', style: TextStyle(fontSize: 12)),
                    SizedBox(width: 4),
                    Text(
                      '오늘의 말씀',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '"${_todayVerse['text'] ?? ''}"',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
                height: 1.7,
                letterSpacing: -0.2,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              _todayVerse['reference'] ?? '',
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 피드 탭 전환 (디자인 가이드 스타일)
  Widget _buildFeedTabToggle() {
    return Row(
      children: [
        // 섹션 타이틀
        Expanded(
          child: Row(
            children: [
              _feedTab('🙏 기도 피드', true),
              const SizedBox(width: 8),
              _feedTab('🌷 감사 피드', false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _feedTab(String label, bool isPrayer) {
    final isSelected = _showPrayerFeed == isPrayer;
    return GestureDetector(
      onTap: () => setState(() => _showPrayerFeed = isPrayer),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isPrayer ? AppTheme.primary : AppTheme.gamsa)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : AppTheme.border,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (isPrayer ? AppTheme.primary : AppTheme.gamsa)
                        .withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }

  // ── 기도 피드 (SliverList)
  Widget _buildPrayerFeedSliver(PrayerProvider provider) {
    final prayers = provider.homePrayers;
    final isLoading = provider.isHomeLoading;

    if (isLoading && prayers.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          ),
        ),
      );
    }

    if (prayers.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: [
                const Text('🙏', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                const Text(
                  '아직 기도제목이 없어요\n첫 번째 기도를 작성해보세요',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => context.push('/prayer/create'),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('기도 작성하기'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final list = prayers.take(5).toList();
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) {
          if (i == list.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Center(
                child: TextButton.icon(
                  onPressed: _goToPrayersTab,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: const Text('기도 목록 전체보기'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            child: _PrayerFeedCard(prayer: list[i]),
          );
        },
        childCount: list.length + 1,
      ),
    );
  }

  // ── 감사 피드 (SliverList)
  Widget _buildGratitudeFeedSliver(GratitudeProvider provider) {
    final journals = provider.getFeedByTab('group');
    final isLoading = provider.isFeedLoading('group');

    if (isLoading && journals.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Center(
            child: CircularProgressIndicator(color: AppTheme.gamsa),
          ),
        ),
      );
    }

    if (journals.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.gamsaLight,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.gamsaBorder),
            ),
            child: Column(
              children: [
                const Text('🌸', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                const Text(
                  '감사일기가 없어요\n오늘 감사한 일 3가지를 적어보세요',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _goToGratitudeTab,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.gamsa,
                  ),
                  icon: const Text('🌷', style: TextStyle(fontSize: 16)),
                  label: const Text('감사일기 쓰기'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final list = journals.take(5).toList();
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) {
          if (i == list.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Center(
                child: TextButton.icon(
                  onPressed: _goToGratitudeTab,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: const Text('감사 피드 전체보기'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.gamsa,
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            child: _GratitudeFeedCard(journal: list[i]),
          );
        },
        childCount: list.length + 1,
      ),
    );
  }
}

// ── 기도 피드 카드 (디자인 가이드 적용)
class _PrayerFeedCard extends StatelessWidget {
  final dynamic prayer;
  const _PrayerFeedCard({required this.prayer});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/prayer/${prayer.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryLight,
                  ),
                  child: ClipOval(
                    child: prayer.user?.profileImageUrl != null
                        ? Image.network(prayer.user!.profileImageUrl!,
                            fit: BoxFit.cover)
                        : Center(
                            child: Text(
                              (prayer.user?.nickname ?? '?')[0],
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    prayer.user?.nickname ?? '사용자',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                if (prayer.category != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      prayer.category!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // 제목
            Text(
              prayer.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            if (prayer.content != null && prayer.content!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                prayer.content!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 12),
            // 하단 액션
            Row(
              children: [
                _actionChip('🙏', '${prayer.prayerCount ?? 0}명', AppTheme.primaryLight, AppTheme.primary),
                const SizedBox(width: 8),
                _actionChip('💬', '${prayer.commentCount ?? 0}', AppTheme.background, AppTheme.textSecondary),
                const Spacer(),
                Text(
                  _timeAgo(prayer.createdAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionChip(String emoji, String count, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            count,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(String? createdAt) {
    if (createdAt == null || createdAt.isEmpty) return '';
    final dt = DateTime.tryParse(createdAt);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt.toLocal());
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inHours < 1) return '${diff.inMinutes}분 전';
    if (diff.inDays < 1) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }
}

// ── 감사 피드 카드 (디자인 가이드 적용)
class _GratitudeFeedCard extends StatelessWidget {
  final dynamic journal;
  const _GratitudeFeedCard({required this.journal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.gamsaLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.gamsaBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0AF59E0B),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFEF3C7),
                ),
                child: Center(
                  child: Text(
                    (journal.user?.nickname ?? '?')[0],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  journal.user?.nickname ?? '사용자',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              if (journal.emotion != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.gamsaBorder.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    journal.emotion!,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // 감사 항목들
          if (journal.item1 != null)
            _gratitudeItem(journal.item1!),
          if (journal.item2 != null) ...[
            const SizedBox(height: 6),
            _gratitudeItem(journal.item2!),
          ],
          if (journal.item3 != null) ...[
            const SizedBox(height: 6),
            _gratitudeItem(journal.item3!),
          ],
        ],
      ),
    );
  }

  Widget _gratitudeItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('🌷', style: TextStyle(fontSize: 14)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textPrimary,
              height: 1.5,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ],
    );
  }
}
