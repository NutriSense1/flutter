import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/router/app_router.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/common/ns_button.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 10;
  bool _submitting = false;
  String? _submitError;

  void _next() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _submitOnboarding();
    }
  }

  /// Sends the collected answers to the backend, which creates the
  /// `users` row and computes BMR/TDEE/calorie targets server-side.
  /// Requires the user to already be signed in to Firebase (auth now
  /// happens BEFORE onboarding in the app flow).
  Future<void> _submitOnboarding() async {
    final data = ref.read(onboardingProvider);
    if (!data.isComplete) {
      setState(() => _submitError = 'Please complete all steps.');
      return;
    }

    setState(() {
      _submitting = true;
      _submitError = null;
    });

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

  void _back() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      if (_currentPage > 0)
                        GestureDetector(
                          onTap: _back,
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              size: 20, color: AppColors.textPrimary),
                        )
                      else
                        const SizedBox(width: 20),
                      const Spacer(),
                      Text(
                        '${_currentPage + 1} of $_totalPages',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (_currentPage + 1) / _totalPages,
                      backgroundColor: AppColors.secondary,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                      minHeight: 6,
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
                          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_submitError!,
                                style: AppTypography.bodySmall.copyWith(color: AppColors.error)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
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

// ─── Pages ─────────────────────────────────────────────────────────────────────

class _WelcomePage extends StatelessWidget {
  final VoidCallback onNext;
  const _WelcomePage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.restaurant_menu, color: Colors.white, size: 44),
          ),
          const SizedBox(height: 32),
          Text('Your personal\nnutrition coach\nis here 🥗',
              style: AppTypography.displayLarge),
          const SizedBox(height: 16),
          Text(
            'Scan food, understand ingredients, track macros, and make smarter choices every day.',
            style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 40),
          _FeatureRow(icon: Icons.camera_alt_outlined, label: 'Scan any food instantly'),
          const SizedBox(height: 12),
          _FeatureRow(icon: Icons.psychology_outlined, label: 'AI-powered health insights'),
          const SizedBox(height: 12),
          _FeatureRow(icon: Icons.trending_up_rounded, label: 'Track your progress daily'),
          const Spacer(),
          NsButton(label: "Let's get started", onPressed: onNext),
          const SizedBox(height: 16),
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
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(12),
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
    final ctrl = TextEditingController(text: ref.read(onboardingProvider).name ?? '');
    return _OnboardingPageShell(
      emoji: '👋',
      title: 'What\'s your name?',
      subtitle: 'We\'ll use this to personalise your experience.',
      onNext: onNext,
      child: TextField(
        controller: ctrl,
        autofocus: true,
        style: AppTypography.headlineMedium,
        decoration: InputDecoration(
          hintText: 'Your name',
          hintStyle: AppTypography.headlineMedium.copyWith(color: AppColors.textHint),
        ),
        textCapitalization: TextCapitalization.words,
        onChanged: (v) => ref.read(onboardingProvider.notifier).updateName(v),
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
    return _OnboardingPageShell(
      emoji: '🎂',
      title: 'How old are you?',
      subtitle: 'Your age helps us calculate accurate nutrition targets.',
      onNext: widget.onNext,
      child: Column(
        children: [
          Text('$_age', style: AppTypography.numericLarge.copyWith(color: AppColors.primary)),
          const SizedBox(height: 8),
          Text('years old', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          Slider(
            value: _age.toDouble(),
            min: 13,
            max: 90,
            divisions: 77,
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
    return _OnboardingPageShell(
      emoji: '🧬',
      title: 'Your biological sex?',
      subtitle: 'Used for precise BMR and calorie calculations.',
      onNext: onNext,
      child: Column(
        children: [
          _SelectionCard(
            label: 'Male',
            icon: '♂️',
            selected: selected == 'Male',
            onTap: () => ref.read(onboardingProvider.notifier).updateGender('Male'),
          ),
          const SizedBox(height: 12),
          _SelectionCard(
            label: 'Female',
            icon: '♀️',
            selected: selected == 'Female',
            onTap: () => ref.read(onboardingProvider.notifier).updateGender('Female'),
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
  ConsumerState<_HeightWeightPage> createState() => _HeightWeightPageState();
}

class _HeightWeightPageState extends ConsumerState<_HeightWeightPage> {
  double _height = 170;
  double _weight = 70;

  @override
  void initState() {
    super.initState();
    final data = ref.read(onboardingProvider);
    _height = data.heightCm ?? 170;
    _weight = data.weightKg ?? 70;
  }

  @override
  Widget build(BuildContext context) {
    return _OnboardingPageShell(
      emoji: '📏',
      title: 'Height & Weight',
      subtitle: 'Used to calculate your BMI and calorie needs.',
      onNext: widget.onNext,
      child: Column(
        children: [
          _SliderRow(
            label: 'Height',
            value: _height,
            unit: 'cm',
            min: 100,
            max: 230,
            onChanged: (v) {
              setState(() => _height = v);
              ref.read(onboardingProvider.notifier).updateHeight(v);
            },
          ),
          const SizedBox(height: 24),
          _SliderRow(
            label: 'Weight',
            value: _weight,
            unit: 'kg',
            min: 30,
            max: 200,
            onChanged: (v) {
              setState(() => _weight = v);
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
    final descriptions = {
      'Sedentary': 'Little or no exercise, desk job',
      'Lightly Active': '1–3 days/week light exercise',
      'Moderately Active': '3–5 days/week moderate exercise',
      'Very Active': '6–7 days/week hard exercise',
      'Extremely Active': 'Twice daily, very intense workouts',
    };
    return _OnboardingPageShell(
      emoji: '🏃',
      title: 'Activity Level',
      subtitle: 'How active are you on a typical week?',
      onNext: onNext,
      child: Column(
        children: AppConstants.activityLevels.map((level) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SelectionCard(
              label: level,
              subtitle: descriptions[level],
              selected: selected == level,
              onTap: () => ref.read(onboardingProvider.notifier).updateActivityLevel(level),
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
      'Lose Weight': '🔥',
      'Maintain Weight': '⚖️',
      'Gain Weight': '📈',
      'Build Muscle': '💪',
      'Improve Health': '❤️',
      'Eat Healthier': '🥗',
    };
    return _OnboardingPageShell(
      emoji: '🎯',
      title: 'What\'s your goal?',
      subtitle: 'We\'ll tailor your calorie and macro targets.',
      onNext: onNext,
      child: Column(
        children: AppConstants.goals.map((goal) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SelectionCard(
              label: goal,
              icon: icons[goal],
              selected: selected == goal,
              onTap: () => ref.read(onboardingProvider.notifier).updateGoal(goal),
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
  ConsumerState<_GoalWeightPage> createState() => _GoalWeightPageState();
}

class _GoalWeightPageState extends ConsumerState<_GoalWeightPage> {
  double _goalWeight = 65;

  @override
  void initState() {
    super.initState();
    _goalWeight = ref.read(onboardingProvider).goalWeightKg ??
        (ref.read(onboardingProvider).weightKg ?? 65);
  }

  @override
  Widget build(BuildContext context) {
    return _OnboardingPageShell(
      emoji: '🏁',
      title: 'Goal Weight',
      subtitle: 'What\'s your target weight?',
      onNext: widget.onNext,
      child: _SliderRow(
        label: 'Goal Weight',
        value: _goalWeight,
        unit: 'kg',
        min: 30,
        max: 200,
        onChanged: (v) {
          setState(() => _goalWeight = v);
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
    return _OnboardingPageShell(
      emoji: '🥦',
      title: 'Dietary Preferences',
      subtitle: 'Select all that apply. We\'ll tailor recommendations.',
      onNext: onNext,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: AppConstants.dietaryPreferences.map((pref) {
          final isSelected = selected.contains(pref);
          return FilterChip(
            label: Text(pref),
            selected: isSelected,
            onSelected: (_) => ref.read(onboardingProvider.notifier).toggleDietaryPreference(pref),
            selectedColor: AppColors.secondary,
            checkmarkColor: AppColors.primary,
            labelStyle: AppTypography.labelMedium.copyWith(
              color: isSelected ? AppColors.primary : AppColors.textPrimary,
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
    return _OnboardingPageShell(
      emoji: '⚠️',
      title: 'Any allergies?',
      subtitle: 'We\'ll warn you when detected allergens are found.',
      onNext: onNext,
      nextLabel: 'Finish',
      loading: loading,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: AppConstants.allergens.map((allergen) {
          final isSelected = selected.contains(allergen);
          return FilterChip(
            label: Text(allergen),
            selected: isSelected,
            onSelected: (_) => ref.read(onboardingProvider.notifier).toggleAllergen(allergen),
            selectedColor: const Color(0xFFFFE4E4),
            checkmarkColor: AppColors.error,
            labelStyle: AppTypography.labelMedium.copyWith(
              color: isSelected ? AppColors.error : AppColors.textPrimary,
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Reusable Shell ────────────────────────────────────────────────────────────

class _OnboardingPageShell extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback onNext;
  final String nextLabel;
  final bool loading;

  const _OnboardingPageShell({
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(title, style: AppTypography.headlineLarge),
          const SizedBox(height: 8),
          Text(subtitle,
              style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          Expanded(child: SingleChildScrollView(child: child)),
          NsButton(label: nextLabel, onPressed: onNext, loading: loading),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─── Reusable UI Components ────────────────────────────────────────────────────

class _SelectionCard extends StatelessWidget {
  final String label;
  final String? subtitle;
  final String? icon;
  final bool selected;
  final VoidCallback onTap;

  const _SelectionCard({
    required this.label,
    this.subtitle,
    this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.secondary : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Text(icon!, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTypography.titleMedium.copyWith(
                        color: selected ? AppColors.primary : AppColors.textPrimary,
                      )),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: AppTypography.bodySmall),
                  ],
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22),
          ],
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
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value.toStringAsFixed(1),
                    style: AppTypography.headlineMedium.copyWith(color: AppColors.primary),
                  ),
                  TextSpan(
                    text: ' $unit',
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
