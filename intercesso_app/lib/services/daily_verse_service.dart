import '../services/api_service.dart';

class DailyVerseService {
  final ApiService _api = ApiService();

  /// 오늘의 말씀 조회
  /// GET /daily-verse/today
  Future<Map<String, String>> getTodayVerse() async {
    final res = await _api.get('/daily-verse/today');
    final data = (res['data'] as Map?)?.cast<String, dynamic>() ?? {};
    return {
      'text': (data['text'] as String?) ?? '',
      'reference': (data['reference'] as String?) ?? '',
    };
  }
}

