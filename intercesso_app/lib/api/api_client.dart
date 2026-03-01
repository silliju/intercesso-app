// api_client.dart — ApiService의 alias (하위 호환용)
export '../services/api_service.dart' show ApiService, ApiException;
import '../services/api_service.dart';

/// PrayerAnswerService 등에서 사용하는 ApiClient 클래스
/// 내부적으로 ApiService 싱글톤을 위임한다.
class ApiClient {
  final ApiService _svc = ApiService();

  Future<Map<String, dynamic>> get(String path,
      {Map<String, String>? queryParams}) =>
      _svc.get(path, queryParams: queryParams);

  Future<Map<String, dynamic>> post(String path,
      {Map<String, dynamic>? body}) =>
      _svc.post(path, body: body);

  Future<Map<String, dynamic>> put(String path,
      {Map<String, dynamic>? body}) =>
      _svc.put(path, body: body);

  Future<Map<String, dynamic>> delete(String path) =>
      _svc.delete(path);
}
