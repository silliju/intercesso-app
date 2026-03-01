import '../api/api_client.dart';

class PrayerAnswerService {
  final ApiClient _api = ApiClient();

  /// 기도 응답 조회 (없으면 null 반환)
  Future<Map<String, dynamic>?> getAnswer(String prayerId) async {
    try {
      final response = await _api.get('/prayers/$prayerId/answer');
      return response['data'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  /// 기도 응답 등록 / 수정 (upsert)
  Future<Map<String, dynamic>> upsertAnswer(
    String prayerId, {
    String? content,
    String scope = 'public',
  }) async {
    final body = <String, dynamic>{'scope': scope};
    if (content != null) body['content'] = content;
    final response = await _api.post('/prayers/$prayerId/answer', body: body);
    return response;
  }

  /// 기도 응답 삭제
  Future<void> deleteAnswer(String prayerId) async {
    await _api.delete('/prayers/$prayerId/answer');
  }

  /// 응답 댓글 등록
  Future<Map<String, dynamic>> createComment(String prayerId, String content) async {
    final response = await _api.post(
      '/prayers/$prayerId/answer/comments',
      body: {'content': content},
    );
    return response;
  }

  /// 응답 댓글 삭제
  Future<void> deleteComment(String prayerId, String commentId) async {
    await _api.delete('/prayers/$prayerId/answer/comments/$commentId');
  }
}
