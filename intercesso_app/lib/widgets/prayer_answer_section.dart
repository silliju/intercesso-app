import 'package:flutter/material.dart';
import '../../services/prayer_answer_service.dart';
import '../../theme/app_theme.dart';

class PrayerAnswerSection extends StatefulWidget {
  final String prayerId;
  final bool isOwner;
  final String prayerStatus;

  const PrayerAnswerSection({
    Key? key,
    required this.prayerId,
    required this.isOwner,
    required this.prayerStatus,
  }) : super(key: key);

  @override
  State<PrayerAnswerSection> createState() => _PrayerAnswerSectionState();
}

class _PrayerAnswerSectionState extends State<PrayerAnswerSection> {
  final PrayerAnswerService _service = PrayerAnswerService();
  Map<String, dynamic>? _answer;
  bool _loading = true;
  final TextEditingController _commentCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAnswer();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAnswer() async {
    setState(() => _loading = true);
    try {
      final data = await _service.getAnswer(widget.prayerId);
      setState(() { _answer = data; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    if (_answer != null) {
      return _buildAnswerCard();
    }

    // 응답 없음 + 소유자 + answered/grateful 상태
    if (widget.isOwner && widget.prayerStatus != 'praying') {
      return _buildWritePrompt();
    }

    return const SizedBox.shrink();
  }

  // ── 응답 카드 ───────────────────────────────────────
  Widget _buildAnswerCard() {
    final a = _answer!;
    final content = a['content'] as String?;
    final scope = a['scope'] as String? ?? 'public';
    final comments = (a['comments'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final scopeLabel = {'public': '🌐 전체', 'group': '👥 그룹', 'private': '🔒 비공개'}[scope] ?? '🌐 전체';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFECFDF5), Color(0xFFF0FFF4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: AppTheme.success, width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 12, 0),
                child: Row(
                  children: [
                    const Text('🎉', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    const Text('기도 응답', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF065F46))),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(50)),
                      child: Text(scopeLabel, style: const TextStyle(fontSize: 11, color: Color(0xFF065F46))),
                    ),
                    const Spacer(),
                    if (widget.isOwner) ...[
                      GestureDetector(
                        onTap: () => _showAnswerModal(existing: a),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(border: Border.all(color: AppTheme.success), borderRadius: BorderRadius.circular(8)),
                          child: Text('수정', style: TextStyle(fontSize: 12, color: AppTheme.success)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: _deleteAnswer,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(border: Border.all(color: Colors.redAccent), borderRadius: BorderRadius.circular(8)),
                          child: const Text('삭제', style: TextStyle(fontSize: 12, color: Colors.redAccent)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // 내용
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: content != null && content.isNotEmpty
                    ? Text(content, style: const TextStyle(fontSize: 15, color: Color(0xFF064E3B), height: 1.7))
                    : const Text('응답 내용이 없습니다', style: TextStyle(fontSize: 14, color: Colors.grey, fontStyle: FontStyle.italic)),
              ),
            ],
          ),
        ),

        // 응답 댓글 섹션
        if (scope != 'private') _buildCommentSection(comments),
      ],
    );
  }

  // ── 응답 댓글 ────────────────────────────────────────
  Widget _buildCommentSection(List<Map<String, dynamic>> comments) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(children: [
              const Text('🙌 응답 댓글 ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF065F46))),
              Text('${comments.length}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.success)),
            ]),
          ),
          if (comments.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Center(child: Text('첫 번째 축하 댓글을 남겨보세요!', style: TextStyle(fontSize: 13, color: Colors.grey))),
            )
          else
            ...comments.map((c) => _buildCommentItem(c)),
          // 댓글 입력
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _commentCtrl,
                  decoration: InputDecoration(
                    hintText: '축하 또는 감사 댓글...',
                    hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(50), borderSide: const BorderSide(color: Color(0xFFA7F3D0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(50), borderSide: const BorderSide(color: Color(0xFFA7F3D0))),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  style: const TextStyle(fontSize: 13),
                  maxLength: 200,
                  buildCounter: (_, {required currentLength, required isFocused, maxLength}) => const SizedBox.shrink(),
                  onSubmitted: (_) => _submitComment(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _submitComment,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(color: AppTheme.success, borderRadius: BorderRadius.circular(50)),
                  child: const Text('전송', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(Map<String, dynamic> c) {
    final user = c['user'] as Map<String, dynamic>?;
    final nick = user?['nickname'] as String? ?? '익명';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: const Color(0xFFD1FAE5),
            child: Text(nick.isNotEmpty ? nick[0] : '?', style: const TextStyle(fontSize: 11, color: Color(0xFF065F46), fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(nick, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF065F46))),
              const SizedBox(height: 2),
              Text(c['content'] as String? ?? '', style: const TextStyle(fontSize: 13, color: Color(0xFF064E3B), height: 1.5)),
            ]),
          ),
        ],
      ),
    );
  }

