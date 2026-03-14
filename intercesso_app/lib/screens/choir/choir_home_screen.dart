import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/choir_provider.dart';
import '../../models/choir_models.dart';

// ═══════════════════════════════════════════════════════════════
// 찬양대 홈 화면
// ═══════════════════════════════════════════════════════════════
class ChoirHomeScreen extends StatefulWidget {
  const ChoirHomeScreen({super.key});

  @override
  State<ChoirHomeScreen> createState() => _ChoirHomeScreenState();
}

class _ChoirHomeScreenState extends State<ChoirHomeScreen> {
  // 보라색 테마 컬러 (const로 const 위젯에서 사용)
  static const Color _purple = AppTheme.seonggadae;

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
            backgroundColor: AppTheme.seonggadae,
            body: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
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
        backgroundColor: _purple,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('찬양대',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () => context.push('/choir/management'),
          ),
        ],
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
                  color: _purple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.music_note_rounded,
                    size: 48, color: _purple),
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
                    fontSize: 14, color: AppTheme.textSecondary, height: 1.6),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/choir/create'),
                  icon: const Icon(Icons.add),
                  label: const Text('찬양대 만들기'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
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
                    foregroundColor: _purple,
                    side: const BorderSide(color: _purple),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
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
      backgroundColor: AppColors.bgTertiary,
      body: Column(
        children: [
          // ── 보라색 헤더 영역 ──────────────────────────────────
          _buildHeader(context, choir, selected),
          // ── 스크롤 가능한 콘텐츠 ─────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 다음 일정 카드
                  if (choir.nextSchedule != null)
                    _buildNextScheduleCard(context, choir.nextSchedule!),
                  const SizedBox(height: 24),

                  // 이번 주 일정
                  _buildThisWeekSection(context, choir),
                  const SizedBox(height: 24),

                  // 공지사항
                  _buildNoticesSection(context, choir),
                  const SizedBox(height: 24),

                  // 빠른 메뉴
                  _buildQuickMenu(context),
                  const SizedBox(height: 24),

                  // 단원 현황
                  _buildMemberPreview(context, choir),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 보라색 헤더 ───────────────────────────────────────────────
  Widget _buildHeader(
      BuildContext context, ChoirProvider choir, ChoirModel selected) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.seonggadae, AppTheme.seonggadaeDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단 바: 뒤로가기 + 설정
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: Colors.white),
                    onPressed: () => context.push('/choir/management'),
                  ),
                ],
              ),
              // 찬양대명 + 종 아이콘
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => _showChoirSelector(context, choir),
                      child: Row(
                        children: [
                          Text(
                            selected.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.keyboard_arrow_down,
                              color: Colors.white70, size: 22),
                        ],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined,
                          color: Colors.white, size: 26),
                      onPressed: () => context.push('/notifications'),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '${selected.churchName ?? '교회'} · 단원 ${selected.memberCount}명',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  // ── 다음 일정 카드 ────────────────────────────────────────────
  Widget _buildNextScheduleCard(
      BuildContext context, ChoirScheduleModel schedule) {
    return GestureDetector(
      onTap: () => context.push('/choir/schedule/${schedule.id}'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.seonggadae, AppTheme.seonggadaeDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.seonggadae.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단: '다음 일정' 뱃지 + 음표 아이콘
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '다음 일정',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(),
                // 음표 아이콘 (우상단)
                Icon(
                  Icons.music_note,
                  color: Colors.white.withOpacity(0.6),
                  size: 28,
                ),
              ],
            ),
            const SizedBox(height: 14),
            // 제목
            Text(
              schedule.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            // 날짜·시간·장소
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 13, color: Colors.white70),
                const SizedBox(width: 4),
                Text(
                  schedule.formattedDate,
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.access_time_outlined,
                    size: 13, color: Colors.white70),
                const SizedBox(width: 4),
                Text(
                  schedule.formattedTime,
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
                if (schedule.location != null) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.location_on_outlined,
                      size: 13, color: Colors.white70),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      schedule.location!,
                      style:
                          const TextStyle(fontSize: 13, color: Colors.white70),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            if (schedule.isConfirmed) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
            padding: const EdgeInsets.symmetric(vertical: 20),
            alignment: Alignment.center,
            child: const Text(
              '이번 주 일정이 없어요',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: weekSchedules.asMap().entries.map((entry) {
                final idx = entry.key;
                final s = entry.value;
                return Column(
                  children: [
                    if (idx > 0)
                      const Divider(height: 1, indent: 68, endIndent: 0),
                    _buildScheduleRow(context, s),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildScheduleRow(BuildContext context, ChoirScheduleModel schedule) {
    return InkWell(
      onTap: () => context.push('/choir/schedule/${schedule.id}'),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // 원형 이모지 아이콘
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _purple.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  schedule.scheduleType.emoji,
                  style: const TextStyle(fontSize: 20),
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
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
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
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.seonggadaeLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '확정',
                  style: TextStyle(
                    fontSize: 12,
                    color: _purple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right,
                size: 18, color: AppTheme.textLight),
          ],
        ),
      ),
    );
  }

  // ── 공지사항 섹션 ─────────────────────────────────────────────
  Widget _buildNoticesSection(BuildContext context, ChoirProvider choir) {
    final pinnedNotices = choir.notices.where((n) => n.isPinned).take(2).toList();
    final recentNotices =
        choir.notices.where((n) => !n.isPinned).take(2).toList();
    final displayNotices =
        [...pinnedNotices, ...recentNotices].take(3).toList();

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
            padding: const EdgeInsets.symmetric(vertical: 20),
            alignment: Alignment.center,
            child: const Text(
              '공지사항이 없어요',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: displayNotices.asMap().entries.map((entry) {
                final idx = entry.key;
                final notice = entry.value;
                return Column(
                  children: [
                    if (idx > 0)
                      const Divider(height: 1, indent: 54, endIndent: 0),
                    InkWell(
                      onTap: () {},
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            // 핀 or 일반 아이콘
                            Icon(
                              notice.isPinned
                                  ? Icons.push_pin
                                  : Icons.article_outlined,
                              size: 18,
                              color: notice.isPinned
                                  ? _purple
                                  : AppTheme.textLight,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    notice.title,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    notice.timeAgo,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right,
                                size: 18, color: AppTheme.textLight),
                          ],
                        ),
                      ),
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
  Widget _buildQuickMenu(BuildContext context) {
    final items = [
      _QuickMenuItem(
          icon: Icons.calendar_month,
          label: '일정',
          color: AppTheme.primary,
          route: '/choir/schedules'),
      _QuickMenuItem(
          icon: Icons.people,
          label: '회원',
          color: AppTheme.success,
          route: '/choir/members'),
      _QuickMenuItem(
          icon: Icons.how_to_reg,
          label: '출석',
          color: AppTheme.warning,
          route: '/choir/stats'),
      _QuickMenuItem(
          icon: Icons.library_music,
          label: '자료실',
          color: _purple,
          route: '/choir/library'),
      _QuickMenuItem(
          icon: Icons.queue_music,
          label: '곡 관리',
          color: AppColors.info,
          route: '/choir/songs'),
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
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
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
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: item.color.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(item.icon, color: item.color, size: 20),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.label,
                        style: const TextStyle(
                          fontSize: 11,
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

  // ── 단원 현황 ─────────────────────────────────────────────────
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
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
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: _purple,
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
              Row(
                children: [
                  ...previewMembers.map((m) => _memberAvatar(m)),
                  if (choir.activeMembers.length > 5)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: AppTheme.seonggadaeLight,
                        child: Text(
                          '+${choir.activeMembers.length - 5}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: _purple,
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
      padding: const EdgeInsets.only(right: 6),
      child: CircleAvatar(
        radius: 18,
        backgroundColor: _purple.withOpacity(0.15),
        backgroundImage: member.profileImageUrl != null
            ? NetworkImage(member.profileImageUrl!)
            : null,
        child: member.profileImageUrl == null
            ? Text(
                member.name.isNotEmpty ? member.name[0] : '?',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _purple,
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
      backgroundColor: Colors.white,
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
                      color: _purple.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.music_note,
                        color: _purple, size: 20),
                  ),
                  title: Text(
                    c.name,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? _purple : AppTheme.textPrimary,
                    ),
                  ),
                  subtitle: c.churchName != null
                      ? Text(c.churchName!,
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary))
                      : null,
                  trailing: isSelected
                      ? const Icon(Icons.check_circle,
                          color: _purple, size: 20)
                      : null,
                  onTap: () {
                    choir.selectChoir(c);
                    Navigator.pop(context);
                  },
                );
              }),
              const Divider(),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add,
                      color: AppTheme.textSecondary, size: 20),
                ),
                title: const Text('새 찬양대 만들기',
                    style: TextStyle(color: AppTheme.textSecondary)),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/choir/create');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ── 섹션 헤더 ─────────────────────────────────────────────────
  Widget _sectionHeader(String title,
      {String? trailing, VoidCallback? onTap}) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              trailing,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _purple,
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

// ── 빠른 메뉴 아이템 모델 ─────────────────────────────────────
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
