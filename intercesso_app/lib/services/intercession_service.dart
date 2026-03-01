// lib/services/intercession_service.dart
import '../models/models.dart';
import 'api_service.dart';

class IntercessionService {
  final ApiService _api = ApiService();

  Future<List<IntercessionModel>> getReceivedRequests({String? status}) async {
    final params = <String, String>{};
    if (status != null) params['status'] = status;
    final response = await _api.get('/intercessions/received', queryParams: params);
    final raw = response['data'];
    List<dynamic> data = [];
    if (raw is List) data = raw;
    else if (raw is Map && raw['data'] is List) data = raw['data'];
    return data.map((i) => IntercessionModel.fromJson(i)).toList();
  }

  Future<List<IntercessionModel>> getSentRequests({String? status}) async {
    final params = <String, String>{};
    if (status != null) params['status'] = status;
    final response = await _api.get('/intercessions/sent', queryParams: params);
    final raw = response['data'];
    List<dynamic> data = [];
    if (raw is List) data = raw;
    else if (raw is Map && raw['data'] is List) data = raw['data'];
    return data.map((i) => IntercessionModel.fromJson(i)).toList();
  }

  /// 전체공개 요청
  Future<void> sendPublicRequest({
    required String prayerId,
    String? message,
  }) async {
    await _api.post('/intercessions', body: {
      'prayer_id': prayerId,
      'target_type': 'public',
      if (message != null && message.isNotEmpty) 'message': message,
    });
  }

  /// 그룹 요청
  Future<void> sendGroupRequest({
    required String prayerId,
    required String groupId,
    String? message,
  }) async {
    await _api.post('/intercessions', body: {
      'prayer_id': prayerId,
      'target_type': 'group',
      'group_id': groupId,
      if (message != null && message.isNotEmpty) 'message': message,
    });
  }

  /// 개인 요청
  Future<void> sendPersonalRequest({
    required String prayerId,
    required String recipientId,
    String? message,
    String priority = 'normal',
  }) async {
    await _api.post('/intercessions', body: {
      'prayer_id': prayerId,
      'target_type': 'individual',
      'recipient_id': recipientId,
      if (message != null && message.isNotEmpty) 'message': message,
      'priority': priority,
    });
  }

  /// 사용자 검색 (개인 요청용)
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final response = await _api.get('/intercessions/search-users', queryParams: {'q': query});
    final raw = response['data'];
    if (raw is List) return raw.cast<Map<String, dynamic>>();
    return [];
  }

  Future<IntercessionModel> respondToRequest(
    String requestId, {
    required String status,
  }) async {
    final response = await _api.put('/intercessions/$requestId/respond', body: {
      'status': status,
    });
    return IntercessionModel.fromJson(response['data']);
  }
}
