import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/models.dart';
import '../../providers/gratitude_provider.dart';
import '../../providers/auth_provider.dart';
import 'gratitude_detail_screen.dart';

class GratitudeFeedScreen extends StatefulWidget {
  const GratitudeFeedScreen({super.key});

  @override
  State<GratitudeFeedScreen> createState() => _GratitudeFeedScreenState();
}

class _GratitudeFeedScreenState extends State<GratitudeFeedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _tabs = ['group', 'following', 'public'];
  final _tabLabels = ['🏠 우리 그룹', '👥 팔로우', '🌐 전체'];

  static Color get _choirPurple => AppTheme.seonggadae;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<GratitudeProvider>();
      // 그룹 탭 첫 로드
      provider.loadFeed('group');
      provider.loadStreak();
      provider.loadTodayJournal();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          _buildAppBar(),
          _buildStreakBanner(),
          _buildTabBar(),
        ],
        body: TabBarView(
          controller: _tabController,
          children: _tabs.map((tab) => _FeedTabView(tab: tab)).toList(),
        ),
      ),
      // FAB는 MainTabScreen에서 관리 (중복 방지)
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: _choirPurple,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.seonggadae, AppTheme.seonggadaeDark],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Text(
                        '은혜 나눔 🎵',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.calendar_month_outlined, color: Colors.white),
                        onPressed: () => context.push('/gratitude/calendar'),
                      ),
                    ],
                  ),
                  const Text(
                    '오늘 받은 은혜를 찬양으로 나눠요',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStreakBanner() {
    return SliverToBoxAdapter(
      child: Consumer<GratitudeProvider>(
        builder: (_, provider, __) {
          final streak = provider.streak;
          if (streak.currentStreak == 0) return const SizedBox.shrink();
          return Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.gamsaLight, AppTheme.primaryLight],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.gamsaBorder),
            ),
            child: Row(
              children: [
                const Text('🎶', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${streak.currentStreak}일 연속 은혜 기록 중!',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppTheme.seonggadaeDark,
                        ),
                      ),
                      Text(
                        '총 ${streak.totalCount}번 은혜를 기록했어요',
                        style: const TextStyle(fontSize: 12, color: AppTheme.seonggadae),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _choirPurple,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '최고 ${streak.longestStreak}일',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _TabBarDelegate(
        TabBar(
          controller: _tabController,
          tabs: _tabLabels.map((l) => Tab(text: l)).toList(),
          labelColor: _choirPurple,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: _choirPurple,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          onTap: (i) {
            final tab = _tabs[i];
            final provider = context.read<GratitudeProvider>();
            if (provider.getFeedByTab(tab).isEmpty) {
              provider.loadFeed(tab);
            }
          },
        ),
      ),
    );
  }

}

// ── 탭 뷰 ─────────────────────────────────────────────────────
class _FeedTabView extends StatelessWidget {
  final String tab;
  const _FeedTabView({required this.tab});

  @override
  Widget build(BuildContext context) {
    return Consumer<GratitudeProvider>(
      builder: (_, provider, __) {
        final journals = provider.getFeedByTab(tab);
        final isLoading = provider.isFeedLoading(tab);
        final hasMore = provider.hasFeedMore(tab);

        if (isLoading && journals.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (journals.isEmpty) {
          return _buildEmpty();
        }

        return RefreshIndicator(
          color: AppTheme.seonggadae,
          onRefresh: () => provider.loadFeed(tab, refresh: true),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: journals.length + (hasMore ? 1 : 0),
            itemBuilder: (_, i) {
              if (i == journals.length) {
                provider.loadFeed(tab);
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return _GratitudeFeedCard(journal: journals[i], tab: tab);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmpty() {
    final messages = {
      'group': '그룹에 감사일기를 공유한 멤버가 없어요\n먼저 감사일기를 써보세요! 🌟',
      'following': '팔로우한 사람이 없거나\n아직 감사일기가 없어요',
      'public': '공개 감사일기가 없어요\n첫 번째로 공유해 보세요! ✨',
    };
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🌸', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 16),
          Text(
            messages[tab] ?? '감사일기가 없어요',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 피드 카드 ──────────────────────────────────────────────────
class _GratitudeFeedCard extends StatelessWidget {
  final GratitudeModel journal;
  final String tab;
  const _GratitudeFeedCard({required this.journal, required this.tab});

  @override
  Widget build(BuildContext context) {
    final user = journal.user;
    final authProvider = context.read<AuthProvider>();
    final isMyPost = journal.userId == authProvider.user?.id;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GratitudeDetailScreen(journalId: journal.id),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppTheme.primaryLight,
                    backgroundImage: user?.profileImageUrl != null
                        ? NetworkImage(user!.profileImageUrl!)
                        : null,
                    child: user?.profileImageUrl == null
                        ? Text(
                            (user?.nickname ?? '?')[0],
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              user?.nickname ?? '사용자',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (isMyPost) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryLight,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  '나',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              _formatDate(journal.journalDate),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            if (journal.emotion != null) ...[
                              const SizedBox(width: 6),
                              Text(
                                journal.emotionEmoji,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // 감사 내용
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _GratitudeItem(number: 1, text: journal.gratitude1),
                  if (journal.gratitude2 != null && journal.gratitude2!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _GratitudeItem(number: 2, text: journal.gratitude2!),
                  ],
                  if (journal.gratitude3 != null && journal.gratitude3!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _GratitudeItem(number: 3, text: journal.gratitude3!),
                  ],
                ],
              ),
            ),
            // 기도 연결
            if (journal.linkedPrayer != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.link_rounded, color: AppTheme.primary, size: 14),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          journal.linkedPrayer!['title'] ?? '기도제목',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            // 반응 바
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 4),
              child: Row(
                children: [
                  _ReactionButton(
                    journalId: journal.id,
                    reactionType: 'grace',
                    emoji: '🙏',
                    label: '은혜',
                    count: journal.reactionCounts['grace'] ?? 0,
                    isActive: journal.myReactions.contains('grace'),
                    tab: tab,
                  ),
                  _ReactionButton(
                    journalId: journal.id,
                    reactionType: 'empathy',
                    emoji: '🤍',
                    label: '공감',
                    count: journal.reactionCounts['empathy'] ?? 0,
                    isActive: journal.myReactions.contains('empathy'),
                    tab: tab,
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GratitudeDetailScreen(journalId: journal.id),
                      ),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                    label: Text(
                      journal.commentCount > 0 ? '${journal.commentCount}' : '댓글',
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final d = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(d).inDays;
      if (diff == 0) return '오늘';
      if (diff == 1) return '어제';
      return '${d.month}월 ${d.day}일';
    } catch (_) {
      return dateStr;
    }
  }
}

class _GratitudeItem extends StatelessWidget {
  final int number;
  final String text;
  const _GratitudeItem({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          margin: const EdgeInsets.only(top: 1),
          decoration: BoxDecoration(
            color: AppColors.warningBg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              '$number',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFFD97706),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReactionButton extends StatelessWidget {
  final String journalId;
  final String reactionType;
  final String emoji;
  final String label;
  final int count;
  final bool isActive;
  final String tab;

  const _ReactionButton({
    required this.journalId,
    required this.reactionType,
    required this.emoji,
    required this.label,
    required this.count,
    required this.isActive,
    required this.tab,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => context.read<GratitudeProvider>().toggleReaction(journalId, reactionType, tab),
      style: TextButton.styleFrom(
        foregroundColor: isActive ? AppTheme.gamsa : AppTheme.textSecondary,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        backgroundColor: isActive ? AppTheme.gamsaLight : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Text(
            count > 0 ? '$count $label' : label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// ── SliverPersistentHeaderDelegate ────────────────────────────
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);

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
  bool shouldRebuild(covariant _TabBarDelegate old) => old.tabBar != tabBar;
}
