import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../routes/app_router.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 백그라운드 메시지 핸들러 (앱 종료/백그라운드 상태)
/// 반드시 top-level 함수여야 함
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('📨 [FCM 백그라운드] ${message.notification?.title}: ${message.notification?.body}');
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// 앱 시작 시 초기화 (main.dart에서 호출)
  Future<void> initialize() async {
    // 백그라운드 핸들러 등록
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 로컬 알림 초기화 (Android)
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Android 알림 채널 생성 (Android 8.0+)
    const channel = AndroidNotificationChannel(
      'intercesso_channel',
      'Intercesso 알림',
      description: '중보기도 요청, 댓글 등의 알림',
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 포그라운드 메시지 처리 (앱 실행 중)
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 알림 클릭으로 앱 열릴 때 (백그라운드 → 포그라운드)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpen);

    // 앱이 종료된 상태에서 알림 클릭으로 시작된 경우
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      // 앱이 완전히 시작된 후 처리하기 위해 약간의 딜레이
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleNotificationOpen(initialMessage);
      });
    }

    debugPrint('✅ FCM 서비스 초기화 완료');
  }

  /// 알림 권한 요청 + FCM 토큰 발급 및 서버 저장
  /// 로그인 성공 후 호출
  Future<void> requestPermissionAndRegister(String authToken) async {
    // 권한 요청
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await _registerToken(authToken);
    } else {
      debugPrint('⚠️ 알림 권한 거부됨');
    }
  }

  /// FCM 토큰 서버 등록 + 로컬 저장
  Future<void> _registerToken(String authToken) async {
    try {
      final token = await _fcm.getToken();
      if (token == null) return;

      debugPrint('📱 FCM 토큰: ${token.substring(0, 20)}...');

      // 이전 토큰과 같으면 스킵
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('fcm_token');
      if (savedToken == token) return;

      // 서버에 토큰 저장
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/users/me/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'token': token}),
      );

      if (response.statusCode == 200) {
        await prefs.setString('fcm_token', token);
        debugPrint('✅ FCM 토큰 서버 저장 완료');
      }
    } catch (e) {
      debugPrint('❌ FCM 토큰 등록 실패: $e');
    }
  }

  /// 로그아웃 시 서버에서 토큰 삭제
  Future<void> deleteToken(String authToken) async {
    try {
      await http.delete(
        Uri.parse('${AppConstants.baseUrl}/users/me/fcm-token'),
        headers: {'Authorization': 'Bearer $authToken'},
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('fcm_token');
      debugPrint('✅ FCM 토큰 삭제 완료');
    } catch (e) {
      debugPrint('❌ FCM 토큰 삭제 실패: $e');
    }
  }

  /// 포그라운드 메시지 처리 (앱 실행 중 수신)
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📨 [FCM 포그라운드] ${message.notification?.title}');

    final notification = message.notification;
    if (notification == null) return;

    // 로컬 알림으로 표시 (포그라운드에서는 자동 표시 안 됨)
    _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'intercesso_channel',
          'Intercesso 알림',
          channelDescription: '중보기도 요청, 댓글 등의 알림',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  /// 알림 클릭 처리 - 화면 이동 (백그라운드/종료 상태에서 클릭 시)
  void _handleNotificationOpen(RemoteMessage message) {
    debugPrint('🔔 알림 클릭: ${message.data}');
    _navigateFromData(message.data);
  }

  /// 로컬 알림 클릭 처리 (포그라운드 알림 클릭)
  void _onNotificationTap(NotificationResponse response) {
    debugPrint('🔔 로컬 알림 클릭: ${response.payload}');
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        _navigateFromData(data);
      } catch (_) {}
    }
  }

  /// FCM 데이터에 따라 화면 이동
  void _navigateFromData(Map<String, dynamic> data) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final type = data['type'] as String?;
    final relatedId = data['related_id'] as String?;

    switch (type) {
      case 'prayer_participation':
      case 'comment':
      case 'prayer_answer':
        // 기도 상세 화면으로 이동
        if (relatedId != null) {
          navigatorKey.currentContext?.go('/prayer/$relatedId');
        }
        break;
      case 'intercession_request':
        // 중보기도 화면으로 이동 (홈의 중보기도 탭)
        navigatorKey.currentContext?.go('/home');
        break;
      case 'group_invite':
      case 'group_join':
        // 그룹 상세 화면으로 이동
        if (relatedId != null) {
          navigatorKey.currentContext?.go('/group/$relatedId');
        }
        break;
      default:
        // 기본: 알림 화면으로 이동
        navigatorKey.currentContext?.go('/notifications');
        break;
    }
  }
}
