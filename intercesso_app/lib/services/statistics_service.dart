import 'api_service.dart';

class StatisticsService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> getMyStatistics() async {
    return _api.get('/statistics/me');
  }

  Future<Map<String, dynamic>> getDashboard() async {
    return _api.get('/statistics/dashboard');
  }

  Future<Map<String, dynamic>> getUserStatistics(String userId) async {
    return _api.get('/statistics/users/$userId');
  }
}
