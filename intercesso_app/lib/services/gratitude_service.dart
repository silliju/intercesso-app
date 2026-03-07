import '../models/models.dart';
import 'api_service.dart';

class GratitudeService {
  final ApiService _api = ApiService();

  // ── CRUD ──────────────────────────────────────────────────

  /// 감사일기 작성 / 수정 (upsert)
  Future<GratitudeModel> saveJournal({
    required String gratitude1,
    String? gratitude2,
    String? gratitude3,
    String? emotion,
    String? linkedPrayerId,
    String scope = 'private',
    String? journalDate,
  }) async {
    final response = await _api.post('/gratitude', body: {
      'gratitude_1': gratitude1,
      if (gratitude2 != null && gratitude2.isNotEmpty) 'gratitude_2': gratitude2,
      if (gratitude3 != null && gratitude3.isNotEmpty) 'gratitude_3': gratitude3,
      if (emotion != null) 'emotion': emotion,
      if (linkedPrayerId != null) 'linked_prayer_id': linkedPrayerId,
      'scope': scope,
      if (journalDate != null) 'journal_date': journalDate,
    });
    return GratitudeModel.fromJson(response['data']);
  }

  /// 오늘의 감사일기 조회
  Future<GratitudeModel?> getTodayJournal() async {
    final response = await _api.get('/gratitude/today');
    if (response['data'] == null) return null;
    return GratitudeModel.fromJson(response['data']);
  }

  /// 내 감사일기 목록
  Future<Map<String, dynamic>> getMyJournals({int page = 1, int limit = 20}) async {
    return _api.get('/gratitude/my', queryParams: {
      'page': '$page',
      'limit': '$limit',
    });
  }

  /// 특정 일기 상세
  Future<GratitudeModel> getJournalById(String journalId) async {
    final response = await _api.get('/gratitude/$journalId');
    return GratitudeModel.fromJson(response['data']);
  }

  /// 수정
  Future<GratitudeModel> updateJournal(String journalId, Map<String, dynamic> body) async {
    final response = await _api.put('/gratitude/$journalId', body: body);
    return GratitudeModel.fromJson(response['data']);
  }

  /// 삭제
  Future<void> deleteJournal(String journalId) async {
    await _api.delete('/gratitude/$journalId');
  }

  // ── 소셜 피드 ──────────────────────────────────────────────

  /// 피드 조회 (group | following | public)
  Future<Map<String, dynamic>> getFeed({
    String tab = 'group',
    int page = 1,
    int limit = 20,
  }) async {
    return _api.get('/gratitude/feed', queryParams: {
      'tab': tab,
      'page': '$page',
      'limit': '$limit',
    });
  }

  // ── 반응 ──────────────────────────────────────────────────

  /// 반응 토글 (grace | empathy)
  Future<Map<String, dynamic>> toggleReaction(String journalId, String reactionType) async {
    return _api.post('/gratitude/$journalId/reactions', body: {
      'reaction_type': reactionType,
    });
  }

  // ── 댓글 ──────────────────────────────────────────────────

  /// 댓글 작성
  Future<Map<String, dynamic>> addComment(String journalId, String content) async {
    return _api.post('/gratitude/$journalId/comments', body: {'content': content});
  }

  /// 댓글 삭제
  Future<void> deleteComment(String commentId) async {
    await _api.delete('/gratitude/comments/$commentId');
  }

  // ── 스트릭 & 캘린더 ────────────────────────────────────────

  /// 스트릭 조회
  Future<GratitudeStreakModel> getStreak() async {
    final response = await _api.get('/gratitude/streak');
    return GratitudeStreakModel.fromJson(response['data'] ?? {});
  }

  /// 캘린더 조회
  Future<Map<String, dynamic>> getCalendar({int? year, int? month}) async {
    final now = DateTime.now();
    return _api.get('/gratitude/calendar', queryParams: {
      'year': '${year ?? now.year}',
      'month': '${month ?? now.month}',
    });
  }
}
