import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../models/scan_result_model.dart';
import '../../providers/food_log_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/common/ns_button.dart';

class ScanResultScreen extends ConsumerStatefulWidget {
  final ScanResultModel result;
  const ScanResultScreen({super.key, required this.result});

  @override
  ConsumerState<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends ConsumerState<ScanResultScreen> {
  String _selectedMeal = 'Lunch';
  double _servings = 1.0;
  bool _logging = false;

  Future<void> _logFood() async {
    final user = ref.read(userProvider);
    if (user == null) return;

    setState(() => _logging = true);

    // Optimistic local update so the diary feels instant even before
    // the network call resolves.
    ref.read(foodLogsProvider.notifier).addFromScan(
      widget.result,
      _selectedMeal,
      user.id,
      servings: _servings,
    );

    try {
      final api = ref.read(apiServiceProvider);
      await api.createFoodLog({
        'scan_id': widget.result.id,
        'product_name': widget.result.productName,
        'brand': widget.result.brand,
        'image_url': widget.result.imageUrl,
        'meal_type': _selectedMeal,
        'serving_size': widget.result.servingSize,
        'serving_unit': widget.result.servingUnit,
        'servings_consumed': _servings,
        'nutrition_info': widget.result.nutritionInfo.toJson(),
        'health_score': widget.result.healthScore,
      });
      ref.read(userProvider.notifier).addXP(5);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.result.productName} added to $_selectedMeal'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _logging = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved locally but failed to sync: ${e.message}'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    }
  }

  Color get _scoreColor {
    final s = widget.result.healthScore;
    if (s >= 80) return AppColors.scoreExcellent;
    if (s >= 60) return AppColors.scoreGood;
    if (s >= 40) return AppColors.scoreFair;
    return AppColors.scorePoor;
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // ── Header ──
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_scoreColor.withOpacity(0.15), AppColors.background],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (r.brand != null)
                                Text(r.brand!, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                              Text(r.productName, style: AppTypography.headlineLarge),
                              const SizedBox(height: 4),
                              Text(r.foodType,
                                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        _HealthScoreBadge(score: r.healthScore, label: r.healthScoreLabel, color: _scoreColor),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Confidence ──
                if (r.confidence != ScanConfidence.high)
                  _ConfidenceBanner(confidence: r.confidence),

                // ── Allergen Warning ──
                if (r.detectedAllergens.isNotEmpty)
                  _AllergenBanner(allergens: r.detectedAllergens),

                const SizedBox(height: 16),

                // ── AI Verdict ──
                _SectionCard(
                  title: '🤖 AI Verdict',
                  child: Text(r.aiVerdict, style: AppTypography.bodyMedium),
                ),
                const SizedBox(height: 16),

                // ── Pros & Cons ──
                if (r.positives.isNotEmpty || r.negatives.isNotEmpty)
                  _ProsConsCard(positives: r.positives, negatives: r.negatives),
                const SizedBox(height: 16),

                // ── Calories overview ──
                _CalorieOverviewCard(nutrition: r.nutritionInfo, servings: _servings),
                const SizedBox(height: 16),

                // ── Full Nutrition Label ──
                _NutritionLabelCard(nutrition: r.nutritionInfo),
                const SizedBox(height: 16),

                // ── Ingredients ──
                if (r.ingredients.isNotEmpty)
                  _SectionCard(
                    title: '🧪 Ingredients',
                    child: Text(r.ingredients.join(', '), style: AppTypography.bodyMedium),
                  ),
                const SizedBox(height: 16),

                // ── Additives ──
                if (r.detectedAdditives.isNotEmpty)
                  _AdditivesCard(additives: r.detectedAdditives),
                const SizedBox(height: 16),

                // ── Recommendations ──
                if (r.recommendations.isNotEmpty)
                  _SectionCard(
                    title: '💡 Recommendations',
                    child: Column(
                      children: r.recommendations
                          .map((rec) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.arrow_right_rounded, color: AppColors.primary, size: 20),
                                    const SizedBox(width: 6),
                                    Expanded(child: Text(rec, style: AppTypography.bodyMedium)),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                const SizedBox(height: 16),

                // ── Log to meal ──
                _LogToMealCard(
                  selectedMeal: _selectedMeal,
                  servings: _servings,
                  onMealChange: (m) => setState(() => _selectedMeal = m),
                  onServingsChange: (s) => setState(() => _servings = s),
                ),
              ]),
            ),
          ),
        ],
      ),

      // ── Bottom CTA ──
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: NsButton(label: 'Add to $_selectedMeal', onPressed: _logFood, loading: _logging),
        ),
      ),
    );
  }
}

