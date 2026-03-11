import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/choir_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/choir_models.dart';

// ═══════════════════════════════════════════════════════════════
// 공지사항 목록 + 상세 + 등록 화면
// ═══════════════════════════════════════════════════════════════
class ChoirNoticeScreen extends StatefulWidget {
  const ChoirNoticeScreen({super.key});

  @override
  State<ChoirNoticeScreen> createState() => _ChoirNoticeScreenState();
}

class _ChoirNoticeScreenState extends State<ChoirNoticeScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer2<ChoirProvider, AuthProvider>(
      builder: (context, choir, auth, _) {
        final isAdmin = choir.isAdmin(auth.user?.id) || choir.isOwner(auth.user?.id);
        final pinned = choir.notices.where((n) => n.isPinned).toList();
        final normal = choir.notices.where((n) => !n.isPinned).toList();

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: const Text('공지사항'),
            backgroundColor: const Color(0xFF885CF6),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          floatingActionButton: isAdmin
              ? FloatingActionButton(
                  onPressed: () => _showAddNoticeSheet(context, choir),
                  backgroundColor: const Color(0xFF885CF6),
                  child: const Icon(Icons.add, color: Colors.white),
                )
              : null,
          body: choir.notices.isEmpty
              ? _buildEmpty()
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (pinned.isNotEmpty) ...[
                      _sectionLabel('📌 고정 공지'),
                      const SizedBox(height: 8),
                      ...pinned.map((n) => _NoticeCard(
                            notice: n,
                            isAdmin: isAdmin,
                            choir: choir,
                          )),
                      const SizedBox(height: 16),
                    ],
                    if (normal.isNotEmpty) ...[
                      _sectionLabel('📋 전체 공지'),
                      const SizedBox(height: 8),
                      ...normal.map((n) => _NoticeCard(
                            notice: n,
                            isAdmin: isAdmin,
                            choir: choir,
                          )),
                    ],
                    const SizedBox(height: 80),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.campaign_outlined, size: 60, color: AppTheme.textLight),
          SizedBox(height: 12),
          Text('공지사항이 없어요', style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppTheme.textSecondary,
      ),
    );
  }

  void _showAddNoticeSheet(BuildContext context, ChoirProvider choir) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddNoticeSheet(choir: choir),
    );
  }
}

// ── 공지 카드 ─────────────────────────────────────────────────
class _NoticeCard extends StatelessWidget {
  final ChoirNoticeModel notice;
  final bool isAdmin;
  final ChoirProvider choir;

  const _NoticeCard({
    required this.notice,
    required this.isAdmin,
    required this.choir,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: notice.isPinned
                ? const Color(0xFF885CF6).withOpacity(0.4)
                : AppTheme.border,
            width: notice.isPinned ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (notice.isPinned) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF885CF6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '📌 고정',
                      style: TextStyle(
                          fontSize: 10, color: Color(0xFF885CF6), fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    notice.title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isAdmin)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 18, color: AppTheme.textLight),
                    onSelected: (action) async {
                      if (action == 'pin') {
                        // 핀 토글 (updateNotice)
                        await choir.updateNotice(notice.id, isPinned: !notice.isPinned);
                      } else if (action == 'delete') {
                        await choir.deleteNotice(notice.id);
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'pin',
                        child: Text(notice.isPinned ? '📌 고정 해제' : '📌 상단 고정'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('삭제', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              notice.content,
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 12, color: AppTheme.textLight),
                const SizedBox(width: 4),
                Text(notice.authorName,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textLight)),
                const SizedBox(width: 12),
                const Icon(Icons.schedule, size: 12, color: AppTheme.textLight),
                const SizedBox(width: 4),
                Text(notice.timeAgo,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textLight)),
                if (notice.targetSection != null) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.textLight.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      notice.targetSection!,
                      style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, ctrl) => ListView(
          controller: ctrl,
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (notice.isPinned)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF885CF6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('📌 고정 공지',
                    style: TextStyle(fontSize: 11, color: Color(0xFF885CF6))),
              ),
            Text(
              notice.title,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('${notice.authorName} · ${notice.timeAgo}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
            const Divider(height: 28),
            Text(
              notice.content,
              style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary, height: 1.7),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ── 공지 등록 바텀시트 ─────────────────────────────────────────
class _AddNoticeSheet extends StatefulWidget {
  final ChoirProvider choir;
  const _AddNoticeSheet({required this.choir});

  @override
  State<_AddNoticeSheet> createState() => _AddNoticeSheetState();
}

class _AddNoticeSheetState extends State<_AddNoticeSheet> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  bool _isPinned = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목을 입력해주세요')),
      );
      return;
    }
    if (_contentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('내용을 입력해주세요')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final ok = await widget.choir.createNotice(
      title: _titleCtrl.text.trim(),
      content: _contentCtrl.text.trim(),
      isPinned: _isPinned,
    );
    setState(() => _isLoading = false);

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('📢 공지가 등록됐어요!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.choir.errorMessage ?? '공지 등록에 실패했어요')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text('공지 등록',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: '제목 *',
                hintText: '공지 제목을 입력하세요',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentCtrl,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: '내용 *',
                hintText: '공지 내용을 입력하세요',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Switch(
                  value: _isPinned,
                  onChanged: (v) => setState(() => _isPinned = v),
                  activeColor: const Color(0xFF885CF6),
                ),
                const SizedBox(width: 8),
                const Text('📌 상단 고정',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF885CF6),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('공지 등록',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
