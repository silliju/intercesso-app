// lib/services/intercession_service.dart
import '../models/models.dart';
import 'api_service.dart';

class IntercessionService {
  final ApiService _api = ApiService();

  Future<List<IntercessionModel>> getReceivedRequests({String? status}) async {
    final params = <String, String>{};
    if (status != null) params['status'] = status;
    final response = await _api.get('/intercessions/received', queryParams: params);
    final List<dynamic> data = response['data'] ?? [];
    return data.map((i) => IntercessionModel.fromJson(i)).toList();
  }

  Future<List<IntercessionModel>> getSentRequests({String? status}) async {
    final params = <String, String>{};
    if (status != null) params['status'] = status;
    final response = await _api.get('/intercessions/sent', queryParams: params);
    final List<dynamic> data = response['data'] ?? [];
    return data.map((i) => IntercessionModel.fromJson(i)).toList();
  }

  Future<IntercessionModel> sendIntercessionRequest({
    required String prayerId,
    required String recipientId,
    String? message,
    String priority = 'normal',
  }) async {
    final response = await _api.post('/intercessions', body: {
      'prayer_id': prayerId,
      'recipient_id': recipientId,
      if (message != null) 'message': message,
      'priority': priority,
    });
    return IntercessionModel.fromJson(response['data']);
  }

  Future<IntercessionModel> respondToRequest(
    String requestId, {
    required String status, // 'accepted' or 'rejected'
  }) async {
    final response = await _api.put('/intercessions/$requestId/respond', body: {
      'status': status,
    });
    return IntercessionModel.fromJson(response['data']);
  }
}
