import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/choir_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/choir_models.dart';

// ═══════════════════════════════════════════════════════════════
// 회원 목록 화면
// ═══════════════════════════════════════════════════════════════
class ChoirMembersScreen extends StatefulWidget {
  const ChoirMembersScreen({super.key});

  @override
  State<ChoirMembersScreen> createState() => _ChoirMembersScreenState();
}

class _ChoirMembersScreenState extends State<ChoirMembersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  ChoirSection _filterSection = ChoirSection.all;
  String? _currentUserId;
  bool _adminMode = false;

  @override
  void initState() {
    super.initState();
    // 탭 수는 권한에 따라 달라지므로 최대값(2)으로 초기화
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ChoirProvider, AuthProvider>(
      builder: (context, choir, auth, _) {
        _currentUserId = auth.user?.id;
        _adminMode = choir.isAdmin(_currentUserId) || choir.isOwner(_currentUserId);
        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: Text(_adminMode ? '단원 관리' : '단원 목록'),
            backgroundColor: AppTheme.surface,
            elevation: 0,
            bottom: TabBar(
              controller: _tabController,
              labelColor: AppTheme.success,
              unselectedLabelColor: AppTheme.textSecondary,
              indicatorColor: AppTheme.success,
              tabs: [
                Tab(text: '단원 (${choir.activeMembers.length})'),
                if (_adminMode)
                  Tab(text: '가입 대기 (${choir.pendingMembers.length})'),
              ],
            ),
          ),
          floatingActionButton: _adminMode
              ? FloatingActionButton.extended(
                  onPressed: () => _showAddMemberSheet(context, choir),
                  backgroundColor: AppTheme.success,
                  icon: const Icon(Icons.person_add, color: Colors.white),
                  label: const Text('단원 추가',
                      style: TextStyle(color: Colors.white)),
                )
              : null,
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildMemberList(context, choir),
              if (_adminMode) _buildPendingList(context, choir),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMemberList(BuildContext context, ChoirProvider choir) {
    return Column(
      children: [
        // 검색 + 파트 필터
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: [
              TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: '이름 검색',
                  prefixIcon: const Icon(Icons.search,
                      size: 20, color: AppTheme.textSecondary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () =>
                              setState(() => _searchQuery = ''),
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [ChoirSection.all, ChoirSection.soprano,
                    ChoirSection.alto, ChoirSection.tenor, ChoirSection.bass]
                      .map((s) {
                    final selected = _filterSection == s;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(
                            '${s.emoji} ${s.label}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: selected
                                  ? AppTheme.success
                                  : AppTheme.textSecondary,
                            )),
                        selected: selected,
                        onSelected: (_) =>
                            setState(() => _filterSection = s),
                        selectedColor:
                            AppTheme.success.withOpacity(0.15),
                        checkmarkColor: AppTheme.success,
                        backgroundColor: AppTheme.surface,
                        side: BorderSide(
                          color: selected
                              ? AppTheme.success
                              : AppTheme.border,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildFilteredMemberList(context, choir),
        ),
      ],
    );
  }

  Widget _buildFilteredMemberList(BuildContext context, ChoirProvider choir) {
    var members = choir.getMembersBySection(_filterSection);
    if (_searchQuery.isNotEmpty) {
      members = members
          .where(
              (m) => m.name.contains(_searchQuery))
          .toList();
    }

    if (members.isEmpty) {
      return const Center(
        child: Text('단원이 없어요', style: TextStyle(color: AppTheme.textSecondary)),
      );
    }

    // 섹션별 그룹핑 (all 필터일 때)
    if (_filterSection == ChoirSection.all && _searchQuery.isEmpty) {
      return _buildGroupedList(context, members, choir);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: members.length,
      itemBuilder: (ctx, i) =>
          _buildMemberCard(context, members[i], choir),
    );
  }

  Widget _buildGroupedList(BuildContext context,
      List<ChoirMemberModel> members, ChoirProvider choir) {
    final sections = [
      ChoirSection.soprano,
      ChoirSection.alto,
      ChoirSection.tenor,
      ChoirSection.bass,
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: sections.map((section) {
        final sectionMembers =
            members.where((m) => m.section == section).toList();
        if (sectionMembers.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 12),
              child: Row(
                children: [
                  Text(
                    '${section.emoji} ${section.label}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${sectionMembers.length}명',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...sectionMembers.map(
                (m) => _buildMemberCard(context, m, choir)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildMemberCard(
      BuildContext context, ChoirMemberModel member, ChoirProvider choir) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: AppTheme.success.withOpacity(0.15),
          backgroundImage: member.profileImageUrl != null
              ? NetworkImage(member.profileImageUrl!)
              : null,
          child: member.profileImageUrl == null
              ? Text(
                  member.name.isNotEmpty ? member.name[0] : '?',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.success,
                  ),
                )
              : null,
        ),
        title: Row(
          children: [
            Text(
              member.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.seonggadae.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${member.role.emoji} ${member.role.label}',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.seonggadae,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          '${member.section.emoji} ${member.section.label}'
          '${member.phone != null ? ' · ${member.phone}' : ''}',
          style: const TextStyle(
              fontSize: 12, color: AppTheme.textSecondary),
        ),
        trailing: _buildMemberTrailing(context, member, choir),
      ),
    );
  }

  Widget _buildMemberTrailing(
      BuildContext context, ChoirMemberModel member, ChoirProvider choir) {
    final isMe = member.userId == _currentUserId;
    if (isMe) {
      return IconButton(
        icon: const Icon(Icons.edit_outlined,
            size: 18, color: AppTheme.seonggadae),
        tooltip: '내 정보 수정',
        onPressed: () => _onMemberAction(context, 'edit', member, choir),
      );
    }
    if (_adminMode) {
      return PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert,
            size: 18, color: AppTheme.textLight),
        onSelected: (action) =>
            _onMemberAction(context, action, member, choir),
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'edit', child: Text('정보 수정')),
          const PopupMenuItem(
              value: 'remove',
              child: Text('내보내기',
                  style: TextStyle(color: Colors.red))),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildPendingList(BuildContext context, ChoirProvider choir) {
    if (choir.pendingMembers.isEmpty) {
      return const Center(
        child: Text(
          '가입 대기 중인 단원이 없어요',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: choir.pendingMembers.length,
      itemBuilder: (ctx, i) {
        final member = choir.pendingMembers[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.textLight.withOpacity(0.2),
              child: Text(
                member.name.isNotEmpty ? member.name[0] : '?',
                style: const TextStyle(
                    color: AppTheme.textSecondary),
              ),
            ),
            title: Text(member.name,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: Text(
                '${member.section.label} · 가입 신청 중',
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check_circle,
                      color: AppTheme.success),
                  onPressed: () async {
                    await choir.approveMember(member.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('${member.name}님을 승인했습니다')),
                      );
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: AppTheme.error),
                  onPressed: () async {
                    await choir.removeMember(member.id);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onMemberAction(BuildContext context, String action,
      ChoirMemberModel member, ChoirProvider choir) {
    if (action == 'edit') {
      _showEditMemberSheet(context, member, choir);
    } else if (action == 'remove') {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('단원 삭제'),
          content: Text('${member.name}님을 찬양대에서 삭제할까요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await choir.removeMember(member.id);
              },
              style:
                  TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('삭제'),
            ),
          ],
        ),
      );
    }
  }

  // ── 단원 추가 바텀시트 ────────────────────────────────────────
  void _showAddMemberSheet(BuildContext context, ChoirProvider choir) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _MemberFormSheet(choir: choir),
    );
  }

  // ── 단원 수정 바텀시트 ────────────────────────────────────────
  void _showEditMemberSheet(
      BuildContext context, ChoirMemberModel member, ChoirProvider choir) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _MemberFormSheet(choir: choir, editMember: member),
    );
  }
}

// ─── 단원 추가/수정 폼 바텀시트 ──────────────────────────────────
class _MemberFormSheet extends StatefulWidget {
  final ChoirProvider choir;
  final ChoirMemberModel? editMember;
  const _MemberFormSheet({required this.choir, this.editMember});

  @override
  State<_MemberFormSheet> createState() => _MemberFormSheetState();
}

class _MemberFormSheetState extends State<_MemberFormSheet> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late ChoirSection _section;
  late ChoirRole _role;
  bool _isLoading = false;

  bool get isEdit => widget.editMember != null;

  @override
  void initState() {
    super.initState();
    final m = widget.editMember;
    _nameController = TextEditingController(text: m?.name ?? '');
    _phoneController = TextEditingController(text: m?.phone ?? '');
    _section = m?.section ?? ChoirSection.soprano;
    _role = m?.role ?? ChoirRole.member;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
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
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  isEdit ? '단원 수정' : '단원 추가',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 이름
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: '이름 *'),
            ),
            const SizedBox(height: 12),
            // 파트
            const Text('성부 (파트) *',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoirSection.soprano,
                ChoirSection.alto,
                ChoirSection.tenor,
                ChoirSection.bass,
              ].map((s) {
                final selected = _section == s;
                return ChoiceChip(
                  label: Text('${s.emoji} ${s.label}'),
                  selected: selected,
                  onSelected: (_) => setState(() => _section = s),
                  selectedColor:
                      AppTheme.success.withOpacity(0.15),
                  labelStyle: TextStyle(
                    color: selected
                        ? AppTheme.success
                        : AppTheme.textSecondary,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w400,
                    fontSize: 12,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            // 역할
            const Text('역할 *',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ChoirRole.values.map((r) {
                final selected = _role == r;
                return ChoiceChip(
                  label: Text('${r.emoji} ${r.label}'),
                  selected: selected,
                  onSelected: (_) => setState(() => _role = r),
                  selectedColor:
                      AppTheme.seonggadae.withOpacity(0.15),
                  labelStyle: TextStyle(
                    color: selected
                        ? AppTheme.seonggadae
                        : AppTheme.textSecondary,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w400,
                    fontSize: 12,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            // 전화번호
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: '전화번호 (선택)',
                hintText: '010-0000-0000',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(isEdit ? '수정 완료' : '단원 추가',
                        style: const TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이름을 입력해주세요')),
      );
      return;
    }
    setState(() => _isLoading = true);
    bool ok;
    if (isEdit) {
      ok = await widget.choir.updateMember(
        widget.editMember!.id,
        name: _nameController.text.trim(),
        section: _section,
        role: _role,
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
      );
    } else {
      ok = await widget.choir.addMember(
        choirId: widget.choir.selectedChoir?.id ?? '',
        name: _nameController.text.trim(),
        section: _section,
        role: _role,
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
      );
    }
    setState(() => _isLoading = false);
    if (ok && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                isEdit ? '단원 정보가 수정되었습니다' : '단원이 추가되었습니다')),
      );
    }
  }
}
