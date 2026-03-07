import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/fcm_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';

enum AuthState { initial, loading, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiService _api = ApiService();

  AuthState _state = AuthState.initial;
  UserModel? _user;
  String? _error;

  AuthState get state => _state;
  UserModel? get user => _user;
  String? get error => _error;
  bool get isAuthenticated => _state == AuthState.authenticated;

  Future<void> init() async {
    await _api.init();
    final isLoggedIn = await _authService.isLoggedIn();
    if (isLoggedIn) {
      _user = await _authService.getSavedUser();
      _state = AuthState.authenticated;

      // 앱 재시작 시에도 FCM 토큰 갱신 시도
      _registerFcmToken();
    } else {
      _state = AuthState.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String nickname,
    String? churchName,
    String? denomination,
  }) async {
    _state = AuthState.loading;
    _error = null;
    notifyListeners();

    try {
      final data = await _authService.signUp(
        email: email,
        password: password,
        nickname: nickname,
        churchName: churchName,
        denomination: denomination,
      );
      _user = UserModel.fromJson(data['user']);
      _state = AuthState.authenticated;
      notifyListeners();

      // 회원가입 성공 후 FCM 토큰 등록
      _registerFcmToken();

      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _state = AuthState.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _state = AuthState.loading;
    _error = null;
    notifyListeners();

    try {
      final data = await _authService.login(email: email, password: password);
      _user = UserModel.fromJson(data['user']);
      _state = AuthState.authenticated;
      notifyListeners();

      // 로그인 성공 후 FCM 토큰 등록
      _registerFcmToken();

      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _state = AuthState.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    // 로그아웃 전 FCM 토큰 서버에서 삭제
    await _deleteFcmToken();

    await _authService.logout();
    _user = null;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }

  // 프로필 수정 후 유저 정보 재로드
  Future<void> refreshUser() async {
    try {
      final response = await _api.get('/users/me');
      if (response['success'] == true && response['data'] != null) {
        _user = UserModel.fromJson(response['data']);
        notifyListeners();
      }
    } catch (_) {}
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// FCM 토큰 등록 (내부 헬퍼)
  Future<void> _registerFcmToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.tokenKey);
      if (token != null && token.isNotEmpty) {
        await FcmService().requestPermissionAndRegister(token);
      }
    } catch (e) {
      debugPrint('❌ FCM 토큰 등록 중 오류: $e');
    }
  }

  /// FCM 토큰 삭제 (내부 헬퍼)
  Future<void> _deleteFcmToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.tokenKey);
      if (token != null && token.isNotEmpty) {
        await FcmService().deleteToken(token);
      }
    } catch (e) {
      debugPrint('❌ FCM 토큰 삭제 중 오류: $e');
    }
  }
}
