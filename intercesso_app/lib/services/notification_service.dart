// lib/services/notification_service.dart
import '../models/models.dart';
import 'api_service.dart';

class NotificationService {
  final ApiService _api = ApiService();

  Future<List<NotificationModel>> getNotifications({
    int page = 1,
    int limit = 20,
    bool? isRead,
  }) async {
    final params = <String, String>{'page': '$page', 'limit': '$limit'};
    if (isRead != null) params['is_read'] = '$isRead';
    final response = await _api.get('/notifications', queryParams: params);
    final List<dynamic> data = response['data'] ?? [];
    return data.map((n) => NotificationModel.fromJson(n)).toList();
  }

  Future<int> getUnreadCount() async {
    final response = await _api.get('/notifications/unread-count');
    return response['data']['count'] ?? 0;
  }

  Future<void> markAsRead(String notificationId) async {
    await _api.put('/notifications/$notificationId/read');
  }

  Future<void> markAllAsRead() async {
    await _api.put('/notifications/read-all');
  }

  Future<void> deleteNotification(String notificationId) async {
    await _api.delete('/notifications/$notificationId');
  }

  Future<Map<String, dynamic>> getPreferences() async {
    final response = await _api.get('/notifications/preferences');
    return response['data'] ?? {};
  }

  Future<Map<String, dynamic>> updatePreferences(Map<String, dynamic> prefs) async {
    final response = await _api.put('/notifications/preferences', body: prefs);
    return response['data'] ?? {};
  }
}
