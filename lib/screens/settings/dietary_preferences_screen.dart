import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/common/ns_button.dart';

class DietaryPreferencesScreen extends ConsumerStatefulWidget {
  const DietaryPreferencesScreen({super.key});

  @override
  ConsumerState<DietaryPreferencesScreen> createState() => _DietaryPreferencesScreenState();
}

class _DietaryPreferencesScreenState extends ConsumerState<DietaryPreferencesScreen> {
  late Set<String> _diets;
  late Set<String> _allergens;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProvider);
    _diets = {...?user?.dietaryPreferences};
    _allergens = {...?user?.allergies};
  }

  Future<void> _save() async {
    final user = ref.read(userProvider);
    if (user == null) return;

    final newDiets = _diets.toList();
    final newAllergens = _allergens.toList();
    final updates = <String, dynamic>{};
    if (newDiets.toSet().difference(user.dietaryPreferences.toSet()).isNotEmpty ||
        user.dietaryPreferences.toSet().difference(newDiets.toSet()).isNotEmpty) {
      updates['dietary_preferences'] = newDiets;
    }
    if (newAllergens.toSet().difference(user.allergies.toSet()).isNotEmpty ||
        user.allergies.toSet().difference(newAllergens.toSet()).isNotEmpty) {
      updates['allergies'] = newAllergens;
    }

    if (updates.isEmpty) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    setState(() { _saving = true; _error = null; });
    try {
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Dietary Preferences')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          Text('Diet type', style: AppTypography.titleMedium),
          const SizedBox(height: 4),
          Text('Used to tailor recommendations and warnings on scanned food.',
              style: AppTypography.bodySmall.copyWith(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextHint : AppColors.textHint)),
          const SizedBox(height: 12),
          _ChipGroup(
            options: AppConstants.dietaryPreferences,
            selected: _diets,
            onToggle: (v) => setState(() => _diets.contains(v) ? _diets.remove(v) : _diets.add(v)),
          ),

          const SizedBox(height: 28),
          Text('Allergies & intolerances', style: AppTypography.titleMedium),
          const SizedBox(height: 4),
          Text('Scanned food containing these will be flagged with a warning.',
              style: AppTypography.bodySmall.copyWith(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextHint : AppColors.textHint)),
          const SizedBox(height: 12),
          _ChipGroup(
            options: AppConstants.allergens,
            selected: _allergens,
            color: AppColors.error,
            onToggle: (v) =>
                setState(() => _allergens.contains(v) ? _allergens.remove(v) : _allergens.add(v)),
          ),

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

class _ChipGroup extends StatelessWidget {
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final Color color;
  const _ChipGroup({
    required this.options,
    required this.selected,
    required this.onToggle,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((o) {
        final isSelected = selected.contains(o);
        return GestureDetector(
          onTap: () => onToggle(o),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.12) : (Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSelected ? color : Colors.transparent, width: 1.5),
            ),
            child: Text(
              o,
              style: AppTypography.bodyMedium.copyWith(
                color: isSelected ? color : (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
