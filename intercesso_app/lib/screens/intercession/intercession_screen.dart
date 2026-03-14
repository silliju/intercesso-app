import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../widgets/common_widgets.dart';
import '../../services/intercession_service.dart';
import '../../models/models.dart';

class IntercessionScreen extends StatefulWidget {
  const IntercessionScreen({super.key});

  @override
  State<IntercessionScreen> createState() => _IntercessionScreenState();
}

class _IntercessionScreenState extends State<IntercessionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final IntercessionService _service = IntercessionService();

  List<IntercessionModel> _received = [];
  List<IntercessionModel> _sent = [];
  bool _isLoadingReceived = false;
  bool _isLoadingSent = false;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadReceived(), _loadSent()]);
  }

  Future<void> _loadReceived() async {
    setState(() { _isLoadingReceived = true; });
    try {
      final list = await _service.getReceivedRequests();
      if (mounted) setState(() { _received = list; _isLoadingReceived = false; });
    } catch (e) {
      debugPrint('[Intercession] 받은 요청 로드 오류: $e');
      if (mounted) setState(() { _isLoadingReceived = false; });
    }
  }

  Future<void> _loadSent() async {
    setState(() => _isLoadingSent = true);
    try {
      final list = await _service.getSentRequests();
      if (mounted) setState(() { _sent = list; _isLoadingSent = false; });
    } catch (e) {
      debugPrint('[Intercession] 보낸 요청 로드 오류: $e');
      if (mounted) setState(() => _isLoadingSent = false);
    }
  }

  Future<void> _respond(IntercessionModel req, String status) async {
    try {
      await _service.respondToRequest(req.id, status: status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(status == 'accepted'
              ? '중보기도 요청을 수락했습니다 🙏'
              : '요청을 거절했습니다'),
          backgroundColor:
              status == 'accepted' ? AppTheme.success : AppTheme.textLight,
          behavior: SnackBarBehavior.floating,
          action: status == 'accepted' && req.prayerId.isNotEmpty
              ? SnackBarAction(
                  label: '기도 보기',
                  textColor: Colors.white,
                  onPressed: () => context.push('/prayer/${req.prayerId}'),
                )
              : null,
        ));
        await _loadReceived();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('처리 실패: $e'),
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
        title: const Text('중보기도'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          indicatorWeight: 3,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textLight,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('받은 요청'),
                  if (_received.where((r) => r.status == 'pending').isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_received.where((r) => r.status == 'pending').length}',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
            ),
            const Tab(text: '보낸 요청'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReceivedTab(),
          _buildSentTab(),
        ],
      ),
    );
  }

  Widget _buildReceivedTab() {
    if (_isLoadingReceived) return const LoadingWidget(message: '중보기도 요청을 불러오는 중...');
    if (_received.isEmpty) {
      return const EmptyWidget(
        emoji: '🤝',
        title: '받은 중보기도 요청이 없어요',
        subtitle: '다른 사람이 중보기도를 요청하면\n여기에 표시됩니다',
      );
    }
    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: _loadReceived,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: _received.length,
        itemBuilder: (context, index) {
          return _buildReceivedCard(_received[index]);
        },
      ),
    );
  }

  Widget _buildSentTab() {
    if (_isLoadingSent) return const LoadingWidget(message: '보낸 요청을 불러오는 중...');
    if (_sent.isEmpty) {
      return const EmptyWidget(
        emoji: '💌',
        title: '보낸 중보기도 요청이 없어요',
        subtitle: '기도 상세 페이지에서\n중보기도를 요청해보세요',
      );
    }
    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: _loadSent,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: _sent.length,
        itemBuilder: (context, index) {
          return _buildSentCard(_sent[index]);
        },
      ),
    );
  }

  Widget _buildReceivedCard(IntercessionModel req) {
    final isPending = req.status == 'pending';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 요청자 정보
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primaryLight,
                child: Text(
                  (req.requester?.nickname ?? '?')[0],
                  style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      req.requester?.nickname ?? '알 수 없음',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      _formatTime(req.createdAt),
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(req.status),
            ],
          ),
          const SizedBox(height: 12),
          // 기도 제목
          if (req.prayer != null)
            GestureDetector(
              onTap: () => context.push('/prayer/${req.prayerId}'),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    const Text('🙏', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        req.prayer!.title,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, size: 16, color: AppTheme.textLight),
                  ],
                ),
              ),
            ),
          // 메시지
          if (req.message != null && req.message!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.successBg,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppTheme.success),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💬', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      req.message!,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // 수락/거절 버튼 (pending인 경우만)
          if (isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _respond(req, 'rejected'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                      side: const BorderSide(color: AppTheme.border),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('거절', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => _respond(req, 'accepted'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('🙏 함께 기도하기', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSentCard(IntercessionModel req) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💌', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('중보기도 요청',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    Text(
                      _formatTime(req.createdAt),
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(req.status),
            ],
          ),
          const SizedBox(height: 12),
          if (req.prayer != null)
            GestureDetector(
              onTap: () => context.push('/prayer/${req.prayerId}'),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    const Text('🙏', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        req.prayer!.title,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, size: 16, color: AppTheme.textLight),
                  ],
                ),
              ),
            ),
          if (req.message != null && req.message!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '전달 메시지: ${req.message}',
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String label;
    switch (status) {
      case 'accepted':
        bg = const Color(0xFFECFDF5); fg = AppTheme.success; label = '수락됨 ✅';
        break;
      case 'rejected':
        bg = const Color(0xFFFEF2F2); fg = AppTheme.error; label = '거절됨';
        break;
      default:
        bg = const Color(0xFFFFF7ED); fg = const Color(0xFFF59E0B); label = '대기중 ⏳';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.full)),
      child: Text(label, style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w700)),
    );
  }

  String _formatTime(String createdAt) {
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return '방금 전';
      if (diff.inHours < 1) return '${diff.inMinutes}분 전';
      if (diff.inDays < 1) return '${diff.inHours}시간 전';
      if (diff.inDays < 7) return '${diff.inDays}일 전';
      return '${dt.month}/${dt.day}';
    } catch (_) {
      return '';
    }
  }
}
