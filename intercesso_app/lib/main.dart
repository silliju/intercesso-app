import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/prayer_provider.dart';
import 'providers/group_provider.dart';
import 'providers/notification_provider.dart';
import 'routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    _router = createRouter(authProvider);
    // authProvider.init()을 await해서 토큰 복원 완료 후 앱 실행
    _initializeApp(authProvider);
  }

  Future<void> _initializeApp(AuthProvider authProvider) async {
    await authProvider.init(); // 토큰 복원 완료까지 대기
    if (mounted) {
      setState(() => _initialized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 초기화 전에는 스플래시 화면 표시
    if (!_initialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: AppTheme.primary,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🙏', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                const Text(
                  'Intercesso',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '함께 기도하는 공동체',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 40),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return MaterialApp.router(
      title: 'Intercesso',
      theme: AppTheme.lightTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      locale: const Locale('ko', 'KR'),
    );
  }
}
