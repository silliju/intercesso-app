import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../models/models.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String nickname,
    String? churchName,
    String? denomination,
    String? bio,
  }) async {
    final response = await _api.post('/auth/signup', body: {
      'email': email,
      'password': password,
      'nickname': nickname,
      if (churchName != null) 'church_name': churchName,
      if (denomination != null) 'denomination': denomination,
      if (bio != null) 'bio': bio,
    });

    final token = response['data']['token'];
    final userData = response['data']['user'];

    await _api.setToken(token);
    await _saveUserData(userData);

    return response['data'];
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.post('/auth/login', body: {
      'email': email,
      'password': password,
    });

    final token = response['data']['token'];
    final userData = response['data']['user'];

    await _api.setToken(token);
    await _saveUserData(userData);

    return response['data'];
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } catch (_) {}
    await _api.clearToken();
  }

  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.userDataKey, jsonEncode(userData));
    await prefs.setString(AppConstants.userIdKey, userData['id']);
  }

  Future<UserModel?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(AppConstants.userDataKey);
    if (data == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(data));
    } catch (_) {
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    return token != null && token.isNotEmpty;
  }

  // ─────────────────────────────────────────────────────────
  // 소셜 로그인용 토큰/사용자 저장 메서드
  // ─────────────────────────────────────────────────────────

  /// 소셜 로그인 후 백엔드에서 받은 JWT 토큰을 저장합니다
  Future<void> saveToken(String token) async {
    await _api.setToken(token);
  }

  /// 소셜 로그인 후 받은 사용자 정보를 로컬에 저장합니다
  Future<void> saveUser(Map<String, dynamic> userData) async {
    await _saveUserData(userData);
  }
}
