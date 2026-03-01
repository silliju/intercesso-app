import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

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

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
