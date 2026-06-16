import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/router/app_router.dart';
import '../../providers/user_provider.dart';
import '../../providers/food_log_provider.dart';
import '../../providers/tracking_providers.dart';
import '../../widgets/cards/summary_card.dart';
import '../../widgets/cards/ai_insight_card.dart';
import '../../widgets/cards/macro_ring_card.dart';
import '../../widgets/cards/recent_scans_card.dart';
import '../../widgets/cards/quick_actions_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final summary = ref.watch(todaySummaryProvider);
    final waterConsumed = ref.watch(todayWaterProvider);
    final steps = ref.watch(todayStepsProvider);
    final scanHistory = ref.watch(scanHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──
          SliverAppBar(
            floating: true,
            backgroundColor: AppColors.background,
            expandedHeight: 80,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              title: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greeting(),
                          style: AppTypography.bodySmall,
                        ),
                        Text(
                          user?.name ?? 'Friend',
                          style: AppTypography.headlineMedium,
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go(AppRoutes.profile),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.secondary,
                      child: Text(
                        (user?.name.isNotEmpty == true ? user!.name[0] : 'U'),
                        style: AppTypography.titleLarge.copyWith(color: AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Today's Summary ──
                SummaryCard(
                  caloriesConsumed: summary.totalCalories,
                  caloriesTarget: user?.dailyCalorieTarget ?? 2000,
                  waterConsumed: waterConsumed,
                  waterTarget: user?.waterGoalLiters ?? 2.5,
                  steps: steps,
                  stepsTarget: 10000,
                  onWaterTap: () => context.push(AppRoutes.water),
                  onStepsTap: () => context.push(AppRoutes.weight),
                ),
                const SizedBox(height: 20),

                // ── Macro Progress Ring ──
                MacroRingCard(
                  calories: summary.totalCalories,
                  caloriesTarget: user?.dailyCalorieTarget ?? 2000,
                  protein: summary.totalProtein,
                  proteinTarget: user?.dailyProteinTarget ?? 150,
                  carbs: summary.totalCarbs,
                  carbsTarget: user?.dailyCarbsTarget ?? 250,
                  fat: summary.totalFat,
                  fatTarget: user?.dailyFatTarget ?? 65,
                ),
                const SizedBox(height: 20),

                // ── AI Insight ──
                const AiInsightCard(
                  insight: "You've eaten 68% of your calorie target today. "
                      "Add a protein-rich dinner to hit your 150g goal — "
                      "you're 42g away. Try grilled chicken with brown rice.",
                ),
                const SizedBox(height: 20),

                // ── Quick Actions ──
                QuickActionsCard(
                  onScan: () => context.push(AppRoutes.scanner),
                  onWeight: () => context.push(AppRoutes.weight),
                  onWater: () => context.push(AppRoutes.water),
                  onDiary: () => context.go(AppRoutes.diary),
                ),
                const SizedBox(height: 20),

                // ── Recent Scans ──
                if (scanHistory.isNotEmpty) ...[
                  RecentScansCard(scans: scanHistory.take(5).toList()),
                  const SizedBox(height: 20),
                ],

                // ── Weight Progress ──
                _WeightProgressTile(
                  currentWeight: user?.weightKg ?? 0,
                  goalWeight: user?.goalWeightKg ?? 0,
                  onTap: () => context.push(AppRoutes.weight),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeightProgressTile extends StatelessWidget {
  final double currentWeight;
  final double goalWeight;
  final VoidCallback onTap;

  const _WeightProgressTile({
    required this.currentWeight,
    required this.goalWeight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = goalWeight == 0 || currentWeight == 0
        ? 0.0
        : (currentWeight - goalWeight).abs() == 0
            ? 1.0
            : 1.0 - ((currentWeight - goalWeight).abs() / currentWeight).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.monitor_weight_outlined,
                  color: AppColors.primary, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Weight Progress', style: AppTypography.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    '${currentWeight.toStringAsFixed(1)} kg → ${goalWeight.toStringAsFixed(1)} kg',
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppColors.secondary,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
