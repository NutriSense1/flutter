import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/router/app_router.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  // Guard so we only navigate once even if the provider rebuilds.
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _routeOnce(AppLoadState state) async {
    if (_navigated || !mounted) return;
    _navigated = true;

    // Let the logo animation breathe for at least 1.6 s total.
    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;

    switch (state) {
      case AppLoadState.needsAuth:
        context.go(AppRoutes.auth);
        break;
      case AppLoadState.needsOnboarding:
        context.go(AppRoutes.onboarding);
        break;
      case AppLoadState.ready:
        context.go(AppRoutes.home);
        break;
      case AppLoadState.loading:
        _navigated = false; // still loading — allow retry
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // React to the FutureProvider resolving.
    ref.listen<AsyncValue<AppLoadState>>(appLoadStateProvider, (_, next) {
      next.whenData(_routeOnce);

      // If the provider errored (should not happen with our catch-all, but
      // just in case), redirect to auth so the user isn't stuck.
      if (next.hasError && !_navigated) {
        _navigated = true;
        Future.delayed(const Duration(milliseconds: 1600), () {
          if (mounted) context.go(AppRoutes.auth);
        });
      }
    });

    final loadState = ref.watch(appLoadStateProvider);

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Icon(
                    Icons.restaurant_menu,
                    color: Colors.white,
                    size: 52,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'NutriSense',
                  style: AppTypography.displayLarge.copyWith(
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Understand Your Food. Improve Your Health.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.85),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (loadState.isLoading)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  ),
                if (loadState.hasError)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Could not connect. Check your internet connection.',
                      style:
                          AppTypography.bodySmall.copyWith(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
