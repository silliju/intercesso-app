import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/prayer_service.dart';
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
  PrayerModel? _prayer;
  bool _isLoading = true;
  bool _isParticipating = false;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPrayer();
  }

  Future<void> _loadPrayer() async {
    try {
      final prayer = await _prayerService.getPrayerById(widget.prayerId);
      setState(() {
        _prayer = prayer;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      setState(() => _isParticipating = false);
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: LoadingWidget(message: '기도를 불러오는 중...'));
    }
    if (_prayer == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyWidget(
          emoji: '😔',
          title: '기도를 찾을 수 없어요',
          subtitle: '삭제된 기도이거나 비공개 기도입니다',
        ),
      );
    }

    final currentUserId = context.read<AuthProvider>().user?.id;
    final isOwner = _prayer!.userId == currentUserId;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('기도 상세'),
        actions: [
          if (isOwner)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'edit') {
                  context.push('/prayer/${widget.prayerId}/edit');
                } else if (value == 'delete') {
                  _confirmDelete();
                } else if (value == 'status') {
                  _changeStatus();
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: 'status', child: Text('상태 변경')),
                const PopupMenuItem(value: 'edit', child: Text('수정')),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('삭제', style: TextStyle(color: AppTheme.error)),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 작성자 정보
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.cardDecoration,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: AppTheme.primaryLight,
                              backgroundImage: _prayer!.user?.profileImageUrl != null
                                  ? NetworkImage(_prayer!.user!.profileImageUrl!)
                                  : null,
                              child: _prayer!.user?.profileImageUrl == null
                                  ? Text(
                                      _prayer!.user?.nickname[0] ?? '?',
                                      style: const TextStyle(
                                        color: AppTheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _prayer!.user?.nickname ?? '익명',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (_prayer!.user?.churchName != null)
                                  Text(
                                    _prayer!.user!.churchName!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                            const Spacer(),
                            // 상태 뱃지
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Text(
                                '${_prayer!.statusEmoji} ${_prayer!.statusLabel}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _statusColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        // 제목
                        Text(
                          _prayer!.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // 내용
                        Text(
                          _prayer!.content,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppTheme.textSecondary,
                            height: 1.6,
                          ),
                        ),
                        if (_prayer!.category != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLight,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Text(
                              '${_prayer!.categoryEmoji} ${_prayer!.category}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        if (_prayer!.isCovenant && _prayer!.covenantDays != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                const Text('🕯️', style: TextStyle(fontSize: 16)),
                                const SizedBox(width: 8),
                                Text(
                                  '${_prayer!.covenantDays}일 작정기도',
                                  style: const TextStyle(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 기도함 버튼
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
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50)),
                      ),
                      icon: _isParticipating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('🙏', style: TextStyle(fontSize: 18)),
                      label: Text(
                        _prayer!.isParticipated
                            ? '기도했습니다 (${_prayer!.prayerCount})'
                            : '🙏 기도하기 (${_prayer!.prayerCount})',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 댓글 섹션
                  const Text(
                    '댓글',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  if (_prayer!.comments?.isEmpty != false)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          '첫 번째 댓글을 남겨보세요 💬',
                          style: TextStyle(color: AppTheme.textLight),
                        ),
                      ),
                    )
                  else
                    ...(_prayer!.comments ?? []).map((comment) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: AppTheme.cardDecoration,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: AppTheme.primaryLight,
                                child: Text(
                                  comment.user?.nickname[0] ?? '?',
                                  style: const TextStyle(
                                    color: AppTheme.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      comment.user?.nickname ?? '익명',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      comment.content,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
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
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
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
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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

  Color get _statusColor {
    switch (_prayer?.status) {
      case 'answered': return AppTheme.success;
      case 'grateful': return AppTheme.warning;
      default: return AppTheme.primary;
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('기도 삭제'),
        content: const Text('이 기도를 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: delete
              context.pop();
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _changeStatus() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '기도 상태 변경',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            ...['praying', 'answered', 'grateful'].map((status) {
              final labels = {'praying': '🙏 기도중', 'answered': '✅ 응답받음', 'grateful': '🙌 감사'};
              return ListTile(
                title: Text(labels[status] ?? status),
                trailing: _prayer?.status == status
                    ? const Icon(Icons.check, color: AppTheme.primary)
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  // TODO: update status
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
