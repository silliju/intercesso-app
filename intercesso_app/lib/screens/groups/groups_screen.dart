import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../widgets/common_widgets.dart';
import '../../services/api_service.dart';
import '../../services/group_service.dart';
import '../../models/models.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final ApiService _api = ApiService();
  final GroupService _groupService = GroupService();
  List<GroupModel> _groups = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      final response = await _api.get('/groups');
      final data = response['data'] as List? ?? [];
      if (mounted) {
        setState(() {
          _groups = data.map((g) => GroupModel.fromJson(g)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  // 초대 코드로 그룹 참여
  void _showJoinByCodeDialog() {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('초대 코드로 참여', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('초대 코드를 입력해 그룹에 참여하세요',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: '예: ABC123',
                prefixIcon: const Icon(Icons.key_outlined, color: AppTheme.primary),
                filled: true,
                fillColor: AppTheme.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = codeController.text.trim();
              if (code.isEmpty) return;
              Navigator.pop(ctx);
              await _joinByCode(code);
            },
            child: const Text('참여하기'),
          ),
        ],
      ),
    );
  }

  Future<void> _joinByCode(String code) async {
    try {
      // 코드로 그룹 찾기 (백엔드가 invite_code로 조회 지원 가정)
      final response = await _api.post('/groups/join-by-code', body: {'invite_code': code});
      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('그룹에 참여했습니다 🎉'),
            backgroundColor: AppTheme.success,
          ));
          await _loadGroups();
        }
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.statusCode == 404
              ? '유효하지 않은 초대 코드입니다'
              : e.statusCode == 409
                  ? '이미 참여 중인 그룹입니다'
                  : e.message),
          backgroundColor: AppTheme.error,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('참여에 실패했습니다: $e'),
          backgroundColor: AppTheme.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('그룹'),
        actions: [
          // 초대 코드로 참여 버튼
          IconButton(
            icon: const Icon(Icons.key_outlined),
            tooltip: '초대 코드로 참여',
            onPressed: _showJoinByCodeDialog,
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: '그룹 만들기',
            onPressed: () => context.push('/group/create'),
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: '그룹 목록을 불러오는 중...')
          : _error != null
              ? _buildErrorState()
              : _groups.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      color: AppTheme.primary,
                      onRefresh: _loadGroups,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _groups.length,
                        itemBuilder: (context, index) {
                          final group = _groups[index];
                          return _buildGroupCard(group);
                        },
                      ),
                    ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('😔', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text('그룹 목록을 불러오지 못했어요',
                style: TextStyle(fontSize: 15, color: AppTheme.textSecondary)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadGroups,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: _loadGroups,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              EmptyWidget(
                emoji: '👥',
                title: '아직 그룹이 없어요',
                subtitle: '교회, 셀, 소모임을 만들거나\n초대 코드로 참여해보세요',
                buttonText: '그룹 만들기',
                onButtonTap: () => context.push('/group/create'),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _showJoinByCodeDialog,
                icon: const Icon(Icons.key_outlined, size: 18),
                label: const Text('초대 코드로 참여'),
                style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupCard(GroupModel group) {
    return GestureDetector(
      onTap: () => context.push('/group/${group.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(group.groupTypeEmoji,
                    style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildChip(group.groupTypeLabel, AppTheme.primary),
                      const SizedBox(width: 8),
                      Text('멤버 ${group.memberCount}명',
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary)),
                    ],
                  ),
                  if (group.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      group.description!,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (group.userRole == 'admin')
                  _buildChip('관리자', AppTheme.warning),
                const SizedBox(height: 4),
                const Icon(Icons.chevron_right_rounded, color: AppTheme.textLight),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
