import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;
  bool _isRefreshing = false;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(AppConstants.tokenKey);
  }

  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userDataKey);
  }

  bool get hasToken => _token != null && _token!.isNotEmpty;

  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // 토큰 갱신 시도
  Future<bool> _tryRefreshToken() async {
    if (_isRefreshing || _token == null) return false;
    _isRefreshing = true;
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/refresh'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({'token': _token}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final newToken = data['data']?['token'] as String?;
        if (newToken != null && newToken.isNotEmpty) {
          await setToken(newToken);
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, String>? queryParams}) async {
    try {
      Uri uri = Uri.parse('${AppConstants.baseUrl}$path');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }
      final response = await http.get(uri, headers: _headers).timeout(
        const Duration(seconds: 15),
      );
      // 401이면 토큰 갱신 후 재시도
      if (response.statusCode == 401 && !_isRefreshing) {
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          final retryResponse = await http.get(uri, headers: _headers).timeout(
            const Duration(seconds: 15),
          );
          return _handleResponse(retryResponse);
        }
      }
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('네트워크 오류가 발생했습니다: $e');
    }
  }

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body}) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}$path'),
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 15));
      // 401이면 토큰 갱신 후 재시도 (refresh 경로 자체는 제외)
      if (response.statusCode == 401 && !path.contains('/auth/') && !_isRefreshing) {
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          final retryResponse = await http.post(
            Uri.parse('${AppConstants.baseUrl}$path'),
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          ).timeout(const Duration(seconds: 15));
          return _handleResponse(retryResponse);
        }
      }
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('네트워크 오류가 발생했습니다: $e');
    }
  }

  Future<Map<String, dynamic>> put(String path, {Map<String, dynamic>? body}) async {
    try {
      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}$path'),
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 401 && !_isRefreshing) {
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          final retryResponse = await http.put(
            Uri.parse('${AppConstants.baseUrl}$path'),
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          ).timeout(const Duration(seconds: 15));
          return _handleResponse(retryResponse);
        }
      }
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('네트워크 오류가 발생했습니다: $e');
    }
  }

  Future<Map<String, dynamic>> delete(String path) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}$path'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 401 && !_isRefreshing) {
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          final retryResponse = await http.delete(
            Uri.parse('${AppConstants.baseUrl}$path'),
            headers: _headers,
          ).timeout(const Duration(seconds: 15));
          return _handleResponse(retryResponse);
        }
      }
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('네트워크 오류가 발생했습니다: $e');
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      } else {
        final message = data['message'] ?? '오류가 발생했습니다';
        final errorCode = data['code'] as String?;
        throw ApiException(
          message,
          statusCode: response.statusCode,
          errorCode: errorCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('응답 처리 오류: $e');
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;

  ApiException(this.message, {this.statusCode, this.errorCode});

  @override
  String toString() => message;
}
