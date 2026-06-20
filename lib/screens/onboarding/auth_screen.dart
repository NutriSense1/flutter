import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/router/app_router.dart';
import '../../core/widgets/animations/animated_tap.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

/// Google Sign-In is the ONLY auth method in this app — there is no
/// email/password form here by design (see AuthService).
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with TickerProviderStateMixin {
  // ── Entry animations ────────────────────────────────────────────────────────
  late AnimationController _entryCtrl;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late Animation<Offset> _cardSlide;
  late Animation<double> _cardFade;

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 650));

    _headerFade = CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut));
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.08), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _entryCtrl,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic)));

    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _entryCtrl,
            curve: const Interval(0.15, 1.0, curve: Curves.easeOutCubic)));
    _cardFade = CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.1, 0.7, curve: Curves.easeOut));

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  // ── Routing ─────────────────────────────────────────────────────────────────
  //
  // After a successful Google sign-in we still need to ask the backend
  // whether this person has a profile yet (GET /users/me). Two things used
  // to go wrong here:
  //   1. That request had no timeout, so a sleeping free-tier backend could
  //      hang indefinitely with the button just spinning forever.
  //   2. Only `ApiException` was caught — any other error (timeout, DNS,
  //      socket) fell through uncaught, silently resetting `_loading` with
  //      no message and no navigation. From the outside that looked exactly
  //      like "the Google account got linked but nothing happens".
  //
  // Fix: every ApiService call now times out instead of hanging (see
  // ApiService), and we retry once here on a timeout (covers a cold-start
  // wake-up, which can take up to ~60s on Render's free tier) before
  // showing a clear, actionable message.
  Future<void> _routeAfterAuth({bool isRetry = false}) async {
    final api = ref.read(apiServiceProvider);
    try {
      final profile = await api.getProfile();
      ref.read(userProvider.notifier).setUser(profile);
      if (!mounted) return;
      context.go(AppRoutes.home);
    } on ApiTimeoutException {
      if (!isRetry) {
        await _routeAfterAuth(isRetry: true);
        return;
      }
      if (!mounted) return;
      setState(() => _error =
          "Couldn't reach the server — it may be waking up. Please try again in a few seconds.");
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        // No backend profile yet → first time through onboarding.
        // Carry over the Google display name so onboarding's name step
        // opens pre-filled instead of asking again from scratch.
        final knownName = ref.read(authServiceProvider).currentUser?.displayName;
        if (knownName != null && knownName.trim().isNotEmpty) {
          ref.read(onboardingProvider.notifier).updateName(knownName.trim());
        }
        if (!mounted) return;
        context.go(AppRoutes.onboarding);
      } else {
        if (!mounted) return;
        setState(() => _error = e.message);
      }
    } catch (_) {
      // Catch-all so an unexpected error never leaves the screen stuck
      // with no feedback — always either navigate or show a message.
      if (!mounted) return;
      setState(() => _error = 'Something went wrong. Please try again.');
    }
  }

  Future<void> _signInGoogle() async {
    setState(() { _loading = true; _error = null; });
    try {
      final user = await ref.read(authServiceProvider).signInWithGoogle();
      if (user == null) { setState(() => _loading = false); return; } // cancelled
      await _routeAfterAuth();
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final headerHeight = size.height * 0.40;

    return Scaffold(
      backgroundColor: const Color(0xFF030E06),
      body: Stack(
        children: [
          // ── Background gradient ──────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF030E06), Color(0xFF0C3018)],
              ),
            ),
          ),

          // ── Header: logo + brand ─────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: headerHeight,
            child: FadeTransition(
              opacity: _headerFade,
              child: SlideTransition(
                position: _headerSlide,
                child: SafeArea(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.5),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/logo_icon.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'NutriSense',
                          style: AppTypography.headlineLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 28,
                            letterSpacing: -1.0,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Know what you eat.',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.45),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── White card (slides up) ────────────────────────────────────────
          Positioned(
            top: headerHeight - 16,
            left: 0,
            right: 0,
            bottom: 0,
            child: FadeTransition(
              opacity: _cardFade,
              child: SlideTransition(
                position: _cardSlide,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: SingleChildScrollView(
                    padding:
                        const EdgeInsets.fromLTRB(28, 28, 28, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Drag handle
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.divider,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Heading
                        Text(
                          'Welcome',
                          style: AppTypography.displayMedium.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.0,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Sign in with Google to start understanding your food.',
                          style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 32),

                        // ── Error banner ──────────────────────────────────
                        if (_error != null)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(bottom: 20),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: AppColors.error.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded,
                                    color: AppColors.error, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(_error!,
                                      style: AppTypography.bodySmall
                                          .copyWith(color: AppColors.error)),
                                ),
                              ],
                            ),
                          ),

                        // ── Google button ──────────────────────────────────
                        AnimatedTap(
                          onTap: _loading ? null : _signInGoogle,
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: AppColors.divider, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: _loading
                                ? const Center(
                                    child: SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2.4),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const _GoogleG(),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Continue with Google',
                                        style: AppTypography.labelLarge.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),

                        const SizedBox(height: 20),
                        Text(
                          'By continuing, you agree to our Terms of Service '
                          'and Privacy Policy.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textHint, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Google G logo ─────────────────────────────────────────────────────────────

class _GoogleG extends StatelessWidget {
  const _GoogleG();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // Segments: blue, red, yellow, green
    const segments = [
      (start: -22.5, sweep: 95.0,  color: Color(0xFF4285F4)), // blue
      (start: 72.5,  sweep: 95.0,  color: Color(0xFF34A853)), // green
      (start: 167.5, sweep: 95.0,  color: Color(0xFFFBBC05)), // yellow
      (start: 262.5, sweep: 95.0,  color: Color(0xFFEA4335)), // red
    ];

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.18
      ..strokeCap = StrokeCap.butt;

    const deg = 3.14159265358979 / 180;
    for (final s in segments) {
      paint.color = s.color;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r * 0.72),
        s.start * deg,
        s.sweep * deg,
        false,
        paint,
      );
    }

    // White "cutout" crossbar (right side of G)
    final barPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = size.width * 0.18;
    canvas.drawLine(
      Offset(c.dx, c.dy),
      Offset(c.dx + r * 0.68, c.dy),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
