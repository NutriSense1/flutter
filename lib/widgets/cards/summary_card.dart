import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class SummaryCard extends StatelessWidget {
  final double caloriesConsumed;
  final double caloriesTarget;
  final double waterConsumed;
  final double waterTarget;
  final int steps;
  final int stepsTarget;
  final VoidCallback onWaterTap;
  final VoidCallback onStepsTap;

  const SummaryCard({
    super.key,
    required this.caloriesConsumed,
    required this.caloriesTarget,
    required this.waterConsumed,
    required this.waterTarget,
    required this.steps,
    required this.stepsTarget,
    required this.onWaterTap,
    required this.onStepsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Overview",
            style: AppTypography.titleMedium.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Calories (large)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      caloriesConsumed.round().toString(),
                      style: AppTypography.numericLarge.copyWith(color: Colors.white),
                    ),
                    Text(
                      '/ ${caloriesTarget.round()} kcal',
                      style: AppTypography.bodySmall.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (caloriesConsumed / caloriesTarget).clamp(0, 1),
                        backgroundColor: Colors.white.withOpacity(0.25),
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${(caloriesTarget - caloriesConsumed).round().abs()} kcal remaining',
                      style: AppTypography.labelSmall.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Water & Steps (mini stats)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _MiniStat(
                    icon: Icons.water_drop_outlined,
                    value: '${(waterConsumed * 1000).round()}',
                    unit: 'ml',
                    target: '${(waterTarget * 1000).round()}',
                    onTap: onWaterTap,
                  ),
                  const SizedBox(height: 12),
                  _MiniStat(
                    icon: Icons.directions_walk_rounded,
                    value: _formatSteps(steps),
                    unit: 'steps',
                    target: _formatSteps(stepsTarget),
                    onTap: onStepsTap,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatSteps(int s) => s >= 1000 ? '${(s / 1000).toStringAsFixed(1)}k' : '$s';
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String unit;
  final String target;
  final VoidCallback onTap;

  const _MiniStat({
    required this.icon,
    required this.value,
    required this.unit,
    required this.target,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value $unit',
                  style: AppTypography.titleMedium.copyWith(color: Colors.white, fontSize: 13),
                ),
                Text(
                  '/ $target',
                  style: AppTypography.labelSmall.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
