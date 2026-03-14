// lib/services/intercession_service.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../config/constants.dart';
import 'api_service.dart';

class IntercessionService {
  final ApiService _api = ApiService();

  /// 현재 로그인된 userId 조회
  Future<String?> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.userIdKey);
  }

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
  /// Railway 구버전 호환: /intercessions/request 레거시 엔드포인트 먼저 시도
  Future<Map<String, dynamic>> sendPublicRequest({
    required String prayerId,
    String? message,
  }) async {
    final myId = await _getCurrentUserId();

    // 신버전 엔드포인트 먼저 시도
    try {
      final res = await _api.post('/intercessions', body: {
        'prayer_id': prayerId,
        'target_type': 'public',
        'recipient_id': myId,
        if (message != null && message.isNotEmpty) 'message': message,
      });
      final success = res['success'] == true;
      final errMsg = res['message'] as String? ?? '';
      // 신버전 성공 또는 대상자ID 에러가 아닌 경우 반환
      if (success || (!errMsg.contains('대상자 ID') && res['error']?['code'] != 'VALIDATION_ERROR')) {
        return res;
      }
    } catch (e) {
      debugPrint('IntercessionService 신버전 엔드포인트 실패: $e');
    }

    // Railway 구버전 레거시 엔드포인트로 fallback
    return await _api.post('/intercessions/request', body: {
      'prayer_id': prayerId,
      'recipient_id': myId,
      if (message != null && message.isNotEmpty) 'message': message,
    });
  }

  /// 그룹 요청
  /// Railway 구버전 호환: /intercessions/request 레거시 엔드포인트 fallback
  Future<Map<String, dynamic>> sendGroupRequest({
    required String prayerId,
    required String groupId,
    String? groupName,
    String? message,
  }) async {
    final myId = await _getCurrentUserId();

    // 신버전 엔드포인트 먼저 시도
    try {
      final res = await _api.post('/intercessions', body: {
        'prayer_id': prayerId,
        'target_type': 'group',
        'group_id': groupId,
        'recipient_id': myId,
        if (message != null && message.isNotEmpty) 'message': message,
      });
      final success = res['success'] == true;
      final errMsg = res['message'] as String? ?? '';
      if (success || (!errMsg.contains('대상자 ID') && res['error']?['code'] != 'VALIDATION_ERROR')) {
        return res;
      }
    } catch (e) {
      debugPrint('IntercessionService 그룹 요청 신버전 실패: $e');
    }

    // Railway 구버전 레거시 엔드포인트로 fallback
    final fallbackMsg = groupName != null
        ? '[그룹:$groupName] ${message ?? ''}'.trim()
        : message ?? '';
    return await _api.post('/intercessions/request', body: {
      'prayer_id': prayerId,
      'recipient_id': myId,
      if (fallbackMsg.isNotEmpty) 'message': fallbackMsg,
    });
  }

  /// 개인 요청
  Future<Map<String, dynamic>> sendPersonalRequest({
    required String prayerId,
    required String recipientId,
    String? message,
    String priority = 'normal',
  }) async {
    return await _api.post('/intercessions', body: {
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
