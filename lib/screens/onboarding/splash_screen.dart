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
    with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late AnimationController _textCtrl;
  late AnimationController _glowCtrl;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _glowPulse;
  late Animation<double> _glowOpacity;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    // Logo: elastic spring scale-in
    _logoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 950));
    _logoScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _logoCtrl,
          curve: const Interval(0.0, 0.35, curve: Curves.easeOut)),
    );

    // Text: fade + slide up, staggered after logo
    _textCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    _textOpacity =
        CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut);
    _textSlide =
        Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
            .animate(
                CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));

    // Glow ring: infinite soft pulse
    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _glowPulse = Tween<double>(begin: 1.0, end: 1.28).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );
    _glowOpacity = Tween<double>(begin: 0.14, end: 0.07).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 420));
    if (!mounted) return;
    _textCtrl.forward();
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  Future<void> _routeOnce(AppLoadState state) async {
    if (_navigated || !mounted) return;
    _navigated = true;
    // Keep on screen for a minimum duration so the animation fully plays
    await Future.delayed(const Duration(milliseconds: 600));
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
        _navigated = false;
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AppLoadState>>(appLoadStateProvider, (_, next) {
      next.whenData(_routeOnce);
      if (next.hasError && !_navigated) {
        _navigated = true;
        Future.delayed(const Duration(milliseconds: 900),
            () { if (mounted) context.go(AppRoutes.auth); });
      }
    });

    ref.watch(appLoadStateProvider); // ensure provider is active

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 1.0],
            colors: [Color(0xFF030E06), Color(0xFF0C3018)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Logo with pulsing glow ──────────────────────────────────
                FadeTransition(
                  opacity: _logoOpacity,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer pulsing halo
                        AnimatedBuilder(
                          animation: _glowCtrl,
                          builder: (_, __) => Transform.scale(
                            scale: _glowPulse.value,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary
                                    .withOpacity(_glowOpacity.value),
                              ),
                            ),
                          ),
                        ),
                        // Mid ring
                        Container(
                          width: 94,
                          height: 94,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withOpacity(0.15),
                          ),
                        ),
                        // Logo tile
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF34D47A),
                                Color(0xFF0F9D58),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.55),
                                blurRadius: 28,
                                spreadRadius: 2,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.restaurant_menu_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ── Brand text ────────────────────────────────────────────
                SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _textOpacity,
                    child: Column(
                      children: [
                        Text(
                          'NutriSense',
                          style: AppTypography.displayLarge.copyWith(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.8,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'AI · NUTRITION · COACH',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 3.0,
                            color: Colors.white.withOpacity(0.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 72),

                // ── Loading dot ───────────────────────────────────────────
                FadeTransition(
                  opacity: _textOpacity,
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.8,
                      color: Colors.white.withOpacity(0.25),
                    ),
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
