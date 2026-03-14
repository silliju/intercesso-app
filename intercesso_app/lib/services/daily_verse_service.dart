import 'dart:async';
import '../services/api_service.dart';

class DailyVerseService {
  final ApiService _api = ApiService();

  /// 오늘의 말씀 조회 (클라이언트 기준 오늘 날짜). 10초 안에 응답 없으면 로컬 fallback으로 빠르게 전환.
  Future<Map<String, String>> getTodayVerse() async {
    final now = DateTime.now();
    final date = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final res = await _api.get('/daily-verse/today', queryParams: {'date': date}).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw TimeoutException('오늘의 말씀 로드 지연'),
    );
    final data = (res['data'] as Map?)?.cast<String, dynamic>() ?? {};
    return {
      'text': (data['text'] as String?) ?? '',
      'reference': (data['reference'] as String?) ?? '',
    };
  }
}

