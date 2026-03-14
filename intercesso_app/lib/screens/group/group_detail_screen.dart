import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../widgets/common_widgets.dart';
import '../../services/api_service.dart';
import '../../services/group_service.dart';
import '../../services/prayer_service.dart';
import '../../models/models.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupId;
  const GroupDetailScreen({super.key, required this.groupId});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  final GroupService _groupService = GroupService();
  final PrayerService _prayerService = PrayerService();

  GroupModel? _group;
  List<PrayerModel> _prayers = [];
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;
  bool _isPrayersLoading = true;
  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _currentTabIndex = _tabController.index);
      }
    });
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadGroup(), _loadGroupPrayers()]);
  }

  Future<void> _loadGroup() async {
    try {
      final response = await _api.get('/groups/${widget.groupId}');
      if (mounted) {
        setState(() {
          _group = GroupModel.fromJson(response['data']);
          _isLoading = false;
        });
        // 멤버 목록도 로드
        _loadMembers();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadGroupPrayers() async {
    try {
      final response = await _prayerService.getPrayers(
        page: 1,
        limit: 20,
        groupId: widget.groupId,
      );
      final List<dynamic> data = response['data'] ?? [];
      if (mounted) {
        setState(() {
          _prayers = data.map((p) => PrayerModel.fromJson(p)).toList();
          _isPrayersLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isPrayersLoading = false);
    }
  }

  Future<void> _loadMembers() async {
    try {
      final members = await _groupService.getGroupMembers(widget.groupId);
      if (mounted) setState(() => _members = members);
    } catch (e) {
      debugPrint('그룹 멤버 로드 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('멤버 목록을 불러오지 못했어요')),
        );
      }
    }
  }

  Future<void> _copyInviteCode() async {
    if (_group?.inviteCode == null) return;
    await Clipboard.setData(ClipboardData(text: _group!.inviteCode!));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('초대 코드가 복사되었습니다 📋'),
        backgroundColor: AppTheme.success,
        duration: Duration(seconds: 2),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: LoadingWidget(message: '그룹 정보를 불러오는 중...'));
    }
    if (_group == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyWidget(
            emoji: '😔', title: '그룹을 찾을 수 없어요', subtitle: '삭제된 그룹일 수 있습니다'),
      );
    }

    final isAdmin = _group!.userRole == 'admin';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(_group!.name),
        actions: [
          if (isAdmin)
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'invite') _copyInviteCode();
                if (v == 'prayer') {
                  context.push('/prayer/create', extra: {'groupId': widget.groupId});
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'invite',
                  child: Row(children: [
                    Icon(Icons.copy_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('초대 코드 복사'),
                  ]),
                ),
                const PopupMenuItem(
                  value: 'prayer',
                  child: Row(children: [
                    Icon(Icons.edit_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('그룹 기도 작성'),
                  ]),
                ),
              ],
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          indicatorWeight: 3,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textLight,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700),
          tabs: [
            Tab(text: '기도 ${_prayers.isNotEmpty ? "(${_prayers.length})" : ""}'),
            Tab(text: '멤버 ${_members.isNotEmpty ? "(${_members.length})" : ""}'),
          ],
        ),
      ),
      body: Column(
        children: [
          // 그룹 헤더 카드
          _buildHeader(isAdmin),
          // 탭 뷰
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPrayersTab(),
                _buildMembersTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _currentTabIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => context
                  .push('/prayer/create', extra: {'groupId': widget.groupId})
                  .then((_) => _loadGroupPrayers()),
              backgroundColor: AppTheme.primary,
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              label: const Text('기도 작성',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            )
          : null,
    );
  }

  Widget _buildHeader(bool isAdmin) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(_group!.groupTypeEmoji, style: const TextStyle(fontSize: 44)),
          const SizedBox(height: 8),
          Text(
            _group!.name,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          if (_group!.description != null) ...[
            const SizedBox(height: 4),
            Text(
              _group!.description!,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.85), fontSize: 13),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatBadge('${_members.isNotEmpty ? _members.length : _group!.memberCount}명', '멤버'),
              const SizedBox(width: 24),
              _buildStatBadge('${_prayers.length}개', '기도'),
              const SizedBox(width: 24),
              _buildStatBadge(_group!.groupTypeLabel, '유형'),
            ],
          ),
          // 관리자이고 초대코드 있으면 표시
          if (isAdmin && _group!.inviteCode != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _copyInviteCode,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.key_outlined,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '초대 코드: ${_group!.inviteCode}',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.copy_rounded,
                        color: Colors.white, size: 14),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrayersTab() {
    if (_isPrayersLoading) {
      return const LoadingWidget(message: '기도 목록을 불러오는 중...');
    }
    if (_prayers.isEmpty) {
      return EmptyWidget(
        emoji: '🙏',
        title: '아직 기도가 없어요',
        subtitle: '그룹을 위한 첫 번째 기도를 작성해보세요',
        buttonText: '기도 작성',
        onButtonTap: () => context
            .push('/prayer/create', extra: {'groupId': widget.groupId})
            .then((_) => _loadGroupPrayers()),
      );
    }
    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: _loadGroupPrayers,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 100),
        itemCount: _prayers.length,
        itemBuilder: (context, index) {
          final prayer = _prayers[index];
          return PrayerCard(
            title: prayer.title,
            content: prayer.content,
            userNickname: prayer.user?.nickname,
            userImage: prayer.user?.profileImageUrl,
            status: prayer.status,
            category: prayer.category,
            scope: prayer.scope,
            prayerCount: prayer.prayerCount,
            commentCount: prayer.commentCount,
            createdAt: prayer.createdAt,
            isParticipated: prayer.isParticipated,
            onTap: () => context.push('/prayer/${prayer.id}'),
          );
        },
      ),
    );
  }

  Widget _buildMembersTab() {
    if (_members.isEmpty) {
      return const Center(
        child: Text('멤버 정보를 불러오는 중...',
            style: TextStyle(color: AppTheme.textSecondary)),
      );
    }
    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: _loadMembers,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _members.length,
        itemBuilder: (context, index) {
          final member = _members[index];
          final nickname = member['nickname'] as String? ??
              member['user']?['nickname'] as String? ?? '익명';
          final role = member['role'] as String? ?? 'member';
          final churchName = member['church_name'] as String? ??
              member['user']?['church_name'] as String?;

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryLight,
              child: Text(
                nickname.isNotEmpty ? nickname[0] : '?',
                style: const TextStyle(
                    color: AppTheme.primary, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(nickname,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: churchName != null ? Text('⛪ $churchName') : null,
            trailing: role == 'admin'
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('관리자',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.warning,
                            fontWeight: FontWeight.w600)),
                  )
                : null,
          );
        },
      ),
    );
  }

  Widget _buildStatBadge(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800)),
        Text(label,
            style: TextStyle(
                color: Colors.white.withOpacity(0.8), fontSize: 11)),
      ],
    );
  }
}
