import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/scan_result_model.dart';

// ─── MacroRingCard ─────────────────────────────────────────────────────────────

class MacroRingCard extends StatelessWidget {
  final double calories;
  final double caloriesTarget;
  final double protein;
  final double proteinTarget;
  final double carbs;
  final double carbsTarget;
  final double fat;
  final double fatTarget;

  const MacroRingCard({
    super.key,
    required this.calories,
    required this.caloriesTarget,
    required this.protein,
    required this.proteinTarget,
    required this.carbs,
    required this.carbsTarget,
    required this.fat,
    required this.fatTarget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Macronutrients', style: AppTypography.titleLarge),
          const SizedBox(height: 16),
          Row(
            children: [
              _MacroBar(
                label: 'Protein',
                value: protein,
                target: proteinTarget,
                color: AppColors.protein,
                unit: 'g',
              ),
              const SizedBox(width: 12),
              _MacroBar(
                label: 'Carbs',
                value: carbs,
                target: carbsTarget,
                color: AppColors.carbs,
                unit: 'g',
              ),
              const SizedBox(width: 12),
              _MacroBar(
                label: 'Fat',
                value: fat,
                target: fatTarget,
                color: AppColors.fat,
                unit: 'g',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroBar extends StatelessWidget {
  final String label;
  final double value;
  final double target;
  final Color color;
  final String unit;

  const _MacroBar({
    required this.label,
    required this.value,
    required this.target,
    required this.color,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final progress = target > 0 ? (value / target).clamp(0.0, 1.0) : 0.0;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.labelSmall),
          const SizedBox(height: 6),
          Text(
            '${value.round()}$unit',
            style: AppTypography.titleMedium.copyWith(color: color),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '/ ${target.round()}$unit',
            style: AppTypography.labelSmall.copyWith(fontSize: 9),
          ),
        ],
      ),
    );
  }
}

// ─── AiInsightCard ─────────────────────────────────────────────────────────────

class AiInsightCard extends StatelessWidget {
  final String insight;

  const AiInsightCard({super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Nutrition Coach',
                  style: AppTypography.titleMedium.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 6),
                Text(insight, style: AppTypography.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── QuickActionsCard ──────────────────────────────────────────────────────────

class QuickActionsCard extends StatelessWidget {
  final VoidCallback onScan;
  final VoidCallback onWeight;
  final VoidCallback onWater;
  final VoidCallback onDiary;

  const QuickActionsCard({
    super.key,
    required this.onScan,
    required this.onWeight,
    required this.onWater,
    required this.onDiary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: AppTypography.titleLarge),
        const SizedBox(height: 12),
        Row(
          children: [
            _QuickAction(icon: Icons.camera_alt_rounded, label: 'Scan Food',
                color: AppColors.primary, onTap: onScan),
            const SizedBox(width: 10),
            _QuickAction(icon: Icons.water_drop_rounded, label: 'Log Water',
                color: AppColors.water, onTap: onWater),
            const SizedBox(width: 10),
            _QuickAction(icon: Icons.monitor_weight_outlined, label: 'Weight',
                color: AppColors.accent, onTap: onWeight),
            const SizedBox(width: 10),
            _QuickAction(icon: Icons.menu_book_rounded, label: 'Diary',
                color: AppColors.protein, onTap: onDiary),
          ],
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 6),
              Text(label,
                  style: AppTypography.labelSmall.copyWith(color: color, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── RecentScansCard ──────────────────────────────────────────────────────────

class RecentScansCard extends StatelessWidget {
  final List<ScanResultModel> scans;

  const RecentScansCard({super.key, required this.scans});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Scans', style: AppTypography.titleLarge),
        const SizedBox(height: 12),
        ...scans.map((scan) => _ScanTile(scan: scan)),
      ],
    );
  }
}

class _ScanTile extends StatelessWidget {
  final ScanResultModel scan;
  const _ScanTile({required this.scan});

  Color get _scoreColor {
    if (scan.healthScore >= 80) return AppColors.scoreExcellent;
    if (scan.healthScore >= 60) return AppColors.scoreGood;
    if (scan.healthScore >= 40) return AppColors.scoreFair;
    return AppColors.scorePoor;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.fastfood_outlined, color: AppColors.textSecondary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(scan.productName,
                    style: AppTypography.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('${scan.nutritionInfo.calories.round()} kcal · ${scan.mealType ?? 'Scanned'}',
                    style: AppTypography.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _scoreColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              scan.healthScore.round().toString(),
              style: AppTypography.titleMedium.copyWith(color: _scoreColor, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
