import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/prayer_provider.dart';
import '../../providers/gratitude_provider.dart';
import '../../config/theme.dart';
import '../main/main_tab_screen.dart';
import 'bible_verses_data.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  late TabController _feedTabController;
  bool _isPersonalMode = true; // true = 개인모드, false = 교회모드

  // 오늘의 말씀
  late Map<String, String> _todayVerse;

  @override
  bool get wantKeepAlive => false;

  @override
  void initState() {
    super.initState();
    _feedTabController = TabController(length: 2, vsync: this);
    _todayVerse = BibleVersesData.getTodayVerse();
    _loadAll();
  }

  @override
  void dispose() {
    _feedTabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadPrayers(),
      _loadGratitude(),
    ]);
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
      await Future.wait([g.loadTodayJournal(), g.loadStreak()]);
    } catch (_) {}
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
      mainState.switchToTab(2);
    } else {
      context.push('/gratitude');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final user = context.watch<AuthProvider>().user;
    final gratProvider = context.watch<GratitudeProvider>();
    final streak = gratProvider.streak;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: _loadAll,
        child: CustomScrollView(
          slivers: [
            // ── 앱바 ──────────────────────────────────────────
            _buildAppBar(),

            // ── 개인/교회 모드 탭 ───────────────────────────────
            SliverToBoxAdapter(child: _buildModeToggle()),

            // ── 인사말 카드 ────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _buildGreetingCard(user, streak),
              ),
            ),

            // ── 빠른 액션 버튼 2개 ─────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _buildQuickActions(gratProvider),
              ),
            ),

            // ── 오늘의 말씀 ────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _buildTodayVerse(),
              ),
            ),

            // ── 피드 탭바 ──────────────────────────────────────
            SliverPersistentHeader(
              pinned: true,
              delegate: _FeedTabDelegate(
                TabBar(
                  controller: _feedTabController,
                  tabs: const [
                    Tab(text: '기도 피드'),
                    Tab(text: '감사 피드'),
                  ],
                  labelColor: AppTheme.primary,
                  unselectedLabelColor: AppTheme.textSecondary,
                  indicatorColor: AppTheme.primary,
                  indicatorWeight: 2.5,
                  labelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),

            // ── 피드 컨텐츠 ────────────────────────────────────
            SliverFillRemaining(
              child: TabBarView(
                controller: _feedTabController,
                children: [
                  _PrayerFeedTab(onGoToPrayers: _goToPrayersTab),
                  _GratitudeFeedTab(onGoToGratitude: _goToGratitudeTab),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 앱바 ────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      title: const Text(
        'Intercesso',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 20,
          color: AppTheme.primary,
          letterSpacing: -0.3,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: AppTheme.textPrimary),
          onPressed: () => context.push('/notifications'),
        ),
      ],
    );
  }

  // ── 개인/교회 모드 토글 ──────────────────────────────────────
  Widget _buildModeToggle() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4F8),
          borderRadius: BorderRadius.circular(14),
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
      onTap: () => setState(() => _isPersonalMode = isPersonal),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
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
            ),
          ),
        ),
      ),
    );
  }

  // ── 인사말 카드 ───────────────────────────────────────────────
  Widget _buildGreetingCard(dynamic user, dynamic streak) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? '좋은 아침이에요' : hour < 18 ? '안녕하세요' : '좋은 저녁이에요';
    final timeEmoji = hour < 12 ? '☀️' : hour < 18 ? '🌤️' : '🌙';
    final hasStreak = streak.currentStreak > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 아바타
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00AAFF), Color(0xFF0088DD)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  image: user?.profileImageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(user!.profileImageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: user?.profileImageUrl == null
                    ? Center(
                        child: Text(
                          (user?.nickname ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              // 텍스트
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                        children: [
                          TextSpan(text: '$greeting, '),
                          TextSpan(
                            text: '${user?.nickname ?? ''}님',
                            style: const TextStyle(color: AppTheme.primary),
                          ),
                          TextSpan(text: ' $timeEmoji'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '오늘도 함께 기도해요',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // 스트릭 배지
          if (hasStreak) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFB800), Color(0xFFFF9500)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    '${streak.currentStreak}일 연속 기도 + 감사 작성 중!  😄',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── 빠른 액션 버튼 ────────────────────────────────────────────
  Widget _buildQuickActions(GratitudeProvider gratProvider) {
    return Row(
      children: [
        // 기도제목 작성
        Expanded(
          child: GestureDetector(
            onTap: () => context.push('/prayer/create'),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00AAFF), Color(0xFF0088DD)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00AAFF).withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🙏', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 6),
                  Text(
                    '기도제목 작성',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
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
            onTap: () {
              final mainState = context.findAncestorStateOfType<MainTabScreenState>();
              mainState?.switchToTab(2);
            },
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    gratProvider.hasTodayJournal ? '✅' : '🌷',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    gratProvider.hasTodayJournal ? '감사일기 완료' : '감사일기 쓰기',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── 오늘의 말씀 ───────────────────────────────────────────────
  Widget _buildTodayVerse() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '오늘의 말씀',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3DBFA6), Color(0xFF108981)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF108981).withValues(alpha: 0.3),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // 장식 테두리 상단
              Container(
                height: 2,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              const Text('📖', style: TextStyle(fontSize: 28)),
              const SizedBox(height: 12),
              Text(
                _todayVerse['text'] ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  height: 1.5,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _todayVerse['reference'] ?? '',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Text(
                  _todayVerse['reference'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                height: 2,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── 기도 피드 탭 ───────────────────────────────────────────────
class _PrayerFeedTab extends StatelessWidget {
  final VoidCallback onGoToPrayers;
  const _PrayerFeedTab({required this.onGoToPrayers});

  @override
  Widget build(BuildContext context) {
    return Consumer<PrayerProvider>(
      builder: (_, provider, __) {
        final prayers = provider.homePrayers;
        final isLoading = provider.isHomeLoading;

        if (isLoading && prayers.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (prayers.isEmpty) {
          return _buildEmpty(context);
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          itemCount: prayers.take(5).length + 1,
          itemBuilder: (_, i) {
            final list = prayers.take(5).toList();
            if (i == list.length) {
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton(
                  onPressed: onGoToPrayers,
                  child: const Text('기도 목록 전체보기 →'),
                ),
              );
            }
            final prayer = list[i];
            return _PrayerFeedCard(prayer: prayer);
          },
        );
      },
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.push('/prayer/create'),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('기도 작성하기'),
          ),
        ],
      ),
    );
  }
}

class _PrayerFeedCard extends StatelessWidget {
  final dynamic prayer;
  const _PrayerFeedCard({required this.prayer});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/prayer/${prayer.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.primaryLight,
                  backgroundImage: prayer.user?.profileImageUrl != null
                      ? NetworkImage(prayer.user!.profileImageUrl!)
                      : null,
                  child: prayer.user?.profileImageUrl == null
                      ? Text(
                          (prayer.user?.nickname ?? '?')[0],
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
            const SizedBox(height: 10),
            Text(
              prayer.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            if (prayer.content != null && prayer.content!.isNotEmpty) ...[
              const SizedBox(height: 4),
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
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('🙏', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  '${prayer.prayerCount ?? 0}명',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.chat_bubble_outline_rounded,
                    size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${prayer.commentCount ?? 0}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
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

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inHours < 1) return '${diff.inMinutes}분 전';
    if (diff.inDays < 1) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }
}

// ── 감사 피드 탭 ───────────────────────────────────────────────
class _GratitudeFeedTab extends StatelessWidget {
  final VoidCallback onGoToGratitude;
  const _GratitudeFeedTab({required this.onGoToGratitude});

  @override
  Widget build(BuildContext context) {
    return Consumer<GratitudeProvider>(
      builder: (_, provider, __) {
        final journals = provider.getFeedByTab('group');
        final isLoading = provider.isFeedLoading('group');

        if (isLoading && journals.isEmpty) {
          // 홈에서 첫 진입 시 로드
          WidgetsBinding.instance.addPostFrameCallback((_) {
            provider.loadFeed('group');
          });
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (journals.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
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
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: onGoToGratitude,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                  ),
                  icon: const Text('🌷', style: TextStyle(fontSize: 16)),
                  label: const Text('감사일기 쓰기'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          itemCount: journals.take(5).length + 1,
          itemBuilder: (_, i) {
            final list = journals.take(5).toList();
            if (i == list.length) {
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton(
                  onPressed: onGoToGratitude,
                  child: const Text(
                    '감사 피드 전체보기 →',
                    style: TextStyle(color: Color(0xFFF59E0B)),
                  ),
                ),
              );
            }
            final journal = list[i];
            return _GratitudeFeedCard(journal: journal);
          },
        );
      },
    );
  }
}

class _GratitudeFeedCard extends StatelessWidget {
  final dynamic journal;
  const _GratitudeFeedCard({required this.journal});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFDE68A),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFFEF3C7),
                backgroundImage: journal.user?.profileImageUrl != null
                    ? NetworkImage(journal.user!.profileImageUrl!)
                    : null,
                child: journal.user?.profileImageUrl == null
                    ? Text(
                        (journal.user?.nickname ?? '?')[0],
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFD97706),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '감사 🙌',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFD97706),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 감사 3가지
          Text(
            '감사 3가지',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF92400E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '1. ${journal.gratitude1}',
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textPrimary,
              height: 1.5,
            ),
          ),
          if (journal.gratitude2 != null && journal.gratitude2!.isNotEmpty)
            Text(
              '2. ${journal.gratitude2}',
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textPrimary,
                height: 1.5,
              ),
            ),
          if (journal.gratitude3 != null && journal.gratitude3!.isNotEmpty)
            Text(
              '3. ${journal.gratitude3}',
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textPrimary,
                height: 1.5,
              ),
            ),
          const SizedBox(height: 10),
          // 감정 이모지 + 반응
          Row(
            children: [
              if (journal.emotion != null) ...[
                Text(
                  journal.emotionEmoji,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 6),
              ],
              const Text('❤️', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 2),
              Text(
                '${journal.reactionCounts['grace'] ?? 0}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              const Text('👏', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 2),
              Text(
                '${journal.reactionCounts['empathy'] ?? 0}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chat_bubble_outline_rounded,
                  size: 14, color: AppTheme.textSecondary),
              const SizedBox(width: 2),
              Text(
                '${journal.commentCount}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 피드 탭바 Delegate ─────────────────────────────────────────
class _FeedTabDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _FeedTabDelegate(this.tabBar);

  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _FeedTabDelegate old) => old.tabBar != tabBar;
}
