import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
// 소셜 로그인 서비스 import
import '../services/social_auth_service.dart';

enum AuthState { initial, loading, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiService _api = ApiService();
  // 소셜 로그인 서비스 인스턴스
  final SocialAuthService _socialAuthService = SocialAuthService();

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
    } else {
      _state = AuthState.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String nickname,
    String? profileId,
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
        profileId: profileId,
        churchName: churchName,
        denomination: denomination,
      );
      _user = UserModel.fromJson(data['user']);
      _state = AuthState.authenticated;
      notifyListeners();
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
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _state = AuthState.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────
  // 구글 소셜 로그인
  // ─────────────────────────────────────────────────────────
  /// 구글 계정으로 로그인
  /// 성공 시 true, 실패 시 false 반환
  Future<bool> loginWithGoogle() async {
    _state = AuthState.loading;
    _error = null;
    notifyListeners();

    try {
      // 구글 로그인 팝업 표시 및 토큰 교환
      final result = await _socialAuthService.signInWithGoogle();
      if (result == null) {
        // 사용자가 로그인 취소한 경우
        _state = AuthState.unauthenticated;
        notifyListeners();
        return false;
      }

      // 받은 JWT 토큰 및 사용자 정보 저장
      await _authService.saveToken(result.token);
      await _authService.saveUser(result.user);
      _user = UserModel.fromJson(result.user);
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _state = AuthState.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────
  // 카카오 소셜 로그인
  // ─────────────────────────────────────────────────────────
  /// 카카오 계정으로 로그인
  /// 카카오톡 앱이 있으면 앱으로, 없으면 웹으로 로그인
  /// 성공 시 true, 실패 시 false 반환
  Future<bool> loginWithKakao() async {
    _state = AuthState.loading;
    _error = null;
    notifyListeners();

    try {
      // 카카오 로그인 실행 (앱 or 웹)
      final result = await _socialAuthService.signInWithKakao();
      if (result == null) {
        _state = AuthState.unauthenticated;
        notifyListeners();
        return false;
      }

      // 받은 JWT 토큰 및 사용자 정보 저장
      await _authService.saveToken(result.token);
      await _authService.saveUser(result.user);
      _user = UserModel.fromJson(result.user);
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _state = AuthState.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    // 소셜 로그인도 함께 로그아웃 처리
    await _socialAuthService.signOutGoogle();
    await _socialAuthService.signOutKakao();
    _user = null;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

