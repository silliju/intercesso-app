import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/find_account_screen.dart';
import '../screens/main/main_tab_screen.dart';
import '../screens/prayer/prayer_detail_screen.dart';
import '../screens/prayer/create_prayer_screen.dart';
import '../screens/prayer/prayer_edit_screen.dart';
import '../screens/group/group_detail_screen.dart';
import '../screens/group/create_group_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuth = authProvider.isAuthenticated;
      final isSplash = state.matchedLocation == '/splash';
      final isOnboarding = state.matchedLocation == '/onboarding';
      final isLogin = state.matchedLocation == '/login';
      final isSignup = state.matchedLocation == '/signup';

      if (isSplash) return null;

      if (authProvider.state == AuthState.initial) {
        return '/splash';
      }

      if (!isAuth && !isOnboarding && !isLogin && !isSignup) {
        final isFindAccount = state.matchedLocation == '/find-account';
        if (!isFindAccount) return '/login';
      }

      if (isAuth && (isLogin || isSignup || isOnboarding)) {
        return '/home';
      }

      return null;
    },
    refreshListenable: authProvider,
    routes: [
      GoRoute(path: '/splash', builder: (ctx, state) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (ctx, state) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (ctx, state) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (ctx, state) => const SignupScreen()),
      GoRoute(
        path: '/find-account',
        builder: (ctx, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return FindAccountScreen(showPasswordTab: extra?['showPasswordTab'] == true);
        },
      ),
      GoRoute(path: '/home', builder: (ctx, state) => const MainTabScreen()),
      GoRoute(
        path: '/prayer/:id',
        builder: (ctx, state) => PrayerDetailScreen(prayerId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/prayer/create',
        builder: (ctx, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return CreatePrayerScreen(groupId: extra?['groupId']);
        },
      ),
      GoRoute(
        path: '/prayer/:id/edit',
        builder: (ctx, state) => PrayerEditScreen(prayerId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/group/:id',
        builder: (ctx, state) => GroupDetailScreen(groupId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/group/create',
        builder: (ctx, state) => const CreateGroupScreen(),
      ),
      GoRoute(path: '/profile/edit', builder: (ctx, state) => const EditProfileScreen()),
      GoRoute(path: '/notifications', builder: (ctx, state) => const NotificationsScreen()),
      GoRoute(path: '/dashboard', builder: (ctx, state) => const DashboardScreen()),
    ],
  );
}
