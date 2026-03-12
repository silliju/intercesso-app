import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/prayer_provider.dart';
import 'providers/group_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/gratitude_provider.dart';
import 'providers/choir_provider.dart';
import 'routes/app_router.dart';
import 'services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase/FCM은 현재 웹에서 FirebaseOptions 미설정으로 인해 크래시 발생.
  // 우선 모바일(Android/iOS)에서만 초기화하고, 웹에서는 건너뛴다.
  if (!kIsWeb) {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await FcmService().initialize();
  }

  runApp(const IntercessoApp());
}

class IntercessoApp extends StatelessWidget {
  const IntercessoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PrayerProvider()),
        ChangeNotifierProvider(create: (_) => GroupProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => GratitudeProvider()),
        ChangeNotifierProvider(create: (_) => ChoirProvider()),
      ],
      child: const _AppWithRouter(),
    );
  }
}

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
    _router = createRouter(authProvider);
    // init()은 SplashScreen에서 호출 - 중복 호출 제거
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
