import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/prayer_service.dart';
import '../../services/intercession_service.dart';
import '../../services/group_service.dart';
import '../../models/models.dart';
import '../../config/theme.dart';
import '../../widgets/common_widgets.dart';

class PrayerDetailScreen extends StatefulWidget {
  final String prayerId;
  const PrayerDetailScreen({super.key, required this.prayerId});

  @override
  State<PrayerDetailScreen> createState() => _PrayerDetailScreenState();
}

class _PrayerDetailScreenState extends State<PrayerDetailScreen> {
  final PrayerService _prayerService = PrayerService();
  final IntercessionService _intercessionService = IntercessionService();
  final GroupService _groupService = GroupService();
  PrayerModel? _prayer;
  bool _isLoading = true;
  bool _isParticipating = false;
  bool _isDeleting = false;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPrayer();
  }

  Future<void> _loadPrayer() async {
    try {
      final prayer = await _prayerService.getPrayerById(widget.prayerId);
      if (mounted) setState(() { _prayer = prayer; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleParticipation() async {
    if (_prayer == null) return;
    setState(() => _isParticipating = true);
    try {
      if (_prayer!.isParticipated) {
        await _prayerService.cancelParticipation(widget.prayerId);
      } else {
        await _prayerService.participatePrayer(widget.prayerId);
      }
      await _loadPrayer();
    } catch (e) {
      if (mounted) _showSnack(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isParticipating = false);
    }
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;
    try {
      await _prayerService.createComment(widget.prayerId, content);
      _commentController.clear();
      await _loadPrayer();
    } catch (e) {
      if (mounted) _showSnack(e.toString(), isError: true);
    }
  }

  // ── 삭제 ──────────────────────────────────────────
  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('기도 삭제', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('이 기도를 삭제하시겠습니까?'),
            if ((_prayer?.prayerCount ?? 0) > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Text('⚠️', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${_prayer!.prayerCount}명이 함께 기도하고 있습니다',
                        style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deletePrayer();
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('삭제', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePrayer() async {
    setState(() => _isDeleting = true);
    try {
      await _prayerService.deletePrayer(widget.prayerId);
      if (mounted) {
        _showSnack('기도가 삭제되었습니다');
        context.pop();
      }
    } catch (e) {
      if (mounted) _showSnack('삭제에 실패했습니다', isError: true);
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  // ── 상태 변경 ──────────────────────────────────────
  void _changeStatus() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('기도 상태 변경', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            ...[
              {'value': 'praying',  'label': '🙏 기도중',   'color': AppTheme.primary},
              {'value': 'answered', 'label': '✅ 응답받음', 'color': AppTheme.success},
              {'value': 'grateful', 'label': '🙌 감사',    'color': AppTheme.warning},
            ].map((s) => ListTile(
              title: Text(s['label'] as String,
                  style: TextStyle(fontWeight: FontWeight.w600, color: s['color'] as Color)),
              trailing: _prayer?.status == s['value']
                  ? Icon(Icons.check_circle, color: s['color'] as Color)
                  : null,
              onTap: () async {
                Navigator.pop(ctx);
                await _updateStatus(s['value'] as String);
              },
            )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(String status) async {
    try {
      await _prayerService.updatePrayer(widget.prayerId, status: status);
      await _loadPrayer();
      if (mounted) {
        final labels = {'praying': '기도중', 'answered': '응답받음 🎉', 'grateful': '감사 🙌'};
        _showSnack('상태가 "${labels[status]}"으로 변경되었습니다');
      }
    } catch (e) {
      if (mounted) _showSnack('상태 변경에 실패했습니다', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppTheme.error : AppTheme.success,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ── 중보기도 요청 ──────────────────────────────────────
  void _openIntercessionRequest() {
    if (_prayer == null) return;
    final messageController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
            ),
            const Text('🤝 중보기도 요청하기',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('누구에게 중보기도를 요청할까요?',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            // 기도 미리보기
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  const Text('🙏', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_prayer!.title,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 선택지
            _icOption(ctx, '🌐', '전체 공개 요청', '모든 사용자에게 공개적으로 요청',
                messageController, 'public'),
            const SizedBox(height: 8),
            _icOption(ctx, '👥', '그룹에게 요청', '내 그룹 멤버 전체에게 요청',
                messageController, 'group'),
            const SizedBox(height: 8),
            _icOption(ctx, '👤', '개인에게 요청', '특정 사람을 검색하여 요청',
                messageController, 'individual'),
            const SizedBox(height: 12),
            // 메시지 입력
            TextField(
              controller: messageController,
              decoration: InputDecoration(
                hintText: '전달 메시지 (선택사항)',
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _icOption(BuildContext ctx, String emoji, String title, String sub,
      TextEditingController msgCtrl, String type) {
    return GestureDetector(
      onTap: () async {
        Navigator.pop(ctx);
        if (type == 'group') {
          await _openGroupPicker(msgCtrl.text.trim());
        } else if (type == 'individual') {
          await _openPersonPicker(msgCtrl.text.trim());
        } else {
          await _sendIntercessionRequest(type: 'public', message: msgCtrl.text.trim());
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  Text(sub, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.textLight),
          ],
        ),
      ),
    );
  }

  Future<void> _sendIntercessionRequest({
    required String type,
    String? message,
    String? groupId,
    String? recipientId,
  }) async {
    try {
      Map<String, dynamic> result = {};
      if (type == 'public') {
        result = await _intercessionService.sendPublicRequest(
          prayerId: widget.prayerId,
          message: message,
        );
        if (mounted) {
          if (result['success'] == true) {
            _showSnack('전체에게 중보기도 요청을 보냈습니다 🙏');
          } else {
            _showSnack(result['message'] ?? '전송에 실패했습니다', isError: true);
          }
        }
      } else if (type == 'group' && groupId != null) {
        result = await _intercessionService.sendGroupRequest(
          prayerId: widget.prayerId,
          groupId: groupId,
          groupName: null,
          message: message,
        );
        if (mounted) {
          if (result['success'] == true) {
            _showSnack('그룹에 중보기도 요청을 보냈습니다 🙏');
          } else {
            _showSnack(result['message'] ?? '전송에 실패했습니다', isError: true);
          }
        }
      } else if (type == 'individual' && recipientId != null) {
        result = await _intercessionService.sendPersonalRequest(
          prayerId: widget.prayerId,
          recipientId: recipientId,
          message: message,
        );
        if (mounted) {
          if (result['success'] == true) {
            _showSnack('중보기도 요청을 보냈습니다 🙏');
          } else {
            _showSnack(result['message'] ?? '전송에 실패했습니다', isError: true);
          }
        }
      }
    } catch (e) {
      if (mounted) _showSnack('요청 전송에 실패했습니다: $e', isError: true);
    }
  }

  Future<void> _openGroupPicker(String message) async {
    try {
      final groups = await _groupService.getMyGroups();
      if (!mounted) return;
      if (groups.isEmpty) {
        _showSnack('속한 그룹이 없습니다. 그룹에 먼저 참여해주세요.');
        return;
      }
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('👥 그룹 선택',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              ...groups.map((g) => ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.primaryLight,
                  child: Text('⛪', style: TextStyle(fontSize: 16)),
                ),
                title: Text(g.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('멤버 ${g.memberCount}명'),
                onTap: () {
                  Navigator.pop(ctx);
                  _sendIntercessionRequest(type: 'group', groupId: g.id, message: message);
                },
              )),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) _showSnack('그룹 정보를 불러오지 못했습니다', isError: true);
    }
  }

  Future<void> _openPersonPicker(String message) async {
    final searchCtrl = TextEditingController();
    List<Map<String, dynamic>> searchResults = [];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateModal) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('👤 개인에게 요청',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              TextField(
                controller: searchCtrl,
                decoration: InputDecoration(
                  hintText: '닉네임으로 검색...',
                  prefixIcon: const Icon(Icons.search),
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onChanged: (q) async {
                  if (q.trim().isEmpty) {
                    setStateModal(() => searchResults = []);
                    return;
                  }
                  final results = await _intercessionService.searchUsers(q.trim());
                  if (ctx.mounted) setStateModal(() => searchResults = results);
                },
              ),
              const SizedBox(height: 12),
              if (searchResults.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('닉네임으로 검색하세요',
                      style: TextStyle(color: AppTheme.textSecondary)),
                )
              else
                ...searchResults.map((u) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryLight,
                    child: Text(
                      (u['nickname'] as String? ?? '?')[0],
                      style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(u['nickname'] as String? ?? '익명'),
                  subtitle: u['church_name'] != null
                      ? Text(u['church_name'] as String)
                      : null,
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.pop(ctx);
                    _sendIntercessionRequest(
                      type: 'individual',
                      recipientId: u['id'] as String,
                      message: message,
                    );
                  },
                )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: LoadingWidget(message: '기도를 불러오는 중...'));
    if (_prayer == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyWidget(emoji: '😔', title: '기도를 찾을 수 없어요', subtitle: '삭제된 기도이거나 비공개 기도입니다'),
      );
    }

    final currentUserId = context.read<AuthProvider>().user?.id;
    final isOwner = _prayer!.userId == currentUserId;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('기도 상세'),
        actions: [
          if (isOwner) ...[
            // 상태 변경 버튼
            IconButton(
              icon: const Icon(Icons.swap_horiz_rounded),
              tooltip: '상태 변경',
              onPressed: _changeStatus,
            ),
            // 더보기 메뉴 (수정/삭제)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') context.push('/prayer/${widget.prayerId}/edit').then((_) => _loadPrayer());
                if (value == 'delete') _confirmDelete();
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('수정')]),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete_outline, size: 18, color: AppTheme.error),
                    SizedBox(width: 8),
                    Text('삭제', style: TextStyle(color: AppTheme.error)),
                  ]),
                ),
              ],
            ),
          ],
        ],
      ),
      body: _isDeleting
          ? const LoadingWidget(message: '삭제 중...')
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 기도 카드
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: AppTheme.cardDecoration,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 작성자 + 상태
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: AppTheme.primaryLight,
                                    backgroundImage: _prayer!.user?.profileImageUrl != null
                                        ? NetworkImage(_prayer!.user!.profileImageUrl!) : null,
                                    child: _prayer!.user?.profileImageUrl == null
                                        ? Text(_prayer!.user?.nickname[0] ?? '?',
                                            style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold))
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(_prayer!.user?.nickname ?? '익명',
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                                        if (_prayer!.user?.churchName != null)
                                          Text(_prayer!.user!.churchName!,
                                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                      ],
                                    ),
                                  ),
                                  // 상태 뱃지 (탭하면 변경)
                                  GestureDetector(
                                    onTap: isOwner ? _changeStatus : null,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _statusColor.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      child: Text(
                                        '${_statusEmoji} ${_prayer!.statusLabel}',
                                        style: TextStyle(fontSize: 12, color: _statusColor, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              // 제목
                              Text(_prayer!.title,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 12),
                              // 내용
                              Text(_prayer!.content,
                                  style: const TextStyle(fontSize: 15, color: AppTheme.textSecondary, height: 1.6)),
                              const SizedBox(height: 16),
                              // 태그들
                              Wrap(
                                spacing: 8,
                                children: [
                                  if (_prayer!.category != null)
                                    _buildTag('${_prayer!.categoryEmoji} ${_prayer!.category}',
                                        AppTheme.primaryLight, AppTheme.primary),
                                  _buildTag(_prayer!.scopeLabel, Colors.grey.shade100, AppTheme.textSecondary),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // 기도 참여 버튼
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isParticipating ? null : _toggleParticipation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _prayer!.isParticipated ? AppTheme.primaryLight : AppTheme.primary,
                              foregroundColor: _prayer!.isParticipated ? AppTheme.primary : Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                            ),
                            icon: _isParticipating
                                ? const SizedBox(width: 16, height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2))
                                : const Text('🙏', style: TextStyle(fontSize: 18)),
                            label: Text(
                              _prayer!.isParticipated
                                  ? '함께 기도했습니다 (${_prayer!.prayerCount})'
                                  : '함께 기도하기 (${_prayer!.prayerCount})',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // 중보기도 요청 버튼 (내 기도일 때만)
                        if (isOwner)
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _openIntercessionRequest(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primary,
                                side: const BorderSide(color: AppTheme.primary, width: 1.5),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                              ),
                              icon: const Text('🤝', style: TextStyle(fontSize: 18)),
                              label: const Text('중보기도 요청하기',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        const SizedBox(height: 20),
                        // 댓글 섹션
                        Row(
                          children: [
                            const Text('댓글', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            const SizedBox(width: 6),
                            Text('${(_prayer!.comments ?? []).length}',
                                style: const TextStyle(fontSize: 14, color: AppTheme.primary, fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if ((_prayer!.comments ?? []).isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(child: Text('첫 번째 댓글을 남겨보세요 💬',
                                style: TextStyle(color: AppTheme.textLight))),
                          )
                        else
                          ...(_prayer!.comments ?? []).map((comment) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: AppTheme.cardDecoration,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AppTheme.primaryLight,
                                  child: Text(comment.user?.nickname[0] ?? '?',
                                      style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(comment.user?.nickname ?? '익명',
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 4),
                                      Text(comment.content,
                                          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.5)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
                // 댓글 입력창
                Container(
                  padding: EdgeInsets.only(
                    left: 16, right: 8, top: 10,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 12,
                  ),
                  decoration: const BoxDecoration(
                    color: AppTheme.surface,
                    border: Border(top: BorderSide(color: AppTheme.border)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: '격려 메시지를 남겨보세요...',
                            filled: true,
                            fillColor: AppTheme.background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _submitComment,
                        icon: const Icon(Icons.send_rounded, color: AppTheme.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTag(String text, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(50)),
    child: Text(text, style: TextStyle(fontSize: 12, color: fg, fontWeight: FontWeight.w600)),
  );

  Color get _statusColor {
    switch (_prayer?.status) {
      case 'answered': return AppTheme.success;
      case 'grateful': return AppTheme.warning;
      default: return AppTheme.primary;
    }
  }

  String get _statusEmoji {
    switch (_prayer?.status) {
      case 'answered': return '✅';
      case 'grateful': return '🙌';
      default: return '🙏';
    }
  }
}
