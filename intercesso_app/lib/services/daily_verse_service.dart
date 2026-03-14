import '../services/api_service.dart';

class DailyVerseService {
  final ApiService _api = ApiService();

  /// 오늘의 말씀 조회 (클라이언트 기준 오늘 날짜로 요청)
  /// GET /daily-verse/today?date=YYYY-MM-DD
  Future<Map<String, String>> getTodayVerse() async {
    final now = DateTime.now();
    final date = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final res = await _api.get('/daily-verse/today', queryParams: {'date': date});
    final data = (res['data'] as Map?)?.cast<String, dynamic>() ?? {};
    return {
      'text': (data['text'] as String?) ?? '',
      'reference': (data['reference'] as String?) ?? '',
    };
  }
}

