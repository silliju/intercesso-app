import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/choir_provider.dart';
import '../../models/choir_models.dart';

class ChoirHomeScreen extends StatefulWidget {
  const ChoirHomeScreen({super.key});

  @override
  State<ChoirHomeScreen> createState() => _ChoirHomeScreenState();
}

class _ChoirHomeScreenState extends State<ChoirHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChoirProvider>().loadMyChoirs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChoirProvider>(
      builder: (context, choir, _) {
        if (choir.isLoading && choir.myChoirs.isEmpty) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (choir.myChoirs.isEmpty) {
          return _buildNoChoirView(context);
        }

        return _buildChoirHome(context, choir);
      },
    );
  }

  // ── 찬양대 없을 때 화면 ──────────────────────────────────────
  Widget _buildNoChoirView(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('찬양대'),
        backgroundColor: AppTheme.surface,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: const Color(0xFF885CF6).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.music_note_rounded,
                  size: 48,
                  color: Color(0xFF885CF6),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '소속된 찬양대가 없어요',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '찬양대를 만들거나\n초대 코드로 참여해보세요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/choir/create'),
                  icon: const Icon(Icons.add),
                  label: const Text('찬양대 만들기'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF885CF6),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/choir/join'),
                  icon: const Icon(Icons.link),
                  label: const Text('초대 코드로 참여'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF885CF6),
                    side: const BorderSide(color: Color(0xFF885CF6)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 찬양대 홈 메인 ───────────────────────────────────────────
  Widget _buildChoirHome(BuildContext context, ChoirProvider choir) {
    final selected = choir.selectedChoir;
    if (selected == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, choir, selected),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 다음 일정 카드
                  if (choir.nextSchedule != null)
                    _buildNextScheduleCard(context, choir.nextSchedule!),
                  const SizedBox(height: 20),

                  // 이번 주 일정
                  _buildThisWeekSection(context, choir),
                  const SizedBox(height: 20),

                  // 공지사항
                  _buildNoticesSection(context, choir),
                  const SizedBox(height: 20),

                  // 빠른 메뉴
                  _buildQuickMenu(context, selected.id),
                  const SizedBox(height: 20),

                  // 멤버 섹션 미리보기
                  _buildMemberPreview(context, choir),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── SliverAppBar ─────────────────────────────────────────────
  Widget _buildSliverAppBar(
      BuildContext context, ChoirProvider choir, ChoirModel selected) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: const Color(0xFF885CF6),
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF885CF6), Color(0xFF6D3FD4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      // 찬양대 선택 드롭다운
                      GestureDetector(
                        onTap: () => _showChoirSelector(context, choir),
                        child: Row(
                          children: [
                            Text(
                              selected.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            if (choir.myChoirs.length > 1) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.white70,
                                size: 20,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined,
                            color: Colors.white),
                        onPressed: () => context.push('/notifications'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${selected.churchName ?? ''} · 단원 ${selected.memberCount}명',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: Colors.white),
          onPressed: () => context.push('/choir/management'),
        ),
      ],
    );
  }

  // ── 다음 일정 카드 ────────────────────────────────────────────
  Widget _buildNextScheduleCard(
      BuildContext context, ChoirScheduleModel schedule) {
    return GestureDetector(
      onTap: () => context.push('/choir/schedule/${schedule.id}'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF885CF6), Color(0xFF6D3FD4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF885CF6).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
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
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '다음 일정',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  schedule.scheduleType.emoji,
                  style: const TextStyle(fontSize: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              schedule.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 14, color: Colors.white70),
                const SizedBox(width: 4),
                Text(
                  schedule.formattedDate,
                  style: const TextStyle(
                      fontSize: 13, color: Colors.white70),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.access_time, size: 14, color: Colors.white70),
                const SizedBox(width: 4),
                Text(
                  schedule.formattedTime,
                  style: const TextStyle(
                      fontSize: 13, color: Colors.white70),
                ),
                if (schedule.location != null) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.location_on, size: 14, color: Colors.white70),
                  const SizedBox(width: 4),
                  Text(
                    schedule.location!,
                    style: const TextStyle(
                        fontSize: 13, color: Colors.white70),
                  ),
                ],
              ],
            ),
            if (schedule.isConfirmed) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '✓ 확정',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── 이번 주 일정 섹션 ─────────────────────────────────────────
  Widget _buildThisWeekSection(BuildContext context, ChoirProvider choir) {
    final weekSchedules = choir.thisWeekSchedules;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          '이번 주 일정',
          onTap: () => context.push('/choir/schedules'),
        ),
        const SizedBox(height: 12),
        if (weekSchedules.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Center(
              child: Text(
                '이번 주 일정이 없어요',
                style: TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary),
              ),
            ),
          )
        else
          ...weekSchedules.map((s) => _buildScheduleRow(context, s)),
      ],
    );
  }

  Widget _buildScheduleRow(
      BuildContext context, ChoirScheduleModel schedule) {
    return GestureDetector(
      onTap: () => context.push('/choir/schedule/${schedule.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF885CF6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  schedule.scheduleType.emoji,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    schedule.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${schedule.formattedDate} ${schedule.formattedTime}'
                    '${schedule.location != null ? ' · ${schedule.location}' : ''}',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            if (schedule.isConfirmed)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '확정',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right,
                size: 18, color: AppTheme.textLight),
          ],
        ),
      ),
    );
  }

  // ── 공지사항 섹션 ─────────────────────────────────────────────
  Widget _buildNoticesSection(BuildContext context, ChoirProvider choir) {
    final pinnedNotices =
        choir.notices.where((n) => n.isPinned).take(2).toList();
    final recentNotices =
        choir.notices.where((n) => !n.isPinned).take(2).toList();
    final displayNotices = [...pinnedNotices, ...recentNotices].take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          '공지사항',
          onTap: () => context.push('/choir/notices'),
        ),
        const SizedBox(height: 12),
        if (displayNotices.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Center(
              child: Text(
                '공지사항이 없어요',
                style: TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: displayNotices.asMap().entries.map((entry) {
                final i = entry.key;
                final notice = entry.value;
                return Column(
                  children: [
                    if (i > 0) const Divider(height: 1),
                    ListTile(
                      leading: notice.isPinned
                          ? const Icon(Icons.push_pin,
                              size: 16, color: Color(0xFF885CF6))
                          : const Icon(Icons.article_outlined,
                              size: 16, color: AppTheme.textLight),
                      title: Text(
                        notice.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        notice.timeAgo,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      trailing: const Icon(Icons.chevron_right,
                          size: 18, color: AppTheme.textLight),
                      dense: true,
                      onTap: () {},
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  // ── 빠른 메뉴 ─────────────────────────────────────────────────
  Widget _buildQuickMenu(BuildContext context, String choirId) {
    final items = [
      _QuickMenuItem(icon: Icons.calendar_month, label: '일정', color: const Color(0xFF2F6FED), route: '/choir/schedules'),
      _QuickMenuItem(icon: Icons.people, label: '회원', color: const Color(0xFF10B981), route: '/choir/members'),
      _QuickMenuItem(icon: Icons.how_to_reg, label: '출석', color: const Color(0xFFF59E0B), route: '/choir/attendance'),
      _QuickMenuItem(icon: Icons.library_music, label: '자료실', color: const Color(0xFF885CF6), route: '/choir/library'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '빠른 메뉴',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: items.map((item) {
            return Expanded(
              child: GestureDetector(
                onTap: () => context.push(item.route),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: item.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(item.icon, color: item.color, size: 22),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.label,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── 멤버 미리보기 ─────────────────────────────────────────────
  Widget _buildMemberPreview(BuildContext context, ChoirProvider choir) {
    final previewMembers = choir.activeMembers.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          '단원 현황',
          trailing: '${choir.activeMembers.length}명',
          onTap: () => context.push('/choir/members'),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // 섹션별 인원
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ChoirSection.soprano,
                  ChoirSection.alto,
                  ChoirSection.tenor,
                  ChoirSection.bass,
                ].map((section) {
                  final count = choir.getMembersBySection(section).length;
                  return Column(
                    children: [
                      Text(
                        '$count',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF885CF6),
                        ),
                      ),
                      Text(
                        section.label,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              // 최근 멤버 아바타
              Row(
                children: [
                  ...previewMembers.map((m) => _memberAvatar(m)),
                  if (choir.activeMembers.length > 5)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: AppTheme.border,
                        child: Text(
                          '+${choir.activeMembers.length - 5}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _memberAvatar(ChoirMemberModel member) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: CircleAvatar(
        radius: 18,
        backgroundColor: const Color(0xFF885CF6).withOpacity(0.15),
        backgroundImage: member.profileImageUrl != null
            ? NetworkImage(member.profileImageUrl!)
            : null,
        child: member.profileImageUrl == null
            ? Text(
                member.name.isNotEmpty ? member.name[0] : '?',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF885CF6),
                ),
              )
            : null,
      ),
    );
  }

  // ── 찬양대 선택 바텀시트 ──────────────────────────────────────
  void _showChoirSelector(BuildContext context, ChoirProvider choir) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '찬양대 선택',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ...choir.myChoirs.map((c) {
                final isSelected = choir.selectedChoir?.id == c.id;
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF885CF6).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.music_note,
                        color: Color(0xFF885CF6), size: 20),
                  ),
                  title: Text(
                    c.name,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? const Color(0xFF885CF6)
                          : AppTheme.textPrimary,
                    ),
                  ),
                  subtitle: Text('${c.memberCount}명'),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle,
                          color: Color(0xFF885CF6))
                      : null,
                  onTap: () {
                    choir.selectChoir(c);
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/choir/create');
                },
                icon: const Icon(Icons.add),
                label: const Text('찬양대 추가'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF885CF6),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── 공통 섹션 헤더 ────────────────────────────────────────────
  Widget _sectionHeader(String title,
      {String? trailing, VoidCallback? onTap}) {
    return Row(
      children: [
        Text(title, style: AppTheme.sectionTitle),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF885CF6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              trailing,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF885CF6),
              ),
            ),
          ),
        ],
        const Spacer(),
        if (onTap != null)
          GestureDetector(
            onTap: onTap,
            child: const Text(
              '더 보기',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
      ],
    );
  }
}

class _QuickMenuItem {
  final IconData icon;
  final String label;
  final Color color;
  final String route;

  const _QuickMenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.route,
  });
}
