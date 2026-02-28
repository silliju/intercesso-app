import '../models/models.dart';
import 'api_service.dart';

class PrayerService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> getPrayers({
    int page = 1,
    int limit = 10,
    String? scope,
    String? category,
    String? status,
    String? groupId,
  }) async {
    final params = <String, String>{'page': '$page', 'limit': '$limit'};
    if (scope != null) params['scope'] = scope;
    if (category != null) params['category'] = category;
    if (status != null) params['status'] = status;
    if (groupId != null) params['group_id'] = groupId;

    return _api.get('/prayers', queryParams: params);
  }

  Future<PrayerModel> getPrayerById(String prayerId) async {
    final response = await _api.get('/prayers/$prayerId');
    return PrayerModel.fromJson(response['data']);
  }

  Future<PrayerModel> createPrayer({
    required String title,
    required String content,
    String? category,
    String scope = 'public',
    String? groupId,
    bool isCovenant = false,
    int? covenantDays,
    String? covenantStartDate,
  }) async {
    final response = await _api.post('/prayers', body: {
      'title': title,
      'content': content,
      if (category != null) 'category': category,
      'scope': scope,
      if (groupId != null) 'group_id': groupId,
      'is_covenant': isCovenant,
      if (covenantDays != null) 'covenant_days': covenantDays,
      if (covenantStartDate != null) 'covenant_start_date': covenantStartDate,
    });
    return PrayerModel.fromJson(response['data']);
  }

  Future<PrayerModel> updatePrayer(
    String prayerId, {
    String? title,
    String? content,
    String? category,
    String? scope,
    String? status,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (content != null) body['content'] = content;
    if (category != null) body['category'] = category;
    if (scope != null) body['scope'] = scope;
    if (status != null) body['status'] = status;

    final response = await _api.put('/prayers/$prayerId', body: body);
    return PrayerModel.fromJson(response['data']);
  }

  Future<void> deletePrayer(String prayerId) async {
    await _api.delete('/prayers/$prayerId');
  }

  Future<void> participatePrayer(String prayerId) async {
    await _api.post('/prayers/$prayerId/participate');
  }

  Future<void> cancelParticipation(String prayerId) async {
    await _api.delete('/prayers/$prayerId/participate');
  }

  Future<CommentModel> createComment(String prayerId, String content) async {
    final response = await _api.post('/prayers/$prayerId/comments', body: {
      'content': content,
    });
    return CommentModel.fromJson(response['data']);
  }

  Future<void> deleteComment(String commentId) async {
    await _api.delete('/prayers/comments/$commentId');
  }

  Future<List<dynamic>> getCheckins(String prayerId) async {
    final response = await _api.get('/prayers/$prayerId/checkins');
    return response['data'] ?? [];
  }

  Future<void> checkIn(String prayerId, int day) async {
    await _api.post('/prayers/$prayerId/checkins', body: {'day': day});
  }
}
