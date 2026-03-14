import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/choir_provider.dart';
import '../../models/choir_models.dart';

// ═══════════════════════════════════════════════════════════════
// 찬양대 관리 화면
// ═══════════════════════════════════════════════════════════════
class ChoirManagementScreen extends StatelessWidget {
  const ChoirManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChoirProvider>(
      builder: (context, choir, _) {
        final selected = choir.selectedChoir;
        if (selected == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: const Text('찬양대 설정'),
            backgroundColor: AppTheme.surface,
            elevation: 0,
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // 찬양대 정보 카드
              _buildChoirInfoCard(context, selected),
              const SizedBox(height: 20),
              // 초대 관리
              _buildInviteSection(context, choir, selected),
              const SizedBox(height: 20),
              // 가입 신청 관리
              if (choir.pendingMembers.isNotEmpty) ...[
                _buildPendingSection(context, choir),
                const SizedBox(height: 20),
              ],
              // 관리 메뉴
              _buildManagementMenu(context, choir, selected),
              const SizedBox(height: 20),
              // 위험 구역
              _buildDangerZone(context, choir, selected),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  // ── 찬양대 정보 카드 ──────────────────────────────────────────
  Widget _buildChoirInfoCard(BuildContext context, ChoirModel choir) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.seonggadae, AppTheme.seonggadaeDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.seonggadae.withOpacity(0.3),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      choir.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      choir.churchName ?? '',
                      style: const TextStyle(
                          fontSize: 13, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () =>
                    _showEditChoirSheet(context, choir),
                icon: const Icon(Icons.edit, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (choir.description != null)
            Text(
              choir.description!,
              style: const TextStyle(
                  fontSize: 13, color: Colors.white70),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.people, size: 16, color: Colors.white70),
              const SizedBox(width: 4),
              Text(
                '단원 ${choir.memberCount}명',
                style: const TextStyle(
                    fontSize: 13, color: Colors.white70),
              ),
              if (choir.worshipType != null) ...[
                const Text(' · ',
                    style: TextStyle(color: Colors.white70)),
                Text(
                  choir.worshipType!,
                  style: const TextStyle(
                      fontSize: 13, color: Colors.white70),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ── 초대 관리 섹션 ────────────────────────────────────────────
  Widget _buildInviteSection(
      BuildContext context, ChoirProvider choir, ChoirModel selected) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              '초대 관리',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const Divider(height: 1),
          // 초대 코드
          ListTile(
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.key,
                  size: 18, color: AppTheme.primary),
            ),
            title: const Text('초대 코드',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: Text(
              selected.inviteCode ?? '코드 없음',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.seonggadae,
                letterSpacing: 2,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.copy, size: 18,
                      color: AppTheme.textSecondary),
                  onPressed: () {
                    if (selected.inviteCode != null) {
                      Clipboard.setData(
                          ClipboardData(text: selected.inviteCode!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('초대 코드 복사됨')),
                      );
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18,
                      color: AppTheme.textSecondary),
                  onPressed: () async {
                    final code =
                        await choir.generateInviteCode(selected.id);
                    if (code != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('새 초대 코드: $code')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 초대 링크
          ListTile(
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.link,
                  size: 18, color: AppTheme.success),
            ),
            title: const Text('초대 링크 공유',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: const Text('링크로 단원을 초대합니다',
                style: TextStyle(fontSize: 12)),
            trailing: Switch(
              value: selected.inviteLinkActive,
              onChanged: (_) {},
              activeColor: AppTheme.success,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  final choir = context.read<ChoirProvider>();
                  final selected = choir.selectedChoir;
                  final code = selected?.inviteCode;
                  if (code != null) {
                    final shareText = '🎵 ${selected!.name} 찬양대에 함께해요!\n초대 코드: $code\n\nIntercesso 앱에서 참여하세요.';
                    Clipboard.setData(ClipboardData(text: shareText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('📋 초대 링크가 복사됐어요! 공유해 보세요'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.share, size: 16),
                label: const Text('초대 링크 공유하기'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.seonggadae,
                  side:
                      const BorderSide(color: AppTheme.seonggadae),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 가입 신청 섹션 ────────────────────────────────────────────
  Widget _buildPendingSection(BuildContext context, ChoirProvider choir) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.warning.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                const Text(
                  '⏳ 가입 신청',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.warning,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${choir.pendingMembers.length}명',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...choir.pendingMembers.take(3).map((m) {
            return ListTile(
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.textLight.withOpacity(0.2),
                child: Text(m.name.isNotEmpty ? m.name[0] : '?',
                    style: const TextStyle(
                        color: AppTheme.textSecondary)),
              ),
              title: Text(m.name,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: Text(m.section.label,
                  style: const TextStyle(fontSize: 11)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      await choir.approveMember(m.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('${m.name}님 승인됨')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      minimumSize: const Size(50, 30),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                    ),
                    child: const Text('승인',
                        style: TextStyle(
                            fontSize: 12, color: Colors.white)),
                  ),
                  const SizedBox(width: 4),
                  OutlinedButton(
                    onPressed: () async {
                      await choir.removeMember(m.id);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: const BorderSide(
                          color: AppTheme.error),
                      minimumSize: const Size(50, 30),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                    ),
                    child: const Text('거절',
                        style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            );
          }),
          if (choir.pendingMembers.length > 3)
            TextButton(
              onPressed: () => context.push('/choir/members'),
              child: Text(
                  '전체 보기 (${choir.pendingMembers.length}명)'),
              style: TextButton.styleFrom(
                  foregroundColor: AppTheme.seonggadae),
            ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ── 관리 메뉴 ─────────────────────────────────────────────────
  Widget _buildManagementMenu(
      BuildContext context, ChoirProvider choir, ChoirModel selected) {
    final items = [
      _MenuItem(
          icon: Icons.people,
          label: '단원 관리',
          color: AppTheme.success,
          onTap: () => context.push('/choir/members')),
      _MenuItem(
          icon: Icons.calendar_month,
          label: '일정 관리',
          color: AppTheme.primary,
          onTap: () => context.push('/choir/schedules')),
      _MenuItem(
          icon: Icons.library_music,
          label: '곡 관리',
          color: AppTheme.warning,
          onTap: () {}),
      _MenuItem(
          icon: Icons.library_books,
          label: '자료실',
          color: AppTheme.seonggadae,
          onTap: () => context.push('/choir/library')),
      _MenuItem(
          icon: Icons.bar_chart,
          label: '출석 통계',
          color: AppColors.info,
          onTap: () => context.push('/choir/stats')),
      _MenuItem(
          icon: Icons.notifications_outlined,
          label: '공지 관리',
          color: AppTheme.simbang,
          onTap: () {}),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              '관리 메뉴',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const Divider(height: 1),
          ...items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            return Column(
              children: [
                if (i > 0) const Divider(height: 1),
                ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: item.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item.icon,
                        size: 18, color: item.color),
                  ),
                  title: Text(item.label,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.chevron_right,
                      size: 18, color: AppTheme.textLight),
                  onTap: item.onTap,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ── 위험 구역 ─────────────────────────────────────────────────
  Widget _buildDangerZone(
      BuildContext context, ChoirProvider choir, ChoirModel selected) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: AppTheme.error.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              '주의',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.error,
              ),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout,
                color: AppTheme.textSecondary),
            title: const Text('찬양대 나가기',
                style: TextStyle(fontSize: 14)),
            trailing: const Icon(Icons.chevron_right,
                size: 18, color: AppTheme.textLight),
            onTap: () => _confirmLeave(context, selected),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete_forever,
                color: AppTheme.error),
            title: const Text(
              '찬양대 삭제',
              style: TextStyle(
                  fontSize: 14, color: AppTheme.error),
            ),
            trailing: const Icon(Icons.chevron_right,
                size: 18, color: AppTheme.textLight),
            onTap: () => _confirmDelete(context, selected),
          ),
        ],
      ),
    );
  }

  void _confirmLeave(BuildContext context, ChoirModel choir) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('찬양대 나가기'),
        content: Text('${choir.name}에서 나가시겠습니까?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            style: TextButton.styleFrom(
                foregroundColor: AppTheme.error),
            child: const Text('나가기'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, ChoirModel choir) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('찬양대 삭제'),
        content: Text(
          '${choir.name}을 삭제하면 모든 데이터가 삭제됩니다.\n정말로 삭제하시겠습니까?',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error),
            child: const Text('삭제',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditChoirSheet(BuildContext context, ChoirModel choir) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditChoirSheet(choir: choir),
    );
  }
}

// ─── 찬양대 정보 수정 바텀시트 ────────────────────────────────────
class _EditChoirSheet extends StatefulWidget {
  final ChoirModel choir;
  const _EditChoirSheet({required this.choir});

  @override
  State<_EditChoirSheet> createState() => _EditChoirSheetState();
}

class _EditChoirSheetState extends State<_EditChoirSheet> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _churchController;
  late TextEditingController _worshipController;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.choir.name);
    _descController =
        TextEditingController(text: widget.choir.description ?? '');
    _churchController =
        TextEditingController(text: widget.choir.churchName ?? '');
    _worshipController =
        TextEditingController(text: widget.choir.worshipType ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _churchController.dispose();
    _worshipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('찬양대 정보 수정',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration:
                  const InputDecoration(labelText: '찬양대 이름 *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _churchController,
              decoration:
                  const InputDecoration(labelText: '교회명'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _worshipController,
              decoration:
                  const InputDecoration(labelText: '예배 종류'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: '설명 (선택)'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('찬양대 정보가 수정되었습니다')),
                  );
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.seonggadae,
                    padding:
                        const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('수정 완료',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}
