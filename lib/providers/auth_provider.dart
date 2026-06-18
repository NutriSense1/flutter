import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'user_provider.dart';

/// Singleton service instances, shared across the whole app.
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(authService: ref.watch(authServiceProvider));
});

/// Emits the current Firebase user whenever sign-in state changes.
/// The router listens to this to decide whether to show auth or home.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// True once we've checked Firebase AND confirmed (via GET /users/me)
/// that the signed-in user has completed onboarding. Drives splash
/// screen routing decisions.
enum AppLoadState { loading, needsAuth, needsOnboarding, ready }

final appLoadStateProvider = FutureProvider<AppLoadState>((ref) async {
  final auth = ref.watch(authServiceProvider);
  final user = auth.currentUser;

  // No Firebase session → go straight to auth screen.
  if (user == null) return AppLoadState.needsAuth;

  try {
    final api = ref.watch(apiServiceProvider);
    final profile = await api.getProfile();
    ref.read(userProvider.notifier).setUser(profile);
    return AppLoadState.ready;
  } on ApiException catch (e) {
    // 404 → Firebase account exists but backend profile was never created.
    if (e.statusCode == 404) return AppLoadState.needsOnboarding;
    // Any other API error (5xx, network, placeholder URL, etc.) — the user
    // is signed in to Firebase but we can't reach the backend right now.
    // Send them to onboarding so they aren't stuck on a blank splash screen.
    // They can always complete onboarding again or reach home once the
    // backend is reachable.
    return AppLoadState.needsOnboarding;
  } catch (_) {
    // Catch-all: network failure, timeout, etc. — don't leave app stuck.
    return AppLoadState.needsAuth;
  }
});