// ── Sub-widgets ─────────────────────────────────────────────────────────────────

class _HealthScoreBadge extends StatelessWidget {
  final double score;
  final String label;
  final Color color;
  const _HealthScoreBadge({required this.score, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 3),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(score.round().toString(),
              style: AppTypography.headlineMedium.copyWith(color: color)),
          Text(label, style: AppTypography.labelSmall.copyWith(color: color, fontSize: 9)),
        ],
      ),
    );
  }
}

class _ConfidenceBanner extends StatelessWidget {
  final ScanConfidence confidence;
  const _ConfidenceBanner({required this.confidence});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              confidence == ScanConfidence.low
                  ? 'Low confidence — results may not be accurate. Try a clearer photo.'
                  : 'Medium confidence — results are approximate.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}

class _AllergenBanner extends StatelessWidget {
  final List<String> allergens;
  const _AllergenBanner({required this.allergens});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Contains: ${allergens.join(', ')}',
              style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.error, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.titleLarge),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ProsConsCard extends StatelessWidget {
  final List<String> positives;
  final List<String> negatives;
  const _ProsConsCard({required this.positives, required this.negatives});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.thumb_up_outlined, color: AppColors.success, size: 16),
                  const SizedBox(width: 6),
                  Text('Pros', style: AppTypography.titleMedium.copyWith(color: AppColors.success)),
                ]),
                const SizedBox(height: 8),
                ...positives.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• $p', style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary)),
                    )),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.thumb_down_outlined, color: AppColors.error, size: 16),
                  const SizedBox(width: 6),
                  Text('Cons', style: AppTypography.titleMedium.copyWith(color: AppColors.error)),
                ]),
                const SizedBox(height: 8),
                ...negatives.map((n) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• $n', style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary)),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CalorieOverviewCard extends StatelessWidget {
  final NutritionInfo nutrition;
  final double servings;
  const _CalorieOverviewCard({required this.nutrition, required this.servings});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🔥 Calories', style: AppTypography.titleLarge),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _CalStat(label: 'Calories', value: '${(nutrition.calories * servings).round()}', unit: 'kcal', color: AppColors.calories),
              _CalStat(label: 'Protein', value: '${(nutrition.protein * servings).toStringAsFixed(1)}', unit: 'g', color: AppColors.protein),
              _CalStat(label: 'Carbs', value: '${(nutrition.carbs * servings).toStringAsFixed(1)}', unit: 'g', color: AppColors.carbs),
              _CalStat(label: 'Fat', value: '${(nutrition.fat * servings).toStringAsFixed(1)}', unit: 'g', color: AppColors.fat),
            ],
          ),
        ],
      ),
    );
  }
}

class _CalStat extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  const _CalStat({required this.label, required this.value, required this.unit, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTypography.headlineSmall.copyWith(color: color)),
        Text(unit, style: AppTypography.labelSmall.copyWith(color: color)),
        const SizedBox(height: 2),
        Text(label, style: AppTypography.labelSmall),
      ],
    );
  }
}

