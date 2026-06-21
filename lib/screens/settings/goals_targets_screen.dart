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
  late String _goal;
  late String _activityLevel;
  late final TextEditingController _goalWeightCtrl;
  late final TextEditingController _waterGoalCtrl;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProvider);
    _goal = user?.goal ?? AppConstants.goals.first;
    _activityLevel = user?.activityLevel ?? AppConstants.activityLevels.first;
    _goalWeightCtrl = TextEditingController(text: user?.goalWeightKg.toStringAsFixed(1) ?? '');
    _waterGoalCtrl = TextEditingController(text: user?.waterGoalLiters.toStringAsFixed(1) ?? '');
  }

  @override
  void dispose() {
    _goalWeightCtrl.dispose();
    _waterGoalCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final user = ref.read(userProvider);
    if (user == null) return;

    final goalWeight = double.tryParse(_goalWeightCtrl.text.trim());
    final waterGoal = double.tryParse(_waterGoalCtrl.text.trim());
    if (goalWeight == null || goalWeight <= 0) {
      setState(() => _error = 'Enter a valid goal weight.');
      return;
    }
    if (waterGoal == null || waterGoal <= 0) {
      setState(() => _error = 'Enter a valid water goal.');
      return;
    }

    final updates = <String, dynamic>{};
    if (_goal != user.goal) updates['goal'] = _goal;
    if (_activityLevel != user.activityLevel) updates['activity_level'] = _activityLevel;
    if (goalWeight != user.goalWeightKg) updates['goal_weight_kg'] = goalWeight;
    if (waterGoal != user.waterGoalLiters) updates['water_goal_liters'] = waterGoal;

    if (updates.isEmpty) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    setState(() { _saving = true; _error = null; });
    try {
      // Changing goal/activity level makes the backend recompute
      // calorie + macro targets server-side (see PATCH /users/me) —
      // the updated UserModel reflects the new targets immediately.
      final updated = await ref.read(apiServiceProvider).updateProfile(updates);
      ref.read(userProvider.notifier).setUser(updated);
      if (mounted) Navigator.of(context).pop();
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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Goals & Targets')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          Text('Goal', style: AppTypography.titleMedium),
          const SizedBox(height: 8),
          _Dropdown(
            value: _goal,
            options: AppConstants.goals,
            onChanged: (v) => setState(() => _goal = v),
          ),
          const SizedBox(height: 20),

          Text('Activity level', style: AppTypography.titleMedium),
          const SizedBox(height: 8),
          _Dropdown(
            value: _activityLevel,
            options: AppConstants.activityLevels,
            onChanged: (v) => setState(() => _activityLevel = v),
          ),
          const SizedBox(height: 20),

          NsTextField(
            controller: _goalWeightCtrl,
            label: 'Goal weight (kg)',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixIcon: Icons.flag_outlined,
          ),
          const SizedBox(height: 16),
          NsTextField(
            controller: _waterGoalCtrl,
            label: 'Daily water goal (liters)',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixIcon: Icons.water_drop_outlined,
          ),

          if (user != null) ...[
            const SizedBox(height: 28),
            Text('Current daily targets', style: AppTypography.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Recalculated automatically when you change goal or activity level.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textHint),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _TargetStat(label: 'Calories', value: '${user.dailyCalorieTarget.round()}'),
                  _TargetStat(label: 'Protein', value: '${user.dailyProteinTarget.round()}g'),
                  _TargetStat(label: 'Carbs', value: '${user.dailyCarbsTarget.round()}g'),
                  _TargetStat(label: 'Fat', value: '${user.dailyFatTarget.round()}g'),
                ],
              ),
            ),
          ],

          if (_error != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(_error!, style: AppTypography.bodySmall.copyWith(color: AppColors.error)),
            ),
          ],

          const SizedBox(height: 32),
          NsButton(label: 'Save changes', onPressed: _save, loading: _saving),
        ],
      ),
    );
  }
}

class _TargetStat extends StatelessWidget {
  final String label;
  final String value;
  const _TargetStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTypography.titleMedium.copyWith(color: AppColors.primary)),
        const SizedBox(height: 2),
        Text(label, style: AppTypography.labelSmall),
      ],
    );
  }
}

class _Dropdown extends StatelessWidget {
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  const _Dropdown({required this.value, required this.options, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: options
              .map((o) => DropdownMenuItem(value: o, child: Text(o, style: AppTypography.bodyLarge)))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}
