import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/register_church_screen.dart';
import '../screens/auth/find_account_screen.dart';
import '../screens/main/main_tab_screen.dart';
import '../screens/prayer/prayer_detail_screen.dart';
import '../screens/prayer/create_prayer_screen.dart';
import '../screens/prayer/prayer_edit_screen.dart';
import '../screens/group/group_detail_screen.dart';
import '../screens/group/create_group_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/gratitude/gratitude_feed_screen.dart';
import '../screens/gratitude/gratitude_calendar_screen.dart';
import '../screens/gratitude/create_gratitude_screen.dart';
import '../screens/choir/choir_home_screen.dart';
import '../screens/choir/choir_create_screen.dart';
import '../screens/choir/choir_join_screen.dart';
import '../screens/choir/choir_schedule_screen.dart';
import '../screens/choir/choir_members_screen.dart';
import '../screens/choir/choir_attendance_screen.dart';
import '../screens/choir/choir_library_screen.dart';
import '../screens/choir/choir_management_screen.dart';
import '../screens/choir/choir_song_screen.dart';
import '../screens/choir/choir_notice_screen.dart';

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
      final isSignupRegisterChurch = state.matchedLocation == '/signup/register-church';

      if (isSplash) return null;

      if (authProvider.state == AuthState.initial) {
        return '/splash';
      }

      if (!isAuth && !isOnboarding && !isLogin && !isSignup && !isSignupRegisterChurch) {
        final isFindAccount = state.matchedLocation == '/find-account';
        if (!isFindAccount) return '/login';
      }

      if (isAuth && (isLogin || isSignup || isSignupRegisterChurch || isOnboarding)) {
        return '/home';
      }

      return null;
    },
    refreshListenable: authProvider,
    routes: [
      GoRoute(path: '/splash', builder: (ctx, state) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (ctx, state) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (ctx, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (ctx, state) => const SignupScreen(),
        routes: [
          GoRoute(
            path: 'register-church',
            builder: (ctx, state) => const RegisterChurchScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/find-account',
        builder: (ctx, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return FindAccountScreen(showPasswordTab: extra?['showPasswordTab'] == true);
        },
      ),
      GoRoute(
        path: '/home',
        builder: (ctx, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final tabIndex = extra?['tabIndex'] as int?;
          return MainTabScreen(initialTabIndex: tabIndex);
        },
      ),
      GoRoute(path: '/my', builder: (ctx, state) => const ProfileScreen()),
      // ⚠️ /prayer/create 반드시 /prayer/:id 보다 먼저 등록해야 충돌 방지
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
        path: '/prayer/:id',
        builder: (ctx, state) => PrayerDetailScreen(prayerId: state.pathParameters['id']!),
      ),
      // ⚠️ /group/create 반드시 /group/:id 보다 먼저 등록
      GoRoute(
        path: '/group/create',
        builder: (ctx, state) => const CreateGroupScreen(),
      ),
      GoRoute(
        path: '/group/:id',
        builder: (ctx, state) => GroupDetailScreen(groupId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/profile/edit', builder: (ctx, state) => const EditProfileScreen()),
      GoRoute(path: '/notifications', builder: (ctx, state) => const NotificationsScreen()),
      GoRoute(path: '/dashboard', builder: (ctx, state) => const DashboardScreen()),
      GoRoute(path: '/gratitude', builder: (ctx, state) => const GratitudeFeedScreen()),
      GoRoute(path: '/gratitude/calendar', builder: (ctx, state) => const GratitudeCalendarScreen()),
      GoRoute(
        path: '/gratitude/create',
        builder: (ctx, state) => const CreateGratitudeScreen(),
      ),
      // ── 찬양대 모듈 라우트 ──────────────────────────────
      GoRoute(
        path: '/choir',
        builder: (ctx, state) => const ChoirHomeScreen(),
      ),
      GoRoute(
        path: '/choir/create',
        builder: (ctx, state) => const ChoirCreateScreen(),
      ),
      GoRoute(
        path: '/choir/join',
        builder: (ctx, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ChoirJoinScreen(initialCode: extra?['code']);
        },
      ),
      GoRoute(
        path: '/choir/schedules',
        builder: (ctx, state) => const ChoirSchedulesScreen(),
      ),
      GoRoute(
        path: '/choir/schedule/:id',
        builder: (ctx, state) => ChoirScheduleDetailScreen(
          scheduleId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/choir/members',
        builder: (ctx, state) => const ChoirMembersScreen(),
      ),
      GoRoute(
        path: '/choir/attendance/:scheduleId',
        builder: (ctx, state) => ChoirAttendanceScreen(
          scheduleId: state.pathParameters['scheduleId']!,
        ),
      ),
      GoRoute(
        path: '/choir/stats',
        builder: (ctx, state) => const ChoirAttendanceStatsScreen(),
      ),
      GoRoute(
        path: '/choir/library',
        builder: (ctx, state) => const ChoirLibraryScreen(),
      ),
      GoRoute(
        path: '/choir/management',
        builder: (ctx, state) => const ChoirManagementScreen(),
      ),
      GoRoute(
        path: '/choir/songs',
        builder: (ctx, state) => const ChoirSongScreen(),
      ),
      GoRoute(
        path: '/choir/notices',
        builder: (ctx, state) => const ChoirNoticeScreen(),
      ),
    ],
  );
}
