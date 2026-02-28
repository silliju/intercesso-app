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
