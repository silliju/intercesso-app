// ============================================================
// main.dart - 앱 진입점
// ============================================================
// 역할: Flutter 앱의 시작점
// - 카카오 SDK 초기화
// - Provider 등록 (상태 관리)
// - 라우터 설정
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// 카카오 SDK 초기화를 위한 import
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'config/theme.dart';
import 'config/constants.dart';
import 'providers/auth_provider.dart';
import 'providers/prayer_provider.dart';
import 'providers/group_provider.dart';
import 'providers/notification_provider.dart';
import 'routes/app_router.dart';

void main() async {
  // Flutter 엔진 초기화 (비동기 작업 전 반드시 호출)
  WidgetsFlutterBinding.ensureInitialized();

  // ─── 카카오 SDK 초기화 ───────────────────────────────────
  // 앱 실행 시 가장 먼저 카카오 SDK를 초기화해야 합니다
  // nativeAppKey: 카카오 개발자 센터에서 발급받은 네이티브 앱 키
  KakaoSdk.init(nativeAppKey: AppConstants.kakaoNativeAppKey);

  runApp(const IntercessoApp());
}

/// 앱의 루트 위젯
/// MultiProvider로 전역 상태 관리자들을 등록합니다
class IntercessoApp extends StatelessWidget {
  const IntercessoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 인증 상태 관리 (로그인/로그아웃/소셜로그인)
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // 기도제목 목록/상태 관리
        ChangeNotifierProvider(create: (_) => PrayerProvider()),
        // 그룹 목록/상태 관리
        ChangeNotifierProvider(create: (_) => GroupProvider()),
        // 알림 목록/상태 관리
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const _AppWithRouter(),
    );
  }
}

/// 라우터가 포함된 MaterialApp 위젯
/// go_router를 사용하여 화면 전환을 관리합니다
class _AppWithRouter extends StatefulWidget {
  const _AppWithRouter();

  @override
  State<_AppWithRouter> createState() => _AppWithRouterState();
}

class _AppWithRouterState extends State<_AppWithRouter> {
  late final dynamic _router;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    // 인증 상태에 따라 라우팅이 결정되는 라우터 생성
    _router = createRouter(authProvider);
    // 앱 초기화 시 로그인 유지 여부 확인 (저장된 토큰 검사)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      authProvider.init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Intercesso',
      theme: AppTheme.lightTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      locale: const Locale('ko', 'KR'),
    );
  }
}