  // ── 간증 작성 유도 ──────────────────────────────────
  Widget _buildWritePrompt() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border: Border.all(color: const Color(0xFFD1D5DB), width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text('✨', style: TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          const Text('응답 간증을 나눠보세요', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('하나님의 응답을 공동체와 함께 나누면 큰 힘이 됩니다', style: TextStyle(fontSize: 13, color: Colors.grey), textAlign: TextAlign.center),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () => _showAnswerModal(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
            child: const Text('🎉 응답 간증 작성하기', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── 모달 ────────────────────────────────────────────
  void _showAnswerModal({Map<String, dynamic>? existing}) {
    final contentCtrl = TextEditingController(text: existing?['content'] as String? ?? '');
    String selectedScope = existing?['scope'] as String? ?? 'public';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: SingleChildScrollView(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              const Center(child: Text('🎉 기도 응답 간증', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
              const SizedBox(height: 4),
              const Center(child: Text('하나님의 응답을 공동체와 나눠보세요', style: TextStyle(fontSize: 13, color: Colors.grey))),
              const SizedBox(height: 20),
              const Text('응답 내용 (선택)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: contentCtrl,
                maxLines: 4,
                maxLength: 1000,
                decoration: InputDecoration(
                  hintText: '어떻게 응답을 받으셨나요? 간증을 나눠주세요...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.all(12),
                ),
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 4),
              const Text('공개 범위', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(children: [
                for (final s in ['public', 'group', 'private'])
                  Expanded(child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: GestureDetector(
                      onTap: () => setModal(() => selectedScope = s),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selectedScope == s ? const Color(0xFFECFDF5) : Colors.white,
                          border: Border.all(color: selectedScope == s ? AppTheme.success : const Color(0xFFE5E7EB), width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(children: [
                          Text({'public':'🌐','group':'👥','private':'🔒'}[s]!, style: const TextStyle(fontSize: 18)),
                          const SizedBox(height: 2),
                          Text({'public':'전체','group':'그룹','private':'비공개'}[s]!,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: selectedScope == s ? const Color(0xFF065F46) : Colors.black87)),
                        ]),
                      ),
                    ),
                  )),
              ]),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 13), shape: const StadiumBorder()),
                  child: const Text('닫기'),
                )),
                const SizedBox(width: 8),
                Expanded(flex: 2, child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _submitAnswer(contentCtrl.text.trim().isEmpty ? null : contentCtrl.text.trim(), selectedScope);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('🙌 간증 공유하기', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                )),
              ]),
              const SizedBox(height: 16),
            ],
          )),
        ),
      ),
    );
  }

  Future<void> _submitAnswer(String? content, String scope) async {
    try {
      await _service.upsertAnswer(widget.prayerId, content: content, scope: scope);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('응답 간증이 등록되었습니다 🎉'), backgroundColor: Color(0xFF10B981)));
        await _loadAnswer();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('등록 실패: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _deleteAnswer() async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('응답 간증 삭제'),
      content: const Text('응답 간증을 삭제하시겠습니까?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('삭제', style: TextStyle(color: Colors.red))),
      ],
    ));
    if (ok != true) return;
    try {
      await _service.deleteAnswer(widget.prayerId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('응답이 삭제되었습니다')));
        await _loadAnswer();
      }
    } catch (_) {}
  }

  Future<void> _submitComment() async {
    final content = _commentCtrl.text.trim();
    if (content.isEmpty) return;
    try {
      await _service.createComment(widget.prayerId, content);
      _commentCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('댓글이 등록되었습니다 🙌'), backgroundColor: Color(0xFF10B981)));
        await _loadAnswer();
      }
    } catch (_) {}
  }
}