class _NutritionLabelCard extends StatelessWidget {
  final NutritionInfo nutrition;
  const _NutritionLabelCard({required this.nutrition});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '📊 Nutrition Facts',
      child: Column(
        children: [
          _NutritionRow(label: 'Calories', value: '${nutrition.calories.round()} kcal', bold: true),
          const Divider(),
          _NutritionRow(label: 'Total Fat', value: '${nutrition.fat.toStringAsFixed(1)}g'),
          _NutritionRow(label: '  Saturated Fat', value: '${nutrition.saturatedFat.toStringAsFixed(1)}g', secondary: true),
          _NutritionRow(label: '  Trans Fat', value: '${nutrition.transFat.toStringAsFixed(1)}g', secondary: true),
          const Divider(),
          _NutritionRow(label: 'Cholesterol', value: '${nutrition.cholesterol.round()}mg'),
          _NutritionRow(label: 'Sodium', value: '${nutrition.sodium.round()}mg'),
          const Divider(),
          _NutritionRow(label: 'Total Carbohydrates', value: '${nutrition.carbs.toStringAsFixed(1)}g'),
          _NutritionRow(label: '  Dietary Fiber', value: '${nutrition.fiber.toStringAsFixed(1)}g', secondary: true),
          _NutritionRow(label: '  Sugars', value: '${nutrition.sugar.toStringAsFixed(1)}g', secondary: true),
          _NutritionRow(label: '  Added Sugars', value: '${nutrition.addedSugar.toStringAsFixed(1)}g', secondary: true),
          const Divider(),
          _NutritionRow(label: 'Protein', value: '${nutrition.protein.toStringAsFixed(1)}g', bold: true),
          _NutritionRow(label: 'Potassium', value: '${nutrition.potassium.round()}mg'),
        ],
      ),
    );
  }
}

class _NutritionRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final bool secondary;
  const _NutritionRow({required this.label, required this.value, this.bold = false, this.secondary = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: secondary
                  ? AppTypography.bodySmall
                  : bold
                      ? AppTypography.titleMedium
                      : AppTypography.bodyMedium),
          Text(value,
              style: bold ? AppTypography.titleMedium : AppTypography.bodyMedium),
        ],
      ),
    );
  }
}

class _AdditivesCard extends StatelessWidget {
  final List<String> additives;
  const _AdditivesCard({required this.additives});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '⚗️ Additives Detected',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: additives
            .map((a) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error.withOpacity(0.2)),
                  ),
                  child: Text(a,
                      style: AppTypography.labelMedium.copyWith(color: AppColors.error)),
                ))
            .toList(),
      ),
    );
  }
}

class _LogToMealCard extends StatelessWidget {
  final String selectedMeal;
  final double servings;
  final ValueChanged<String> onMealChange;
  final ValueChanged<double> onServingsChange;

  const _LogToMealCard({
    required this.selectedMeal,
    required this.servings,
    required this.onMealChange,
    required this.onServingsChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🍽️ Log to Meal', style: AppTypography.titleLarge),
          const SizedBox(height: 12),
          // Meal type selector
          Row(
            children: AppConstants.mealTypes.map((meal) {
              final isSelected = selectedMeal == meal;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onMealChange(meal),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.secondary : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.transparent),
                    ),
                    child: Text(meal,
                        style: AppTypography.labelMedium.copyWith(
                            color: isSelected ? AppColors.primary : AppColors.textSecondary)),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // Servings
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Servings', style: AppTypography.titleMedium),
              Row(
                children: [
                  _ServingBtn(
                    icon: Icons.remove_rounded,
                    onTap: servings > 0.5 ? () => onServingsChange(servings - 0.5) : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(servings.toStringAsFixed(1),
                        style: AppTypography.headlineSmall.copyWith(color: AppColors.primary)),
                  ),
                  _ServingBtn(
                    icon: Icons.add_rounded,
                    onTap: () => onServingsChange(servings + 0.5),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ServingBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _ServingBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: onTap != null ? AppColors.secondary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            color: onTap != null ? AppColors.primary : AppColors.textHint, size: 20),
      ),
    );
  }
}
