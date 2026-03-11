import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/models.dart';
import '../../providers/gratitude_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/gratitude_service.dart';
import 'create_gratitude_screen.dart';

class GratitudeDetailScreen extends StatefulWidget {
  final String journalId;
  const GratitudeDetailScreen({super.key, required this.journalId});

  @override
  State<GratitudeDetailScreen> createState() => _GratitudeDetailScreenState();
}

class _GratitudeDetailScreenState extends State<GratitudeDetailScreen> {
  final GratitudeService _service = GratitudeService();
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();

  GratitudeModel? _journal;
  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = true;
  bool _isSendingComment = false;

  static const _gratitudeColor = Color(0xFF885CF6);
  static const _gratitudeLightColor = Color(0xFFEDE9FE);

  @override
  void initState() {
    super.initState();
    _loadJournal();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadJournal() async {
    setState(() => _isLoading = true);
    try {
      final journal = await _service.getJournalById(widget.journalId);
      // 댓글 분리
      final data = await _service.getJournalById(widget.journalId);
      setState(() {
        _journal = journal;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSendingComment = true);
    try {
      final result = await _service.addComment(widget.journalId, content);
      _commentController.clear();
      // 리로드
      await _loadJournal();
      // 스크롤 아래로
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (_) {}
    setState(() => _isSendingComment = false);
  }

  Future<void> _toggleReaction(String reactionType) async {
    try {
      await _service.toggleReaction(widget.journalId, reactionType);
      await _loadJournal();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(backgroundColor: _gratitudeColor, foregroundColor: Colors.white),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_journal == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('감사일기')),
        body: const Center(child: Text('일기를 불러올 수 없어요')),
      );
    }

    final journal = _journal!;
    final authProvider = context.read<AuthProvider>();
    final isMyPost = journal.userId == authProvider.user?.id;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: _gratitudeColor,
        foregroundColor: Colors.white,
        title: const Text('감사일기'),
        actions: [
          if (isMyPost)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) async {
                if (value == 'edit') {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateGratitudeScreen(existing: journal),
                    ),
                  );
                  if (result == true) await _loadJournal();
                } else if (value == 'delete') {
                  _confirmDelete(context);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Row(
                  children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('수정')],
                )),
                const PopupMenuItem(value: 'delete', child: Row(
                  children: [Icon(Icons.delete_outline, size: 18, color: Colors.red), SizedBox(width: 8), Text('삭제', style: TextStyle(color: Colors.red))],
                )),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(journal),
                  const SizedBox(height: 16),
                  _buildGratitudeCard(journal),
                  if (journal.linkedPrayer != null) ...[
                    const SizedBox(height: 12),
                    _buildLinkedPrayer(journal),
                  ],
                  const SizedBox(height: 16),
                  _buildReactionSection(journal),
                  const SizedBox(height: 16),
                  _buildCommentsSection(journal),
                ],
              ),
            ),
          ),
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildHeader(GratitudeModel journal) {
    final user = journal.user;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF3F0FF), Color(0xFFEDE9FE)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDD6FE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.primaryLight,
                backgroundImage: user?.profileImageUrl != null
                    ? NetworkImage(user!.profileImageUrl!)
                    : null,
                child: user?.profileImageUrl == null
                    ? Text(
                        (user?.nickname ?? '?')[0],
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.nickname ?? '사용자',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    if (user?.churchName != null)
                      Text(
                        user!.churchName!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _gratitudeColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '📅 ${_formatFullDate(journal.journalDate)}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4C1D95),
              ),
            ),
          ),
          if (journal.emotion != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '오늘의 감정: ${journal.emotionLabel}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF7C3AED),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGratitudeCard(GratitudeModel journal) {
    final items = [
      journal.gratitude1,
      if (journal.gratitude2 != null && journal.gratitude2!.isNotEmpty) journal.gratitude2!,
      if (journal.gratitude3 != null && journal.gratitude3!.isNotEmpty) journal.gratitude3!,
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF885CF6), Color(0xFF6D3FD4)],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Text('🌸', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                const Text(
                  '오늘의 감사',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                Text(
                  '${items.length}가지',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ...items.asMap().entries.map((entry) {
            final idx = entry.key;
            final text = entry.value;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F3FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${idx + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: Color(0xFF6D3FD4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          text,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF1A1A2E),
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (idx < items.length - 1)
                  const Divider(height: 1, color: Color(0xFFF3F4F6)),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLinkedPrayer(GratitudeModel journal) {
    final prayer = journal.linkedPrayer!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.link_rounded, color: AppTheme.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '연결된 기도제목',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  prayer['title'] ?? '기도제목',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: prayer['status'] == 'answered' ? AppTheme.success : AppTheme.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              prayer['status'] == 'answered' ? '✅ 응답' : '🙏 기도 중',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactionSection(GratitudeModel journal) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildReactionBtn(journal, 'grace', '🙏', '은혜받았어요'),
          Container(width: 1, height: 36, color: const Color(0xFFE5E7EB)),
          _buildReactionBtn(journal, 'empathy', '🤍', '공감해요'),
        ],
      ),
    );
  }

  Widget _buildReactionBtn(GratitudeModel journal, String type, String emoji, String label) {
    final isActive = journal.myReactions.contains(type);
    final count = journal.reactionCounts[type] ?? 0;

    return GestureDetector(
      onTap: () => _toggleReaction(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEDE9FE) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? const Color(0xFF6D3FD4) : AppTheme.textSecondary,
                  ),
                ),
                if (count > 0)
                  Text(
                    '$count명',
                    style: TextStyle(
                      fontSize: 11,
                      color: isActive ? const Color(0xFF885CF6) : AppTheme.textLight,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection(GratitudeModel journal) {
    // 댓글은 journal 데이터에서 가져옴
    final comments = (journal as dynamic).gratitudeComments as List? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '댓글 ${journal.commentCount > 0 ? journal.commentCount : ''}',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 10),
        if (journal.commentCount == 0)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                '첫 번째 댓글을 남겨보세요 💬',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
        top: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: '따뜻한 댓글을 남겨보세요...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              style: const TextStyle(fontSize: 14),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendComment(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isSendingComment ? null : _sendComment,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _gratitudeColor,
                shape: BoxShape.circle,
              ),
              child: _isSendingComment
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('감사일기 삭제'),
        content: const Text('이 감사일기를 삭제할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<GratitudeProvider>();
      await provider.deleteJournal(widget.journalId);
      Navigator.pop(context, true);
    }
  }

  String _formatFullDate(String dateStr) {
    try {
      final d = DateTime.parse(dateStr);
      const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
      final weekday = weekdays[d.weekday - 1];
      return '${d.year}년 ${d.month}월 ${d.day}일 $weekday요일';
    } catch (_) {
      return dateStr;
    }
  }
}
