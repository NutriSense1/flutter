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
import '../../widgets/common/ns_button.dart';
import '../../widgets/common/ns_text_field.dart';

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

  // ── Form state ──────────────────────────────────────────────────────────────
  int _tab = 0; // 0 = sign in, 1 = sign up
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
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
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  // ── Routing ─────────────────────────────────────────────────────────────────
  Future<void> _routeAfterAuth() async {
    final api = ref.read(apiServiceProvider);
    try {
      final profile = await api.getProfile();
      ref.read(userProvider.notifier).setUser(profile);
      if (!mounted) return;
      context.go(AppRoutes.home);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        if (!mounted) return;
        context.go(AppRoutes.onboarding);
      } else {
        setState(() => _error = e.message);
      }
    }
  }

  Future<void> _signIn() async {
    if (_emailCtrl.text.trim().isEmpty || _passwordCtrl.text.isEmpty) {
      setState(() => _error = 'Enter your email and password.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authServiceProvider).signInWithEmail(
          _emailCtrl.text.trim(), _passwordCtrl.text);
      await _routeAfterAuth();
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signUp() async {
    if (_nameCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty ||
        _passwordCtrl.text.length < 6) {
      setState(() => _error = 'Fill all fields (password min. 6 chars).');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authServiceProvider).signUpWithEmail(
          _emailCtrl.text.trim(), _passwordCtrl.text);
      if (!mounted) return;
      context.go(AppRoutes.onboarding);
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInGoogle() async {
    setState(() { _loading = true; _error = null; });
    try {
      final user = await ref.read(authServiceProvider).signInWithGoogle();
      if (user == null) { setState(() => _loading = false); return; }
      await _routeAfterAuth();
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Enter your email first, then tap "Forgot password?"');
      return;
    }
    try {
      await ref.read(authServiceProvider)
          .sendPasswordResetEmail(_emailCtrl.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Reset link sent to ${_emailCtrl.text.trim()}')));
    } on AuthException catch (e) {
      setState(() => _error = e.message);
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
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF34D47A), Color(0xFF0F9D58)],
                            ),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.5),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.restaurant_menu_rounded,
                              color: Colors.white, size: 38),
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

          // ── White form card (slides up) ───────────────────────────────────
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
                        const SizedBox(height: 24),

                        // Heading
                        Text(
                          _tab == 0 ? 'Welcome back' : 'Create account',
                          style: AppTypography.displayMedium.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.0,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _tab == 0
                              ? 'Your nutrition journey continues here.'
                              : 'Start understanding your food today.',
                          style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 24),

                        // ── Tab selector ─────────────────────────────────
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              _PillTab(
                                  label: 'Sign In',
                                  active: _tab == 0,
                                  onTap: () => setState(
                                      () { _tab = 0; _error = null; })),
                              _PillTab(
                                  label: 'Sign Up',
                                  active: _tab == 1,
                                  onTap: () => setState(
                                      () { _tab = 1; _error = null; })),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Error banner ──────────────────────────────────
                        if (_error != null)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(bottom: 16),
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

                        // ── Animated form switcher ────────────────────────
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                      begin: const Offset(0.04, 0),
                                      end: Offset.zero)
                                  .animate(CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeOutCubic)),
                              child: child,
                            ),
                          ),
                          child: _tab == 0
                              ? _SignInForm(
                                  key: const ValueKey('signin'),
                                  emailCtrl: _emailCtrl,
                                  passwordCtrl: _passwordCtrl,
                                  obscure: _obscure,
                                  onToggleObscure: () =>
                                      setState(() => _obscure = !_obscure),
                                  loading: _loading,
                                  onSubmit: _signIn,
                                  onForgot: _forgotPassword,
                                )
                              : _SignUpForm(
                                  key: const ValueKey('signup'),
                                  nameCtrl: _nameCtrl,
                                  emailCtrl: _emailCtrl,
                                  passwordCtrl: _passwordCtrl,
                                  obscure: _obscure,
                                  onToggleObscure: () =>
                                      setState(() => _obscure = !_obscure),
                                  loading: _loading,
                                  onSubmit: _signUp,
                                ),
                        ),

                        const SizedBox(height: 24),

                        // ── Divider ───────────────────────────────────────
                        Row(
                          children: [
                            const Expanded(
                                child: Divider(color: AppColors.divider)),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text('or',
                                  style: AppTypography.bodySmall
                                      .copyWith(color: AppColors.textHint)),
                            ),
                            const Expanded(
                                child: Divider(color: AppColors.divider)),
                          ],
                        ),

                        const SizedBox(height: 20),

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
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Google "G" logo via coloured text
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

// ─── Pill tab ──────────────────────────────────────────────────────────────────

class _PillTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _PillTab(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedTap(
        onTap: onTap,
        haptic: false,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 14,
                fontWeight:
                    active ? FontWeight.w600 : FontWeight.w400,
                color: active
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
              child: Text(label),
            ),
          ),
        ),
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

// ─── Sign-In Form ──────────────────────────────────────────────────────────────

class _SignInForm extends StatelessWidget {
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final bool loading;
  final VoidCallback onSubmit;
  final VoidCallback onForgot;

  const _SignInForm({
    super.key,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.obscure,
    required this.onToggleObscure,
    required this.loading,
    required this.onSubmit,
    required this.onForgot,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NsTextField(
          controller: emailCtrl,
          label: 'Email',
          hint: 'you@example.com',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email_outlined,
        ),
        const SizedBox(height: 14),
        NsTextField(
          controller: passwordCtrl,
          label: 'Password',
          hint: '••••••••',
          obscureText: obscure,
          prefixIcon: Icons.lock_outline,
          suffixIcon: obscure
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          onSuffixTap: onToggleObscure,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: loading ? null : onForgot,
            style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                padding: const EdgeInsets.symmetric(
                    horizontal: 4, vertical: 8)),
            child: const Text('Forgot password?',
                style: TextStyle(fontSize: 13)),
          ),
        ),
        const SizedBox(height: 8),
        NsButton(
            label: 'Sign In', loading: loading, onPressed: onSubmit),
      ],
    );
  }
}

// ─── Sign-Up Form ──────────────────────────────────────────────────────────────

class _SignUpForm extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final bool loading;
  final VoidCallback onSubmit;

  const _SignUpForm({
    super.key,
    required this.nameCtrl,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.obscure,
    required this.onToggleObscure,
    required this.loading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        NsTextField(
          controller: nameCtrl,
          label: 'Full Name',
          hint: 'Jane Doe',
          prefixIcon: Icons.person_outline,
        ),
        const SizedBox(height: 14),
        NsTextField(
          controller: emailCtrl,
          label: 'Email',
          hint: 'you@example.com',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email_outlined,
        ),
        const SizedBox(height: 14),
        NsTextField(
          controller: passwordCtrl,
          label: 'Password',
          hint: '6+ characters',
          obscureText: obscure,
          prefixIcon: Icons.lock_outline,
          suffixIcon: obscure
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          onSuffixTap: onToggleObscure,
        ),
        const SizedBox(height: 24),
        NsButton(
            label: 'Create Account', loading: loading, onPressed: onSubmit),
      ],
    );
  }
}
