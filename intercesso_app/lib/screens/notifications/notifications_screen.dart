import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../widgets/common_widgets.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiService _api = ApiService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      final response = await _api.get('/notifications');
      final data = response['data'] as List? ?? [];
      if (mounted) {
        setState(() {
          _notifications = data.map((n) => NotificationModel.fromJson(n)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  Future<void> _markAsRead(String id) async {
    try {
      await _api.put('/notifications/$id/read');
      await _loadNotifications();
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    try {
      await _api.put('/notifications/read-all');
      await _loadNotifications();
    } catch (_) {}
  }

  /// 알림 타입에 따라 해당 화면으로 이동
  void _navigateFromNotification(NotificationModel notif) {
    // 읽음 처리
    if (!notif.isRead) _markAsRead(notif.id);

    if (notif.relatedId == null) return;

    switch (notif.type) {
      case 'prayer_participation':
      case 'comment':
      case 'prayer_answered':
      case 'intercession_accepted':
        // 기도 상세 페이지로
        context.push('/prayer/${notif.relatedId}');
        break;
      case 'intercession_request':
        // 중보기도 화면으로 (MainTabScreen의 intercession 탭)
        // go_router에서 뒤로가기가 가능하도록 push 사용
        context.push('/prayer/${notif.relatedId}');
        break;
      case 'group_invite':
        // 그룹 상세로
        context.push('/group/${notif.relatedId}');
        break;
      default:
        // relatedId가 있으면 기도로 간주
        context.push('/prayer/${notif.relatedId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('알림'),
        actions: [
          if (_notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: _markAllRead,
              child: const Text('모두 읽기',
                  style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: '알림을 불러오는 중...')
          : _error != null
              ? _buildErrorState()
              : _notifications.isEmpty
                  ? const EmptyWidget(
                      emoji: '🔔',
                      title: '알림이 없어요',
                      subtitle: '새로운 알림이 오면 여기에 표시됩니다',
                    )
                  : RefreshIndicator(
                      color: AppTheme.primary,
                      onRefresh: _loadNotifications,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final notif = _notifications[index];
                          return _buildNotifItem(notif);
                        },
                      ),
                    ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('😔', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          const Text('알림을 불러오지 못했어요',
              style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadNotifications,
            icon: const Icon(Icons.refresh),
            label: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotifItem(NotificationModel notif) {
    final hasLink = notif.relatedId != null;

    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppTheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
      ),
      onDismissed: (_) async {
        try {
          await _api.delete('/notifications/${notif.id}');
        } catch (_) {}
      },
      child: InkWell(
        onTap: hasLink
            ? () => _navigateFromNotification(notif)
            : (!notif.isRead ? () => _markAsRead(notif.id) : null),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: notif.isRead
                ? Colors.white
                : AppTheme.primary.withOpacity(0.04),
            border: Border(
              bottom: BorderSide(color: AppTheme.border),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 아이콘 뱃지
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _notifColor(notif.type).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(notif.typeEmoji, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              // 내용
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: notif.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          _formatTime(notif.createdAt),
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.textLight),
                        ),
                      ],
                    ),
                    if (notif.message != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        notif.message!,
                        style: const TextStyle(
                            fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    // 이동 힌트
                    if (hasLink) ...[
                      const SizedBox(height: 4),
                      Text(
                        _linkLabel(notif.type),
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // 읽지 않은 점
              if (!notif.isRead)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _notifColor(String type) {
    switch (type) {
      case 'prayer_participation': return AppTheme.primary;
      case 'comment': return const Color(0xFF8B5CF6);
      case 'intercession_request':
      case 'intercession_accepted': return AppTheme.success;
      case 'prayer_answered': return AppTheme.warning;
      case 'group_invite': return const Color(0xFF0EA5E9);
      default: return AppTheme.primary;
    }
  }

  String _linkLabel(String type) {
    switch (type) {
      case 'group_invite': return '그룹 보기 →';
      case 'intercession_request':
      case 'intercession_accepted': return '기도 보기 →';
      default: return '기도 보기 →';
    }
  }

  String _formatTime(String createdAt) {
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return '방금';
      if (diff.inHours < 1) return '${diff.inMinutes}분 전';
      if (diff.inDays < 1) return '${diff.inHours}시간 전';
      if (diff.inDays < 7) return '${diff.inDays}일 전';
      return '${dt.month}/${dt.day}';
    } catch (_) {
      return '';
    }
  }
}
