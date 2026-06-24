import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/router/app_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/animations/animated_tap.dart';
import '../../core/widgets/animations/fade_slide.dart';
import '../../core/utils/nutrition_calculator.dart';
import '../../models/onboarding_model.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/common/ns_button.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _pageCtrl = PageController();
  int _page = 0;
  final int _total = 11;
  bool _submitting = false;
  String? _submitError;

  // Animated progress bar
  late AnimationController _progressCtrl;
  late Animation<double> _progressAnim;
  double _prevProgress = 0;

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _progressAnim = Tween<double>(begin: 0, end: 1 / _total).animate(
      CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOutCubic));
    _progressCtrl.forward();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _total - 1) {
      _animateProgress(_page + 1);
      HapticFeedback.lightImpact();
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 460),
          curve: Curves.easeOutCubic);
    } else {
      _submit();
    }
  }

  void _back() {
    if (_page > 0) {
      _animateProgress(_page - 1);
      HapticFeedback.lightImpact();
      _pageCtrl.previousPage(
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic);
    }
  }

  void _animateProgress(int toPage) {
    _prevProgress = (_page + 1) / _total;
    _progressCtrl.reset();
    _progressAnim = Tween<double>(
            begin: _prevProgress, end: (toPage + 1) / _total)
        .animate(
            CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOutCubic));
    _progressCtrl.forward();
  }

  Future<void> _submit() async {
    final data = ref.read(onboardingProvider);
    if (!data.isComplete) {
      setState(() => _submitError = _describeMissing(data));
      return;
    }
    setState(() { _submitting = true; _submitError = null; });
    try {
      final api = ref.read(apiServiceProvider);
      final user = await api.completeOnboarding({
        'name': data.name,
        'age': data.age,
        'gender': data.gender,
        'height_cm': data.heightCm,
        'weight_kg': data.weightKg,
        'goal_weight_kg': data.goalWeightKg,
        'activity_level': data.activityLevel,
        'goal': data.primaryGoal,
        'dietary_preferences': data.dietaryPreferences,
        'allergies': data.allergies,
        'water_goal_liters': data.waterGoalLiters,
      });
      ref.read(userProvider.notifier).setUser(user);
      ref.read(onboardingProvider.notifier).reset();
      if (!mounted) return;
      context.go(AppRoutes.home);
    } on ApiTimeoutException {
      setState(() => _submitError =
          "Couldn't reach the server — it may be waking up. Please try again in a few seconds.");
    } on ApiException catch (e) {
      setState(() => _submitError = e.message);
    } catch (_) {
      setState(() => _submitError = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// Points at exactly what's missing instead of a blanket "fill all
  /// fields" — this should basically never fire now that every step
  /// commits a value as soon as it's shown, but it's a much better
  /// fallback than a dead-end message if it ever does.
  String _describeMissing(OnboardingData data) {
    final missing = <String>[];
    if (data.name == null || data.name!.trim().isEmpty) missing.add('name');
    if (data.age == null) missing.add('age');
    if (data.gender == null) missing.add('biological sex');
    if (data.heightCm == null) missing.add('height');
    if (data.weightKg == null) missing.add('weight');
    if (data.goalWeightKg == null) missing.add('goal weight');
    if (data.activityLevel == null) missing.add('activity level');
    if (data.goals.isEmpty) missing.add('at least one goal');
    if (missing.isEmpty) return 'Please complete all steps.';
    return 'Just need ${missing.join(', ')} before we can finish setting up your plan.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      AnimatedOpacity(
                        opacity: _page > 0 ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: AnimatedTap(
                          onTap: _page > 0 ? _back : null,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.arrow_back_ios_new_rounded,
                                size: 18, color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Animated dot progress
                      Row(
                        children: List.generate(_total, (i) {
                          final isActive = i == _page;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutCubic,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: isActive ? 20 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.primary
                                  : (isDark ? AppColors.darkDivider : AppColors.divider),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),
                      const Spacer(),
                      Text(
                        '${_page + 1}/$_total',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Gradient progress bar
                  AnimatedBuilder(
                    animation: _progressAnim,
                    builder: (_, __) => ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Stack(
                        children: [
                          Container(
                              height: 4,
                              color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant),
                          FractionallySizedBox(
                            widthFactor: _progressAnim.value,
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF34D47A),
                                    AppColors.primary,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_submitError != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: AppColors.error, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_submitError!,
                                style: AppTypography.bodySmall
                                    .copyWith(color: AppColors.error)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Page content ──────────────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _WelcomePage(onNext: _next),
                  _NamePage(onNext: _next),
                  _AgePage(onNext: _next),
                  _GenderPage(onNext: _next),
                  _HeightWeightPage(onNext: _next),
                  _ActivityPage(onNext: _next),
                  _GoalPage(onNext: _next),
                  _GoalWeightPage(onNext: _next),
                  _DietaryPage(onNext: _next),
                  _AllergiesPage(onNext: _next),
                  _PlanSummaryPage(onNext: _next, loading: _submitting),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Page Shell ──────────────────────────────────────────────────────────────

class _PageShell extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback onNext;
  final String nextLabel;
  final bool loading;

  const _PageShell({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.onNext,
    this.nextLabel = 'Continue',
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 28),
          FadeSlide(
            delay: const Duration(milliseconds: 60),
            child: Text(emoji, style: const TextStyle(fontSize: 44)),
          ),
          const SizedBox(height: 16),
          FadeSlide(
            delay: const Duration(milliseconds: 130),
            child: Text(title, style: AppTypography.headlineLarge),
          ),
          const SizedBox(height: 8),
          FadeSlide(
            delay: const Duration(milliseconds: 190),
            child: Text(subtitle,
                style: AppTypography.bodyLarge
                    .copyWith(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
          ),
          const SizedBox(height: 28),
          Expanded(
            child: FadeSlide(
              delay: const Duration(milliseconds: 260),
              child: SingleChildScrollView(child: child),
            ),
          ),
          FadeSlide(
            delay: const Duration(milliseconds: 90),
            child: NsButton(
                label: nextLabel, onPressed: onNext, loading: loading),
          ),
        ],
      ),
    );
  }
}

// ─── Selection Card (spring animation on tap) ────────────────────────────────

class _SelectCard extends StatefulWidget {
  final String label;
  final String? subtitle;
  final String? icon;
  final bool selected;
  final VoidCallback onTap;

  const _SelectCard({
    required this.label,
    this.subtitle,
    this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_SelectCard> createState() => _SelectCardState();
}

class _SelectCardState extends State<_SelectCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _springCtrl;
  late Animation<double> _spring;

  @override
  void initState() {
    super.initState();
    _springCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _spring = TweenSequence([
      TweenSequenceItem(
          tween: Tween<double>(begin: 1.0, end: 0.94)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 30),
      TweenSequenceItem(
          tween: Tween<double>(begin: 0.94, end: 1.02)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 40),
      TweenSequenceItem(
          tween: Tween<double>(begin: 1.02, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 30),
    ]).animate(_springCtrl);
  }

  @override
  void didUpdateWidget(_SelectCard old) {
    super.didUpdateWidget(old);
    if (!old.selected && widget.selected) {
      HapticFeedback.lightImpact();
      _springCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _springCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedTap(
      onTap: widget.onTap,
      haptic: false,
      child: ScaleTransition(
        scale: _spring,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: widget.selected
                ? (isDark ? AppColors.primary.withOpacity(0.18) : AppColors.secondary)
                : (isDark ? AppColors.darkSurface : AppColors.surface),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.selected ? AppColors.primary : (isDark ? AppColors.darkDivider : AppColors.divider),
              width: widget.selected ? 2 : 1,
            ),
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Row(
            children: [
              if (widget.icon != null) ...[
                Text(widget.icon!, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.label,
                        style: AppTypography.titleMedium.copyWith(
                          color: widget.selected
                              ? AppColors.primary
                              : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                        )),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(widget.subtitle!,
                          style: AppTypography.bodySmall),
                    ],
                  ],
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: widget.selected
                    ? const Icon(Icons.check_circle_rounded,
                        key: ValueKey('check'),
                        color: AppColors.primary,
                        size: 22)
                    : const SizedBox(key: ValueKey('empty'), width: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.titleMedium),
            RichText(
              text: TextSpan(children: [
                TextSpan(
                    text: value.toStringAsFixed(1),
                    style: AppTypography.headlineMedium
                        .copyWith(color: AppColors.primary)),
                TextSpan(
                    text: ' $unit',
                    style: AppTypography.bodyMedium
                        .copyWith(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
              ]),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withOpacity(0.12),
          ),
          child: Slider(
              value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }
}

// ─── Pages ─────────────────────────────────────────────────────────────────────

class _WelcomePage extends StatelessWidget {
  final VoidCallback onNext;
  const _WelcomePage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 28),
          FadeSlide(
            delay: const Duration(milliseconds: 40),
            child: Container(
              width: 76,
              height: 76,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/logo_icon.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 28),
          FadeSlide(
            delay: const Duration(milliseconds: 100),
            child: Text('Your personal\nnutrition coach\nis here 🥗',
                style: AppTypography.displayLarge),
          ),
          const SizedBox(height: 16),
          FadeSlide(
            delay: const Duration(milliseconds: 160),
            child: Text(
              'Scan food, understand ingredients, track macros, and make smarter choices every day.',
              style: AppTypography.bodyLarge
                  .copyWith(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 32),
          FadeSlide(
            delay: const Duration(milliseconds: 220),
            child: Column(
              children: [
                _FeatureRow(
                    icon: Icons.camera_alt_outlined,
                    label: 'Scan any food instantly'),
                const SizedBox(height: 12),
                _FeatureRow(
                    icon: Icons.psychology_outlined,
                    label: 'AI-powered health insights'),
                const SizedBox(height: 12),
                _FeatureRow(
                    icon: Icons.trending_up_rounded,
                    label: 'Track your progress daily'),
              ],
            ),
          ),
          const Spacer(),
          FadeSlide(
            delay: const Duration(milliseconds: 280),
            child: NsButton(label: "Let's get started", onPressed: onNext),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: isDark ? AppColors.primary.withOpacity(0.15) : AppColors.secondary,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 16),
        Text(label, style: AppTypography.bodyLarge),
      ],
    );
  }
}

class _NamePage extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  const _NamePage({required this.onNext});

  @override
  ConsumerState<_NamePage> createState() => _NamePageState();
}

class _NamePageState extends ConsumerState<_NamePage> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    // Pre-filled from the Google account or the sign-up form's name
    // field when available, so this step usually just needs a confirm.
    _ctrl = TextEditingController(text: ref.read(onboardingProvider).name ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prefilled = _ctrl.text.trim().isNotEmpty;
    return _PageShell(
      emoji: '👋',
      title: "What's your name?",
      subtitle: prefilled
          ? "We grabbed this from your account — edit it if you'd like."
          : "We'll personalise everything just for you.",
      onNext: widget.onNext,
      child: TextField(
        controller: _ctrl,
        autofocus: !prefilled,
        style: AppTypography.headlineMedium,
        decoration: InputDecoration(
          hintText: 'Your name',
          hintStyle: AppTypography.headlineMedium
              .copyWith(color: isDark ? AppColors.darkTextHint : AppColors.textHint),
        ),
        textCapitalization: TextCapitalization.words,
        onChanged: (v) =>
            ref.read(onboardingProvider.notifier).updateName(v),
      ),
    );
  }
}

class _AgePage extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  const _AgePage({required this.onNext});

  @override
  ConsumerState<_AgePage> createState() => _AgePageState();
}

class _AgePageState extends ConsumerState<_AgePage> {
  late int _age;

  @override
  void initState() {
    super.initState();
    _age = ref.read(onboardingProvider).age ?? 25;
    // The slider already shows this value as "chosen" — commit it to
    // the provider even if the user never touches the slider, otherwise
    // age stays null and the final step wrongly says it's incomplete.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(onboardingProvider.notifier).updateAge(_age);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _PageShell(
      emoji: '🎂',
      title: 'How old are you?',
      subtitle: 'Helps us calculate accurate calorie targets.',
      onNext: widget.onNext,
      child: Column(
        children: [
          Text('$_age',
              style: AppTypography.numericLarge
                  .copyWith(color: AppColors.primary, fontSize: 56)),
          const SizedBox(height: 4),
          Text('years old',
              style: AppTypography.bodyMedium
                  .copyWith(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
          const SizedBox(height: 28),
          _SliderRow(
            label: 'Age',
            value: _age.toDouble(),
            unit: 'yrs',
            min: 13,
            max: 90,
            onChanged: (v) {
              setState(() => _age = v.round());
              ref.read(onboardingProvider.notifier).updateAge(v.round());
            },
          ),
        ],
      ),
    );
  }
}

class _GenderPage extends ConsumerWidget {
  final VoidCallback onNext;
  const _GenderPage({required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(onboardingProvider).gender;
    return _PageShell(
      emoji: '🧬',
      title: 'Your biological sex?',
      subtitle: 'Used for precise BMR and calorie calculations.',
      onNext: onNext,
      child: Column(
        children: [
          _SelectCard(
            label: 'Male',
            icon: '♂️',
            selected: selected == 'Male',
            onTap: () =>
                ref.read(onboardingProvider.notifier).updateGender('Male'),
          ),
          const SizedBox(height: 12),
          _SelectCard(
            label: 'Female',
            icon: '♀️',
            selected: selected == 'Female',
            onTap: () =>
                ref.read(onboardingProvider.notifier).updateGender('Female'),
          ),
        ],
      ),
    );
  }
}

class _HeightWeightPage extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  const _HeightWeightPage({required this.onNext});

  @override
  ConsumerState<_HeightWeightPage> createState() => _HWState();
}

class _HWState extends ConsumerState<_HeightWeightPage> {
  double _h = 170, _w = 70;

  @override
  void initState() {
    super.initState();
    final d = ref.read(onboardingProvider);
    _h = d.heightCm ?? 170;
    _w = d.weightKg ?? 70;
    // Same fix as age: commit the slider's starting values even if the
    // user accepts the defaults without dragging either slider.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(onboardingProvider.notifier)
        ..updateHeight(_h)
        ..updateWeight(_w);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _PageShell(
      emoji: '📏',
      title: 'Height & Weight',
      subtitle: 'Used to calculate your BMI and calorie needs.',
      onNext: widget.onNext,
      child: Column(
        children: [
          _SliderRow(
            label: 'Height',
            value: _h,
            unit: 'cm',
            min: 100,
            max: 230,
            onChanged: (v) {
              setState(() => _h = v);
              ref.read(onboardingProvider.notifier).updateHeight(v);
            },
          ),
          const SizedBox(height: 24),
          _SliderRow(
            label: 'Weight',
            value: _w,
            unit: 'kg',
            min: 30,
            max: 200,
            onChanged: (v) {
              setState(() => _w = v);
              ref.read(onboardingProvider.notifier).updateWeight(v);
            },
          ),
        ],
      ),
    );
  }
}

class _ActivityPage extends ConsumerWidget {
  final VoidCallback onNext;
  const _ActivityPage({required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(onboardingProvider).activityLevel;
    final descs = {
      'Sedentary': 'Little or no exercise, desk job',
      'Lightly Active': '1–3 days/week light exercise',
      'Moderately Active': '3–5 days/week moderate exercise',
      'Very Active': '6–7 days/week hard exercise',
      'Extremely Active': 'Twice daily, very intense workouts',
    };
    return _PageShell(
      emoji: '🏃',
      title: 'Activity Level',
      subtitle: 'How active are you on a typical week?',
      onNext: onNext,
      child: Column(
        children: AppConstants.activityLevels.map((lvl) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SelectCard(
              label: lvl,
              subtitle: descs[lvl],
              selected: selected == lvl,
              onTap: () => ref
                  .read(onboardingProvider.notifier)
                  .updateActivityLevel(lvl),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _GoalPage extends ConsumerWidget {
  final VoidCallback onNext;
  const _GoalPage({required this.onNext});

  static const _maxGoals = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(onboardingProvider).goals;
    final icons = {
      'Lose Weight': '🔥', 'Maintain Weight': '⚖️', 'Gain Weight': '📈',
      'Build Muscle': '💪', 'Improve Health': '❤️', 'Eat Healthier': '🥗',
    };
    return _PageShell(
      emoji: '🎯',
      title: "What's your goal?",
      subtitle: selected.isEmpty
          ? 'Select up to $_maxGoals — your first pick sets your calorie target.'
          : '${selected.length}/$_maxGoals selected — "${selected.first}" sets your calorie target.',
      onNext: onNext,
      child: Column(
        children: AppConstants.goals.map((g) {
          final isOn = selected.contains(g);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SelectCard(
              label: g,
              icon: icons[g],
              selected: isOn,
              onTap: () {
                if (!isOn && selected.length >= _maxGoals) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('You can select up to $_maxGoals goals.'),
                    duration: const Duration(milliseconds: 1500),
                  ));
                  return;
                }
                ref.read(onboardingProvider.notifier).toggleGoal(g);
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _GoalWeightPage extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  const _GoalWeightPage({required this.onNext});

  @override
  ConsumerState<_GoalWeightPage> createState() => _GWState();
}

class _GWState extends ConsumerState<_GoalWeightPage> {
  double _gw = 65;

  @override
  void initState() {
    super.initState();
    _gw = ref.read(onboardingProvider).goalWeightKg ??
        ref.read(onboardingProvider).weightKg ?? 65;
    // Same fix as age/height/weight: commit the default so accepting it
    // without touching the slider still counts as answered.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(onboardingProvider.notifier).updateGoalWeight(_gw);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _PageShell(
      emoji: '🏁',
      title: 'Goal Weight',
      subtitle: "What's your target weight?",
      onNext: widget.onNext,
      child: _SliderRow(
        label: 'Goal Weight',
        value: _gw,
        unit: 'kg',
        min: 30,
        max: 200,
        onChanged: (v) {
          setState(() => _gw = v);
          ref.read(onboardingProvider.notifier).updateGoalWeight(v);
        },
      ),
    );
  }
}

class _DietaryPage extends ConsumerWidget {
  final VoidCallback onNext;
  const _DietaryPage({required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(onboardingProvider).dietaryPreferences;
    return _PageShell(
      emoji: '🥦',
      title: 'Dietary Preferences',
      subtitle: 'Select all that apply.',
      onNext: onNext,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: AppConstants.dietaryPreferences.map((p) {
          final on = selected.contains(p);
          return AnimatedTap(
            onTap: () => ref
                .read(onboardingProvider.notifier)
                .toggleDietaryPreference(p),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: on
                ? (isDark ? AppColors.primary.withOpacity(0.15) : AppColors.secondary)
                : (isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: on ? AppColors.primary : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Text(
                p,
                style: AppTypography.labelMedium.copyWith(
                    color: on
                        ? AppColors.primary
                        : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _AllergiesPage extends ConsumerWidget {
  final VoidCallback onNext;
  const _AllergiesPage({required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(onboardingProvider).allergies;
    return _PageShell(
      emoji: '⚠️',
      title: 'Any allergies?',
      subtitle: "We'll warn you when allergens are detected.",
      onNext: onNext,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: AppConstants.allergens.map((a) {
          final on = selected.contains(a);
          return AnimatedTap(
            onTap: () =>
                ref.read(onboardingProvider.notifier).toggleAllergen(a),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: on
                    ? const Color(0xFFFFE4E4)
                    : (isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color:
                      on ? AppColors.error : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Text(
                a,
                style: AppTypography.labelMedium.copyWith(
                    color: on ? AppColors.error : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Plan Summary (final step) ───────────────────────────────────────────────
//
// Closes out onboarding by actually showing the person what all those
// questions were for — their computed calorie/macro targets — instead of
// just submitting silently. This is also where the real submission happens
// ("Start Tracking" calls onNext, which is the last page so _next() routes
// straight into _submit()).
//
// IMPORTANT: PageView(children: [...]) builds every page eagerly, so this
// widget's build() runs once as soon as onboarding opens — long before the
// user has filled anything in. Every value below falls back to a sane
// default rather than null-asserting, or this page would crash onboarding
// on load.
class _PlanSummaryPage extends ConsumerWidget {
  final VoidCallback onNext;
  final bool loading;
  const _PlanSummaryPage({required this.onNext, this.loading = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(onboardingProvider);

    final double weight = data.weightKg ?? 70.0;
    final double height = data.heightCm ?? 170.0;
    final int age = data.age ?? 25;
    final gender = data.gender ?? 'Male';
    final activity = data.activityLevel ?? 'Sedentary';
    final goal = data.primaryGoal ?? 'Maintain Weight';
    final double goalWeight = data.goalWeightKg ?? weight;
    final firstName = (data.name ?? '').trim().split(' ').first;

    final bmr = NutritionCalculator.calculateBMR(
        weightKg: weight, heightCm: height, age: age, gender: gender);
    final tdee = NutritionCalculator.calculateTDEE(bmr, activity);
    final calories = NutritionCalculator.calculateDailyCalories(tdee, goal);
    final protein = NutritionCalculator.calculateProteinTarget(weight, goal);
    final macros = NutritionCalculator.calculateMacroCalories(
        totalCalories: calories, proteinG: protein);
    final carbs = NutritionCalculator.carbsFromCalories(macros['carbs']!);
    final fat = NutritionCalculator.fatFromCalories(macros['fat']!);
    final weeks =
        NutritionCalculator.estimateWeeksToGoal(weight, goalWeight);

    final hasRealGoalGap =
        goal != 'Maintain Weight' && (goalWeight - weight).abs() >= 0.5;

    return _PageShell(
      emoji: '✨',
      title: firstName.isNotEmpty
          ? '$firstName, your plan is ready'
          : 'Your plan is ready',
      subtitle: hasRealGoalGap
          ? "Built from your stats — at a safe ~0.5 kg/week pace, you'll reach ${goalWeight.toStringAsFixed(0)} kg in about $weeks weeks."
          : "Built from your stats and activity level — here's what we recommend daily.",
      onNext: onNext,
      nextLabel: 'Start Tracking',
      loading: loading,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 26),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF34D47A), Color(0xFF0F9D58)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Text('${calories.round()}',
                    style: AppTypography.numericLarge
                        .copyWith(color: Colors.white, fontSize: 48)),
                const SizedBox(height: 4),
                Text('calories / day',
                    style: AppTypography.bodyMedium
                        .copyWith(color: Colors.white.withOpacity(0.85))),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MacroStatCard(
                    label: 'Protein', grams: protein, color: AppColors.protein),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MacroStatCard(
                    label: 'Carbs', grams: carbs, color: AppColors.carbs),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MacroStatCard(
                    label: 'Fat', grams: fat, color: AppColors.fat),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 18, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'These targets adjust automatically as you log meals and track progress — nothing here is locked in.',
                    style: AppTypography.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroStatCard extends StatelessWidget {
  final String label;
  final double grams;
  final Color color;
  const _MacroStatCard({
    required this.label,
    required this.grams,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
      ),
      child: Column(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(height: 8),
          Text('${grams.round()}g', style: AppTypography.titleLarge),
          const SizedBox(height: 2),
          Text(label, style: AppTypography.labelSmall),
        ],
      ),
    );
  }
}
