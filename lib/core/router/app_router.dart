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
import '../../screens/settings/personal_details_screen.dart';
import '../../screens/settings/goals_targets_screen.dart';
import '../../screens/settings/dietary_preferences_screen.dart';
import '../../screens/settings/notifications_screen.dart';
import '../../screens/settings/appearance_screen.dart';
import '../../screens/settings/privacy_security_screen.dart';
import '../../screens/settings/help_support_screen.dart';
import '../../models/scan_result_model.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (c, s) => _fade(s.pageKey, const SplashScreen()),
      ),
      GoRoute(
        path: AppRoutes.auth,
        pageBuilder: (c, s) => _fade(s.pageKey, const AuthScreen()),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (c, s) => _slideFade(s.pageKey, const OnboardingScreen()),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (c, s) =>
                NoTransitionPage(key: s.pageKey, child: const HomeScreen()),
          ),
          GoRoute(
            path: AppRoutes.diary,
            pageBuilder: (c, s) =>
                NoTransitionPage(key: s.pageKey, child: const DiaryScreen()),
          ),
          GoRoute(
            path: AppRoutes.coach,
            pageBuilder: (c, s) =>
                NoTransitionPage(key: s.pageKey, child: const CoachScreen()),
          ),
          GoRoute(
            path: AppRoutes.analytics,
            pageBuilder: (c, s) =>
                NoTransitionPage(key: s.pageKey, child: const AnalyticsScreen()),
          ),
          GoRoute(
            path: AppRoutes.profile,
            pageBuilder: (c, s) =>
                NoTransitionPage(key: s.pageKey, child: const ProfileScreen()),
          ),
        ],
      ),
      // Modal-style routes slide up from bottom
      GoRoute(
        path: AppRoutes.scanner,
        pageBuilder: (c, s) => _slideUp(s.pageKey, const ScannerScreen()),
      ),
      GoRoute(
        path: AppRoutes.scanResult,
        pageBuilder: (c, s) {
          final result = s.extra as ScanResultModel;
          return _slideUp(s.pageKey, ScanResultScreen(result: result));
        },
      ),
      GoRoute(
        path: AppRoutes.weight,
        pageBuilder: (c, s) => _slideUp(s.pageKey, const WeightScreen()),
      ),
      GoRoute(
        path: AppRoutes.water,
        pageBuilder: (c, s) => _slideUp(s.pageKey, const WaterScreen()),
      ),
      GoRoute(
        path: AppRoutes.achievements,
        pageBuilder: (c, s) => _slideUp(s.pageKey, const AchievementsScreen()),
      ),
      GoRoute(
        path: AppRoutes.personalDetails,
        pageBuilder: (c, s) => _slideUp(s.pageKey, const PersonalDetailsScreen()),
      ),
      GoRoute(
        path: AppRoutes.goalsTargets,
        pageBuilder: (c, s) => _slideUp(s.pageKey, const GoalsTargetsScreen()),
      ),
      GoRoute(
        path: AppRoutes.dietaryPreferences,
        pageBuilder: (c, s) => _slideUp(s.pageKey, const DietaryPreferencesScreen()),
      ),
      GoRoute(
        path: AppRoutes.notificationSettings,
        pageBuilder: (c, s) => _slideUp(s.pageKey, const NotificationsScreen()),
      ),
      GoRoute(
        path: AppRoutes.appearance,
        pageBuilder: (c, s) => _slideUp(s.pageKey, const AppearanceScreen()),
      ),
      GoRoute(
        path: AppRoutes.privacySecurity,
        pageBuilder: (c, s) => _slideUp(s.pageKey, const PrivacySecurityScreen()),
      ),
      GoRoute(
        path: AppRoutes.helpSupport,
        pageBuilder: (c, s) => _slideUp(s.pageKey, const HelpSupportScreen()),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
});

// ─── Transition Factories ─────────────────────────────────────────────────────

/// Clean cross-fade — used for auth ↔ splash transitions (no spatial direction).
CustomTransitionPage<void> _fade(LocalKey key, Widget child) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (_, animation, __, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        child: child,
      );
    },
  );
}

/// Fade + gentle upward slide — main forward navigation feel.
CustomTransitionPage<void> _slideFade(LocalKey key, Widget child) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 400),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (_, animation, __, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
        child: SlideTransition(
          position:
              Tween<Offset>(begin: const Offset(0.0, 0.05), end: Offset.zero)
                  .animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Full slide-up from bottom — modal-feel push routes (scanner, water, weight).
CustomTransitionPage<void> _slideUp(LocalKey key, Widget child) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 420),
    reverseTransitionDuration: const Duration(milliseconds: 320),
    transitionsBuilder: (_, animation, __, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
        ),
        child: SlideTransition(
          position:
              Tween<Offset>(begin: const Offset(0.0, 1.0), end: Offset.zero)
                  .animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
          child: child,
        ),
      );
    },
  );
}

// ─── Route Constants ──────────────────────────────────────────────────────────

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
  static const String personalDetails = '/settings/personal-details';
  static const String goalsTargets = '/settings/goals-targets';
  static const String dietaryPreferences = '/settings/dietary-preferences';
  static const String notificationSettings = '/settings/notifications';
  static const String appearance = '/settings/appearance';
  static const String privacySecurity = '/settings/privacy-security';
  static const String helpSupport = '/settings/help-support';
}
