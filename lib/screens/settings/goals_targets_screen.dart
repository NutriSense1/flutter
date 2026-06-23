import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/common/ns_button.dart';

class GoalsTargetsScreen extends ConsumerStatefulWidget {
  const GoalsTargetsScreen({super.key});

  @override
  ConsumerState<GoalsTargetsScreen> createState() => _GoalsTargetsScreenState();
}

class _GoalsTargetsScreenState extends ConsumerState<GoalsTargetsScreen> {
  late Set<String> _selectedGoals;
  late String _activityLevel;
  late final TextEditingController _goalWeightCtrl;
  late final TextEditingController _waterGoalCtrl;
  bool _saving = false;
  String? _error;

  static const _availableGoals = [
    _GoalOption('Lose Weight', 'Burn fat and reduce body weight', Icons.trending_down_rounded, AppColors.error),
    _GoalOption('Build Muscle', 'Gain lean mass and strength', Icons.fitness_center_rounded, AppColors.protein),
    _GoalOption('Maintain Weight', 'Stay at your current weight', Icons.balance_rounded, AppColors.info),
    _GoalOption('Improve Nutrition', 'Eat healthier and more balanced', Icons.eco_rounded, AppColors.primary),
    _GoalOption('Increase Energy', 'Feel more energetic through diet', Icons.bolt_rounded, AppColors.accent),
    _GoalOption('Track Macros', 'Monitor protein, carbs and fat', Icons.pie_chart_rounded, AppColors.carbs),
  ];

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProvider);
    // Support both legacy single goal and new multi-goal
    final primaryGoal = user?.goal ?? AppConstants.goals.first;
    _selectedGoals = {primaryGoal};
    _activityLevel = user?.activityLevel ?? AppConstants.activityLevels.first;
    _goalWeightCtrl = TextEditingController(
        text: (user?.goalWeightKg ?? 0) > 0 ? user!.goalWeightKg.toStringAsFixed(1) : '');
    _waterGoalCtrl = TextEditingController(
        text: (user?.waterGoalLiters ?? 0) > 0 ? user!.waterGoalLiters.toStringAsFixed(1) : '');
  }

  @override
  void dispose() {
    _goalWeightCtrl.dispose();
    _waterGoalCtrl.dispose();
    super.dispose();
  }

  void _toggleGoal(String goal) {
    setState(() {
      if (_selectedGoals.contains(goal)) {
        if (_selectedGoals.length > 1) _selectedGoals.remove(goal);
      } else {
        _selectedGoals.add(goal);
      }
    });
  }

  Future<void> _save() async {
    final user = ref.read(userProvider);
    if (user == null) return;

    final goalWeight = double.tryParse(_goalWeightCtrl.text.trim());
    final waterGoal = double.tryParse(_waterGoalCtrl.text.trim());

    if (_goalWeightCtrl.text.trim().isNotEmpty && (goalWeight == null || goalWeight <= 0)) {
      setState(() => _error = 'Enter a valid goal weight.');
      return;
    }
    if (waterGoal == null || waterGoal <= 0) {
      setState(() => _error = 'Enter a valid water goal.');
      return;
    }

    final primaryGoal = _selectedGoals.first;
    final updates = <String, dynamic>{};
    if (primaryGoal != user.goal) updates['goal'] = primaryGoal;
    if (_activityLevel != user.activityLevel) updates['activity_level'] = _activityLevel;
    if (goalWeight != null && goalWeight != user.goalWeightKg) updates['goal_weight_kg'] = goalWeight;
    if (waterGoal != user.waterGoalLiters) updates['water_goal_liters'] = waterGoal;

    if (updates.isEmpty) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    setState(() { _saving = true; _error = null; });
    try {
      final updated = await ref.read(apiServiceProvider).updateProfile(updates);
      ref.read(userProvider.notifier).setUser(updated);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Goals updated!')),
        );
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final variantColor = isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant;
    final dividerColor = isDark ? AppColors.darkDivider : AppColors.divider;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Goals & Targets')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          // ── Goal Selection ────────────────────────────────────────────
          Text('Your Goals', style: AppTypography.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Select one or more goals. Your calorie and macro targets are set by your primary goal.',
            style: AppTypography.bodySmall.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.6,
            children: _availableGoals.map((g) {
              final selected = _selectedGoals.contains(g.label);
              return _GoalCard(
                option: g,
                selected: selected,
                isDark: isDark,
                onTap: () => _toggleGoal(g.label),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // ── Primary Goal Label ─────────────────────────────────────────
          if (_selectedGoals.length > 1)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(isDark ? 0.12 : 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Primary goal: "${_selectedGoals.first}" — used to calculate your daily calorie and macro targets.',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          if (_selectedGoals.length > 1) const SizedBox(height: 20),

          // ── Activity Level ─────────────────────────────────────────────
          Text('Activity Level', style: AppTypography.titleMedium),
          const SizedBox(height: 10),
          ...AppConstants.activityLevels.map((level) {
            final selected = _activityLevel == level;
            return GestureDetector(
              onTap: () => setState(() => _activityLevel = level),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary.withOpacity(isDark ? 0.15 : 0.07)
                      : variantColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? AppColors.primary : dividerColor,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                      color: selected ? AppColors.primary : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(level, style: AppTypography.bodyLarge),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 24),

          // ── Numeric Targets ────────────────────────────────────────────
          Text('Numeric Targets', style: AppTypography.titleMedium),
          const SizedBox(height: 12),
          _TargetTextField(
            controller: _goalWeightCtrl,
            label: 'Goal weight',
            suffix: 'kg',
            icon: Icons.flag_outlined,
          ),
          const SizedBox(height: 12),
          _TargetTextField(
            controller: _waterGoalCtrl,
            label: 'Daily water goal',
            suffix: 'L',
            icon: Icons.water_drop_outlined,
          ),

          // ── Current Daily Targets ──────────────────────────────────────
          if (user != null) ...[
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.track_changes_rounded, color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      Text('Current Daily Targets', style: AppTypography.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Recalculated automatically when you change goal or activity level.',
                    style: AppTypography.labelSmall.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textHint),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _TargetStat(label: 'Calories', value: '${user.dailyCalorieTarget.round()}', unit: 'kcal'),
                      _TargetStat(label: 'Protein', value: '${user.dailyProteinTarget.round()}', unit: 'g'),
                      _TargetStat(label: 'Carbs', value: '${user.dailyCarbsTarget.round()}', unit: 'g'),
                      _TargetStat(label: 'Fat', value: '${user.dailyFatTarget.round()}', unit: 'g'),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // ── Error ──────────────────────────────────────────────────────
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(_error!, style: AppTypography.bodySmall.copyWith(color: AppColors.error)),
            ),
          ],

          const SizedBox(height: 32),
          NsButton(label: 'Save Changes', onPressed: _save, loading: _saving),
        ],
      ),
    );
  }
}

class _GoalOption {
  final String label;
  final String description;
  final IconData icon;
  final Color color;
  const _GoalOption(this.label, this.description, this.icon, this.color);
}

class _GoalCard extends StatelessWidget {
  final _GoalOption option;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _GoalCard({
    required this.option,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? option.color.withOpacity(isDark ? 0.2 : 0.08)
              : (isDark ? AppColors.darkSurface : AppColors.surface),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? option.color : (isDark ? AppColors.darkDivider : AppColors.divider),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(option.icon, color: option.color, size: 20),
                const Spacer(),
                if (selected)
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(color: option.color, shape: BoxShape.circle),
                    child: const Icon(Icons.check, color: Colors.white, size: 12),
                  ),
              ],
            ),
            const Spacer(),
            Text(option.label,
                style: AppTypography.titleMedium.copyWith(
                    color: selected ? option.color : null)),
            Text(
              option.description,
              style: AppTypography.labelSmall.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _TargetTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String suffix;
  final IconData icon;

  const _TargetTextField({
    required this.controller,
    required this.label,
    required this.suffix,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        prefixIcon: Icon(icon, size: 20),
      ),
    );
  }
}

class _TargetStat extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  const _TargetStat({required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(value, style: AppTypography.titleMedium.copyWith(color: AppColors.primary)),
            const SizedBox(width: 2),
            Padding(
              padding: const EdgeInsets.only(bottom: 1),
              child: Text(unit, style: AppTypography.labelSmall.copyWith(color: AppColors.primary)),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: AppTypography.labelSmall),
      ],
    );
  }
}
