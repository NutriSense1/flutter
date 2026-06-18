import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/router/app_router.dart';
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
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  /// After a successful Firebase sign-in, this app has no way of
  /// knowing yet whether the user already finished onboarding (their
  /// account exists in Firebase, but might not have a row in our
  /// `users` table). We try fetching the profile; a 404 means
  /// "onboarding not done", anything else means we're ready for home.
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
        setState(() => _errorMessage = e.message);
      }
    }
  }

  Future<void> _signIn() async {
    if (_emailCtrl.text.trim().isEmpty || _passwordCtrl.text.isEmpty) {
      setState(() => _errorMessage = 'Enter your email and password.');
      return;
    }
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      await ref.read(authServiceProvider).signInWithEmail(
            _emailCtrl.text.trim(),
            _passwordCtrl.text,
          );
      await _routeAfterAuth();
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signUp() async {
    if (_nameCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty ||
        _passwordCtrl.text.length < 6) {
      setState(() => _errorMessage = 'Fill in all fields (password min. 6 characters).');
      return;
    }
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      await ref.read(authServiceProvider).signUpWithEmail(
            _emailCtrl.text.trim(),
            _passwordCtrl.text,
          );
      // Brand-new Firebase account always needs onboarding next —
      // no backend profile can exist yet.
      if (!mounted) return;
      context.go(AppRoutes.onboarding);
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _continueWithGoogle() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final user = await ref.read(authServiceProvider).signInWithGoogle();
      if (user == null) {
        // User cancelled the Google sign-in sheet
        setState(() => _loading = false);
        return;
      }
      await _routeAfterAuth();
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Enter your email above first, then tap "Forgot password?"');
      return;
    }
    try {
      await ref.read(authServiceProvider).sendPasswordResetEmail(_emailCtrl.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset email sent to ${_emailCtrl.text.trim()}')),
      );
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.restaurant_menu, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Text('NutriSense', style: AppTypography.headlineLarge),
                ],
              ),
              const SizedBox(height: 40),
              Text('Welcome back', style: AppTypography.displayMedium),
              const SizedBox(height: 8),
              Text(
                'Your nutrition journey continues here.',
                style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.transparent,
                  dividerColor: Colors.transparent,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: AppTypography.titleMedium,
                  onTap: (_) => setState(() => _errorMessage = null),
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  tabs: const [
                    Tab(text: 'Sign In'),
                    Tab(text: 'Sign Up'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.error.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_errorMessage!,
                            style: AppTypography.bodySmall.copyWith(color: AppColors.error)),
                      ),
                    ],
                  ),
                ),
              SizedBox(
                height: 340,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _SignInForm(
                      emailCtrl: _emailCtrl,
                      passwordCtrl: _passwordCtrl,
                      obscure: _obscure,
                      onToggleObscure: () => setState(() => _obscure = !_obscure),
                      loading: _loading,
                      onSubmit: _signIn,
                      onForgotPassword: _forgotPassword,
                    ),
                    _SignUpForm(
                      nameCtrl: _nameCtrl,
                      emailCtrl: _emailCtrl,
                      passwordCtrl: _passwordCtrl,
                      obscure: _obscure,
                      onToggleObscure: () => setState(() => _obscure = !_obscure),
                      loading: _loading,
                      onSubmit: _signUp,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('or', style: AppTypography.bodySmall),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _loading ? null : _continueWithGoogle,
                icon: const Icon(Icons.g_mobiledata_rounded, size: 24),
                label: const Text('Continue with Google'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignInForm extends StatelessWidget {
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final bool loading;
  final VoidCallback onSubmit;
  final VoidCallback onForgotPassword;

  const _SignInForm({
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.obscure,
    required this.onToggleObscure,
    required this.loading,
    required this.onSubmit,
    required this.onForgotPassword,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        NsTextField(
          controller: emailCtrl,
          label: 'Email',
          hint: 'you@example.com',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email_outlined,
        ),
        const SizedBox(height: 16),
        NsTextField(
          controller: passwordCtrl,
          label: 'Password',
          hint: '••••••••',
          obscureText: obscure,
          prefixIcon: Icons.lock_outline,
          suffixIcon: obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          onSuffixTap: onToggleObscure,
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: loading ? null : onForgotPassword,
            child: const Text('Forgot password?'),
          ),
        ),
        const SizedBox(height: 16),
        NsButton(label: 'Sign In', loading: loading, onPressed: onSubmit),
      ],
    );
  }
}

class _SignUpForm extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final bool loading;
  final VoidCallback onSubmit;

  const _SignUpForm({
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
        const SizedBox(height: 16),
        NsTextField(
          controller: emailCtrl,
          label: 'Email',
          hint: 'you@example.com',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email_outlined,
        ),
        const SizedBox(height: 16),
        NsTextField(
          controller: passwordCtrl,
          label: 'Password',
          hint: '6+ characters',
          obscureText: obscure,
          prefixIcon: Icons.lock_outline,
          suffixIcon: obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          onSuffixTap: onToggleObscure,
        ),
        const SizedBox(height: 24),
        NsButton(label: 'Create Account', loading: loading, onPressed: onSubmit),
      ],
    );
  }
}
