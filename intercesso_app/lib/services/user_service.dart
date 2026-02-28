// lib/services/user_service.dart
import '../models/models.dart';
import 'api_service.dart';

class UserService {
  final ApiService _api = ApiService();

  Future<UserModel> getProfile(String userId) async {
    final response = await _api.get('/users/$userId');
    return UserModel.fromJson(response['data']);
  }

  Future<UserModel> updateProfile({
    String? nickname,
    String? churchName,
    String? denomination,
    String? bio,
  }) async {
    final body = <String, dynamic>{};
    if (nickname != null) body['nickname'] = nickname;
    if (churchName != null) body['church_name'] = churchName;
    if (denomination != null) body['denomination'] = denomination;
    if (bio != null) body['bio'] = bio;
    final response = await _api.put('/users/me', body: body);
    return UserModel.fromJson(response['data']);
  }

  Future<Map<String, dynamic>> getStatistics(String userId) async {
    final response = await _api.get('/statistics/$userId');
    return response['data'] ?? {};
  }

  Future<List<UserModel>> searchUsers(String query) async {
    final response = await _api.get('/users/search', queryParams: {'q': query});
    final List<dynamic> data = response['data'] ?? [];
    return data.map((u) => UserModel.fromJson(u)).toList();
  }
}
