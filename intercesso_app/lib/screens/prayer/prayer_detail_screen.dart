import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/prayer_service.dart';
import '../../services/intercession_service.dart';
import '../../services/group_service.dart';
import '../../models/models.dart';
import '../../config/theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/prayer_answer_section.dart';

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

  // ── 로딩 플래그 분리 ──
  bool _isLoading = true;       // 최초 로드 전용 (전체 화면 교체)
  bool _isSyncing = false;      // 백그라운드 동기화 (UI 유지)
  bool _isParticipating = false;
  bool _isSubmittingComment = false;
  bool _isDeleting = false;
  String? _loadError;

  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // 작정기도 체크인 상태
  List<dynamic> _checkins = [];
  bool _isCheckingIn = false;

  @override
  void initState() {
    super.initState();
    _loadPrayer(initial: true);
  }

  // ════════════════════════════════════════
  // 데이터 로드 — initial=true 일 때만 전체 로딩 화면
  // ════════════════════════════════════════
  Future<void> _loadPrayer({bool initial = false}) async {
    if (!mounted) return;
    if (initial) {
      setState(() { _isLoading = true; _loadError = null; });
    } else {
      setState(() => _isSyncing = true);
    }
    try {
      final prayer = await _prayerService.getPrayerById(widget.prayerId);
      if (!mounted) return;
      setState(() {
        _prayer = prayer;
        _isLoading = false;
        _isSyncing = false;
        _loadError = null;
      });
      _loadCheckins();
    } on ApiException catch (e) {
      debugPrint('[PrayerDetail] load error: ${e.message} (${e.statusCode})');
      if (!mounted) return;
      setState(() { _isLoading = false; _isSyncing = false; _loadError = e.message; });
    } catch (e) {
      debugPrint('[PrayerDetail] unknown error: $e');
      if (!mounted) return;
      setState(() { _isLoading = false; _isSyncing = false; _loadError = '기도를 불러올 수 없습니다'; });
    }
  }

  // ════════════════════════════════════════
  // 참여 토글 — 낙관적 업데이트 (즉시 반영)
  // ════════════════════════════════════════
  Future<void> _toggleParticipation() async {
    if (_prayer == null || _isParticipating) return;

    final wasParticipated = _prayer!.isParticipated;
    final prevCount = _prayer!.prayerCount;

    // ① 즉시 로컬 상태 반영 (API 호출 전)
    setState(() {
      _isParticipating = true;
      _prayer = _prayer!.copyWith(
        isParticipated: !wasParticipated,
        prayerCount: wasParticipated
            ? (prevCount - 1).clamp(0, 99999)
            : prevCount + 1,
      );
    });

    try {
      if (wasParticipated) {
        await _prayerService.cancelParticipation(widget.prayerId);
        if (mounted) _showSnack('기도 참여가 취소되었습니다');
      } else {
        await _prayerService.participatePrayer(widget.prayerId);
        if (mounted) _showSnack('함께 기도했습니다 🙏');
      }
      // ② 서버 정합성 동기화 (백그라운드, 로딩 화면 없음)
      _loadPrayer();
    } on ApiException catch (e) {
      debugPrint('[toggleParticipation] ApiException: ${e.message}');
      if (!mounted) return;
      // 실패 시 롤백
      setState(() {
        _prayer = _prayer!.copyWith(
          isParticipated: wasParticipated,
          prayerCount: prevCount,
        );
      });
      if (e.errorCode == 'ALREADY_PARTICIPATED' || e.statusCode == 400) {
        _showSnack('이미 함께 기도하셨습니다 🙏');
        _loadPrayer();
      } else if (e.statusCode == 401) {
        _showSnack('로그인이 필요합니다. 다시 로그인해주세요.', isError: true);
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) context.go('/login');
      } else {
        _showSnack(e.message, isError: true);
      }
    } catch (e) {
      debugPrint('[toggleParticipation] Error: $e');
      // 실패 시 롤백
      if (mounted) {
        setState(() {
          _prayer = _prayer!.copyWith(
            isParticipated: wasParticipated,
            prayerCount: prevCount,
          );
        });
        _showSnack('오류가 발생했습니다', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isParticipating = false);
    }
  }

  // ════════════════════════════════════════
  // 댓글 작성 — 즉시 로컬 추가
  // ════════════════════════════════════════
  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty || _isSubmittingComment) return;

    final currentUser = context.read<AuthProvider>().user;
    _commentController.clear();

    // ① 즉시 임시 댓글 로컬 추가
    final tempComment = CommentModel(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      prayerId: widget.prayerId,
      userId: currentUser?.id ?? '',
      content: content,
      createdAt: DateTime.now().toIso8601String(),
      user: currentUser != null
          ? UserModel(
              id: currentUser.id,
              email: currentUser.email,
              nickname: currentUser.nickname,
              profileImageUrl: currentUser.profileImageUrl,
              churchName: currentUser.churchName,
              denomination: null,
              bio: null,
              createdAt: '',
              lastLogin: null,
            )
          : null,
    );

    setState(() {
      _isSubmittingComment = true;
      _prayer = _prayer!.copyWith(
        comments: [...(_prayer!.comments ?? []), tempComment],
      );
    });

    // 댓글창 아래로 스크롤
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });

    try {
      await _prayerService.createComment(widget.prayerId, content);
      // ② 서버 동기화 (백그라운드)
      _loadPrayer();
    } catch (e) {
      // 실패 시 임시 댓글 제거
      if (mounted) {
        setState(() {
          _prayer = _prayer!.copyWith(
            comments: (_prayer!.comments ?? [])
                .where((c) => c.id != tempComment.id)
                .toList(),
          );
        });
        _showSnack('댓글 전송에 실패했습니다', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSubmittingComment = false);
    }
  }

  // ════════════════════════════════════════
  // 댓글 삭제 — 즉시 로컬 제거
  // ════════════════════════════════════════
  void _confirmDeleteComment(CommentModel comment, String currentUserId) {
    if (comment.userId != currentUserId) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('댓글 삭제', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('이 댓글을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteComment(comment);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('삭제', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteComment(CommentModel comment) async {
    // ① 즉시 로컬 제거
    final prevComments = List<CommentModel>.from(_prayer!.comments ?? []);
    setState(() {
      _prayer = _prayer!.copyWith(
        comments: prevComments.where((c) => c.id != comment.id).toList(),
      );
    });
    try {
      await _prayerService.deleteComment(comment.id);
      if (mounted) _showSnack('댓글이 삭제되었습니다');
    } catch (e) {
      // 실패 시 롤백
      if (mounted) {
        setState(() {
          _prayer = _prayer!.copyWith(comments: prevComments);
        });
        _showSnack('삭제에 실패했습니다', isError: true);
      }
    }
  }

  // ════════════════════════════════════════
  // 작정기도 체크인
  // ════════════════════════════════════════
  Future<void> _loadCheckins() async {
    if (_prayer == null || !_prayer!.isCovenant) return;
    try {
      final list = await _prayerService.getCheckins(widget.prayerId);
      if (mounted) setState(() => _checkins = list);
    } catch (e) {
      debugPrint('기도 체크인 목록 로드 실패: $e');
    }
  }

  Future<void> _doCheckIn() async {
    if (_isCheckingIn || _prayer == null) return;
    setState(() => _isCheckingIn = true);
    try {
      final startDate = DateTime.tryParse(_prayer!.createdAt);
      final today = DateTime.now();
      final day = startDate != null
          ? today.difference(startDate).inDays + 1
          : 1;
      await _prayerService.checkIn(widget.prayerId, day);
      await _loadCheckins();
      if (mounted) _showSnack('오늘 기도를 체크했습니다 ✏️');
    } on ApiException catch (e) {
      if (mounted) {
        _showSnack(e.statusCode == 409 ? '오늘은 이미 체크인했어요 ✅' : e.message);
      }
    } catch (e) {
      if (mounted) _showSnack('체크인에 실패했습니다', isError: true);
    } finally {
      if (mounted) setState(() => _isCheckingIn = false);
    }
  }

  // ════════════════════════════════════════
  // 기도 삭제
  // ════════════════════════════════════════
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

  // ════════════════════════════════════════
  // 상태 변경 — 즉시 로컬 반영
  // ════════════════════════════════════════
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
    if (_prayer == null || _prayer!.status == status) return;
    final prevStatus = _prayer!.status;

    // ① 즉시 로컬 반영
    setState(() {
      _prayer = _prayer!.copyWith(status: status);
    });

    try {
      await _prayerService.updatePrayer(widget.prayerId, status: status);
      if (mounted) {
        final labels = {'praying': '기도중', 'answered': '응답받음 🎉', 'grateful': '감사 🙌'};
        _showSnack('상태가 "${labels[status]}"으로 변경되었습니다');
      }
    } catch (e) {
      // 실패 시 롤백
      if (mounted) {
        setState(() => _prayer = _prayer!.copyWith(status: prevStatus));
        _showSnack('상태 변경에 실패했습니다', isError: true);
      }
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppTheme.error : AppTheme.success,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ════════════════════════════════════════
  // 중보기도 요청
  // ════════════════════════════════════════
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
            _icOption(ctx, '🌐', '전체 공개 요청', '모든 사용자에게 공개적으로 요청',
                messageController, 'public'),
            const SizedBox(height: 8),
            _icOption(ctx, '👥', '그룹에게 요청', '내 그룹 멤버 전체에게 요청',
                messageController, 'group'),
            const SizedBox(height: 8),
            _icOption(ctx, '👤', '개인에게 요청', '특정 사람을 검색하여 요청',
                messageController, 'individual'),
            const SizedBox(height: 12),
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
          _showSnack(result['success'] == true
              ? '전체에게 중보기도 요청을 보냈습니다 🙏'
              : result['message'] ?? '전송에 실패했습니다',
            isError: result['success'] != true);
        }
      } else if (type == 'group' && groupId != null) {
        result = await _intercessionService.sendGroupRequest(
          prayerId: widget.prayerId,
          groupId: groupId,
          groupName: null,
          message: message,
        );
        if (mounted) {
          _showSnack(result['success'] == true
              ? '그룹에 중보기도 요청을 보냈습니다 🙏'
              : result['message'] ?? '전송에 실패했습니다',
            isError: result['success'] != true);
        }
      } else if (type == 'individual' && recipientId != null) {
        result = await _intercessionService.sendPersonalRequest(
          prayerId: widget.prayerId,
          recipientId: recipientId,
          message: message,
        );
        if (mounted) {
          _showSnack(result['success'] == true
              ? '중보기도 요청을 보냈습니다 🙏'
              : result['message'] ?? '전송에 실패했습니다',
            isError: result['success'] != true);
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
    _scrollController.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    // 최초 로드 중 → 전체 화면 로딩 (한 번만)
    if (_isLoading) return const Scaffold(body: LoadingWidget(message: '기도를 불러오는 중...'));

    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('기도 상세')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('😔', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text(_loadError!, textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, color: AppTheme.textSecondary)),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _loadPrayer(initial: true),
                  icon: const Icon(Icons.refresh),
                  label: const Text('다시 시도'),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('기도 상세'),
        // 백그라운드 동기화 인디케이터 (얇은 상단 바)
        bottom: _isSyncing
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(
                  minHeight: 2,
                  backgroundColor: AppTheme.primaryLight,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                ),
              )
            : null,
        actions: [
          if (isOwner) ...[
            IconButton(
              icon: const Icon(Icons.swap_horiz_rounded),
              tooltip: '상태 변경',
              onPressed: _changeStatus,
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  context.push('/prayer/${widget.prayerId}/edit')
                      .then((_) => _loadPrayer());
                }
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
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── 기도 카드 ────────────────────────────────
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: AppTheme.cardDecoration,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: AppTheme.primaryLight,
                                    child: _prayer!.user?.profileImageUrl != null &&
                                            _prayer!.user!.profileImageUrl!.isNotEmpty
                                        ? ClipOval(
                                            child: CachedNetworkImage(
                                              imageUrl: _prayer!.user!.profileImageUrl!,
                                              fit: BoxFit.cover,
                                              width: 44,
                                              height: 44,
                                              placeholder: (_, __) => Center(
                                                child: Text(_prayer!.user?.nickname[0] ?? '?',
                                                    style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                                              ),
                                              errorWidget: (_, __, ___) => Center(
                                                child: Text(_prayer!.user?.nickname[0] ?? '?',
                                                    style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                                              ),
                                            ),
                                          )
                                        : Text(_prayer!.user?.nickname[0] ?? '?',
                                            style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
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
                                  GestureDetector(
                                    onTap: isOwner ? _changeStatus : null,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _statusColor.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      child: Text(
                                        '$_statusEmoji ${_prayer!.statusLabel}',
                                        style: TextStyle(fontSize: 12, color: _statusColor, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              Text(_prayer!.title,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 12),
                              Text(_prayer!.content,
                                  style: const TextStyle(fontSize: 15, color: AppTheme.textSecondary, height: 1.6)),
                              const SizedBox(height: 16),
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

                        // ── 작정기도 체크인 ──────────────────────────
                        if (_prayer!.isCovenant) ...[
                          _buildCovenantSection(isOwner),
                          const SizedBox(height: 12),
                        ],

                        // ── 함께 기도하기 버튼 ───────────────────────
                        if (_prayer!.status == 'praying') ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isParticipating ? null : _toggleParticipation,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _prayer!.isParticipated
                                    ? AppTheme.primaryLight
                                    : AppTheme.primary,
                                foregroundColor: _prayer!.isParticipated
                                    ? AppTheme.primary
                                    : Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                              ),
                              icon: _isParticipating
                                  ? const SizedBox(
                                      width: 16, height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
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
                          if (isOwner)
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _openIntercessionRequest,
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
                          const SizedBox(height: 10),
                        ],

                        // ── 기도 응답 섹션 ───────────────────────────
                        PrayerAnswerSection(
                          prayerId: widget.prayerId,
                          isOwner: isOwner,
                          prayerStatus: _prayer!.status,
                        ),

                        // ── 댓글 섹션 ────────────────────────────────
                        Row(
                          children: [
                            const Text('댓글', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            const SizedBox(width: 6),
                            Text(
                              '${(_prayer!.comments ?? []).length}',
                              style: const TextStyle(fontSize: 14, color: AppTheme.primary, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if ((_prayer!.comments ?? []).isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Text('첫 번째 댓글을 남겨보세요 💬',
                                  style: TextStyle(color: AppTheme.textLight)),
                            ),
                          )
                        else
                          ...(_prayer!.comments ?? []).map((comment) {
                            final isMine = comment.userId == currentUserId;
                            return GestureDetector(
                              onLongPress: isMine
                                  ? () => _confirmDeleteComment(comment, currentUserId!)
                                  : null,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isMine
                                      ? AppTheme.primaryLight.withOpacity(0.4)
                                      : AppTheme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppTheme.border),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: AppTheme.primaryLight,
                                      child: comment.user?.profileImageUrl != null &&
                                              comment.user!.profileImageUrl!.isNotEmpty
                                          ? ClipOval(
                                              child: CachedNetworkImage(
                                                imageUrl: comment.user!.profileImageUrl!,
                                                fit: BoxFit.cover,
                                                width: 32,
                                                height: 32,
                                                placeholder: (_, __) => Text(
                                                  comment.user?.nickname[0] ?? '?',
                                                  style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.bold),
                                                ),
                                                errorWidget: (_, __, ___) => Text(
                                                  comment.user?.nickname[0] ?? '?',
                                                  style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            )
                                          : Text(
                                              comment.user?.nickname[0] ?? '?',
                                              style: const TextStyle(
                                                  color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.bold),
                                            ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(comment.user?.nickname ?? '익명',
                                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                              if (isMine) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.primary.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(50),
                                                  ),
                                                  child: const Text('나',
                                                      style: TextStyle(fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.w700)),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(comment.content,
                                              style: const TextStyle(
                                                  fontSize: 13, color: AppTheme.textSecondary, height: 1.5)),
                                        ],
                                      ),
                                    ),
                                    if (isMine)
                                      GestureDetector(
                                        onTap: () => _confirmDeleteComment(comment, currentUserId!),
                                        child: const Padding(
                                          padding: EdgeInsets.only(left: 8),
                                          child: Icon(Icons.delete_outline_rounded,
                                              size: 16, color: AppTheme.textLight),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),

                // ── 댓글 입력창 ─────────────────────────────
                Container(
                  padding: EdgeInsets.only(
                    left: 16, right: 8, top: 10,
                    bottom: MediaQuery.of(context).padding.bottom + 12,
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
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _submitComment(),
                          onTap: () {
                            Future.delayed(const Duration(milliseconds: 300), () {
                              if (_scrollController.hasClients) {
                                _scrollController.animateTo(
                                  _scrollController.position.maxScrollExtent,
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOut,
                                );
                              }
                            });
                          },
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
                      _isSubmittingComment
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : IconButton(
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

  // ── 작정기도 체크인 섹션 ──────────────────────────────────
  Widget _buildCovenantSection(bool isOwner) {
    final total = _prayer!.covenantDays ?? 40;
    final checked = _checkins.length;
    final progress = total > 0 ? checked / total : 0.0;

    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final alreadyChecked = _checkins.any((c) {
      final d = c['checked_date'] ?? c['created_at'] ?? '';
      return d.toString().startsWith(todayStr);
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🕯️', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              const Text('작정기도', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              const Spacer(),
              Text('$checked / $total일',
                  style: const TextStyle(fontSize: 14, color: AppTheme.primary, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: AppTheme.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Text('${(progress * 100).toStringAsFixed(0)}% 달성',
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: alreadyChecked || _isCheckingIn || !isOwner ? null : _doCheckIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: alreadyChecked ? AppTheme.success : AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
              ),
              icon: _isCheckingIn
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(alreadyChecked ? '✅' : '✏️', style: const TextStyle(fontSize: 16)),
              label: Text(
                alreadyChecked ? '오늘 기도 완료!' : '오늘 기도 체크인',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
