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
  final int _total = 10;
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
          duration: const Duration(milliseconds: 380),
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
      setState(() => _submitError = 'Please complete all steps.');
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
        'goal': data.goal,
        'dietary_preferences': data.dietaryPreferences,
        'allergies': data.allergies,
        'water_goal_liters': data.waterGoalLiters,
      });
      ref.read(userProvider.notifier).setUser(user);
      ref.read(onboardingProvider.notifier).reset();
      if (!mounted) return;
      context.go(AppRoutes.home);
    } on ApiException catch (e) {
      setState(() => _submitError = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new_rounded,
                                size: 18, color: AppColors.textPrimary),
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
                                  : AppColors.divider,
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
                              color: AppColors.surfaceVariant),
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
                  _AllergiesPage(onNext: _next, loading: _submitting),
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
            delay: const Duration(milliseconds: 40),
            child: Text(emoji, style: const TextStyle(fontSize: 44)),
          ),
          const SizedBox(height: 16),
          FadeSlide(
            delay: const Duration(milliseconds: 100),
            child: Text(title, style: AppTypography.headlineLarge),
          ),
          const SizedBox(height: 8),
          FadeSlide(
            delay: const Duration(milliseconds: 140),
            child: Text(subtitle,
                style: AppTypography.bodyLarge
                    .copyWith(color: AppColors.textSecondary)),
          ),
          const SizedBox(height: 28),
          Expanded(
            child: FadeSlide(
              delay: const Duration(milliseconds: 200),
              child: SingleChildScrollView(child: child),
            ),
          ),
          FadeSlide(
            delay: const Duration(milliseconds: 60),
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
            color: widget.selected ? AppColors.secondary : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.selected ? AppColors.primary : AppColors.divider,
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
                              : AppColors.textPrimary,
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
                        .copyWith(color: AppColors.textSecondary)),
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
            inactiveTrackColor: AppColors.surfaceVariant,
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
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF34D47A), Color(0xFF0F9D58)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.restaurant_menu_rounded,
                  color: Colors.white, size: 40),
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
                  .copyWith(color: AppColors.textSecondary),
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
            color: AppColors.secondary,
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

class _NamePage extends ConsumerWidget {
  final VoidCallback onNext;
  const _NamePage({required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl =
        TextEditingController(text: ref.read(onboardingProvider).name ?? '');
    return _PageShell(
      emoji: '👋',
      title: "What's your name?",
      subtitle: "We'll personalise everything just for you.",
      onNext: onNext,
      child: TextField(
        controller: ctrl,
        autofocus: true,
        style: AppTypography.headlineMedium,
        decoration: InputDecoration(
          hintText: 'Your name',
          hintStyle: AppTypography.headlineMedium
              .copyWith(color: AppColors.textHint),
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
                  .copyWith(color: AppColors.textSecondary)),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(onboardingProvider).goal;
    final icons = {
      'Lose Weight': '🔥', 'Maintain Weight': '⚖️', 'Gain Weight': '📈',
      'Build Muscle': '💪', 'Improve Health': '❤️', 'Eat Healthier': '🥗',
    };
    return _PageShell(
      emoji: '🎯',
      title: "What's your goal?",
      subtitle: "We'll tailor your calorie and macro targets.",
      onNext: onNext,
      child: Column(
        children: AppConstants.goals.map((g) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SelectCard(
              label: g,
              icon: icons[g],
              selected: selected == g,
              onTap: () =>
                  ref.read(onboardingProvider.notifier).updateGoal(g),
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
                color: on ? AppColors.secondary : AppColors.surfaceVariant,
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
                        : AppColors.textPrimary),
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
  final bool loading;
  const _AllergiesPage({required this.onNext, this.loading = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(onboardingProvider).allergies;
    return _PageShell(
      emoji: '⚠️',
      title: 'Any allergies?',
      subtitle: "We'll warn you when allergens are detected.",
      onNext: onNext,
      nextLabel: 'Finish Setup',
      loading: loading,
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
                    : AppColors.surfaceVariant,
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
                    color: on ? AppColors.error : AppColors.textPrimary),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
