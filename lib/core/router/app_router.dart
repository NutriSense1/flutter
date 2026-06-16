import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../screens/onboarding/splash_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/onboarding/auth_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/home/main_shell.dart';
import '../../screens/scanner/scanner_screen.dart';
import '../../screens/scanner/scan_result_screen.dart';
import '../../screens/diary/diary_screen.dart';
import '../../screens/weight/weight_screen.dart';
import '../../screens/water/water_screen.dart';
import '../../screens/coach/coach_screen.dart';
import '../../screens/analytics/analytics_screen.dart';
import '../../screens/gamification/achievements_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../models/scan_result_model.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.auth,
        builder: (_, __) => const AuthScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.diary,
            builder: (_, __) => const DiaryScreen(),
          ),
          GoRoute(
            path: AppRoutes.coach,
            builder: (_, __) => const CoachScreen(),
          ),
          GoRoute(
            path: AppRoutes.analytics,
            builder: (_, __) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.scanner,
        builder: (_, __) => const ScannerScreen(),
      ),
      GoRoute(
        path: AppRoutes.scanResult,
        builder: (context, state) {
          final result = state.extra as ScanResultModel;
          return ScanResultScreen(result: result);
        },
      ),
      GoRoute(
        path: AppRoutes.weight,
        builder: (_, __) => const WeightScreen(),
      ),
      GoRoute(
        path: AppRoutes.water,
        builder: (_, __) => const WaterScreen(),
      ),
      GoRoute(
        path: AppRoutes.achievements,
        builder: (_, __) => const AchievementsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
});

class AppRoutes {
  AppRoutes._();
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String auth = '/auth';
  static const String home = '/home';
  static const String diary = '/diary';
  static const String coach = '/coach';
  static const String analytics = '/analytics';
  static const String profile = '/profile';
  static const String scanner = '/scanner';
  static const String scanResult = '/scan-result';
  static const String weight = '/weight';
  static const String water = '/water';
  static const String achievements = '/achievements';
}
