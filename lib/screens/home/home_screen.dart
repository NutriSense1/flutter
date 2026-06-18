import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/router/app_router.dart';
import '../../core/widgets/animations/animated_tap.dart';
import '../../core/widgets/animations/fade_slide.dart';
import '../../providers/user_provider.dart';
import '../../providers/food_log_provider.dart';
import '../../providers/tracking_providers.dart';
import '../../widgets/cards/summary_card.dart';
import '../../widgets/cards/ai_insight_card.dart';
import '../../widgets/cards/macro_ring_card.dart';
import '../../widgets/cards/recent_scans_card.dart';
import '../../widgets/cards/quick_actions_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final summary = ref.watch(todaySummaryProvider);
    final waterConsumed = ref.watch(todayWaterProvider);
    final steps = ref.watch(todayStepsProvider);
    final scanHistory = ref.watch(scanHistoryProvider);

    // Stagger delays — each card enters 80ms after the previous.
    const d = Duration(milliseconds: 80);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Premium App Bar ──────────────────────────────────────────────
          SliverAppBar(
            floating: true,
            pinned: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: _HomeHeader(
              greeting: _greeting(),
              name: user?.name ?? 'Friend',
              onProfileTap: () => context.go(AppRoutes.profile),
            ),
            expandedHeight: 90,
            toolbarHeight: 90,
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Today Summary ─────────────────────────────────────────
                FadeSlide(delay: d * 1, child: SummaryCard(
                  caloriesConsumed: summary.totalCalories,
                  caloriesTarget: user?.dailyCalorieTarget ?? 2000,
                  waterConsumed: waterConsumed,
                  waterTarget: user?.waterGoalLiters ?? 2.5,
                  steps: steps,
                  stepsTarget: 10000,
                  onWaterTap: () => context.push(AppRoutes.water),
                  onStepsTap: () => context.push(AppRoutes.weight),
                )),
                const SizedBox(height: 16),

                // ── Macro Ring ────────────────────────────────────────────
                FadeSlide(delay: d * 2, child: MacroRingCard(
                  calories: summary.totalCalories,
                  caloriesTarget: user?.dailyCalorieTarget ?? 2000,
                  protein: summary.totalProtein,
                  proteinTarget: user?.dailyProteinTarget ?? 150,
                  carbs: summary.totalCarbs,
                  carbsTarget: user?.dailyCarbsTarget ?? 250,
                  fat: summary.totalFat,
                  fatTarget: user?.dailyFatTarget ?? 65,
                )),
                const SizedBox(height: 16),

                // ── AI Insight ────────────────────────────────────────────
                FadeSlide(delay: d * 3, child: const AiInsightCard(
                  insight: "You've eaten 68% of your calorie target today. "
                      "Add a protein-rich dinner to hit your 150g goal — "
                      "you're 42g away. Try grilled chicken with brown rice.",
                )),
                const SizedBox(height: 16),

                // ── Quick Actions ─────────────────────────────────────────
                FadeSlide(delay: d * 4, child: QuickActionsCard(
                  onScan: () => context.push(AppRoutes.scanner),
                  onWeight: () => context.push(AppRoutes.weight),
                  onWater: () => context.push(AppRoutes.water),
                  onDiary: () => context.go(AppRoutes.diary),
                )),
                const SizedBox(height: 16),

                // ── Recent Scans ──────────────────────────────────────────
                if (scanHistory.isNotEmpty) ...[
                  FadeSlide(
                    delay: d * 5,
                    child: RecentScansCard(
                        scans: scanHistory.take(5).toList()),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Weight Progress ───────────────────────────────────────
                FadeSlide(
                  delay: d * 6,
                  child: _WeightProgressTile(
                    currentWeight: user?.weightKg ?? 0,
                    goalWeight: user?.goalWeightKg ?? 0,
                    onTap: () => context.push(AppRoutes.weight),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Premium gradient header ──────────────────────────────────────────────────

class _HomeHeader extends StatelessWidget {
  final String greeting;
  final String name;
  final VoidCallback onProfileTap;

  const _HomeHeader({
    required this.greeting,
    required this.name,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
          24, MediaQuery.of(context).padding.top + 16, 24, 16),
      child: FadeSlide(
        duration: const Duration(milliseconds: 400),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(greeting,
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(name, style: AppTypography.headlineMedium),
                ],
              ),
            ),
            AnimatedTap(
              onTap: onProfileTap,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF34D47A), Color(0xFF0F9D58)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.30),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                    style: AppTypography.titleLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Weight Progress Tile (gradient bar, press animation) ─────────────────────

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
    final progress = (goalWeight == 0 || currentWeight == 0)
        ? 0.0
        : (currentWeight - goalWeight).abs() == 0
            ? 1.0
            : (1.0 -
                    ((currentWeight - goalWeight).abs() / currentWeight)
                        .clamp(0.0, 1.0));

    return AnimatedTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE8F7EE), AppColors.secondary],
                ),
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
                  Text('Weight Progress',
                      style: AppTypography.titleMedium),
                  const SizedBox(height: 3),
                  Text(
                    '${currentWeight.toStringAsFixed(1)} kg  →  '
                    '${goalWeight.toStringAsFixed(1)} kg',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  // Gradient progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Stack(
                      children: [
                        Container(
                            height: 6,
                            color: AppColors.surfaceVariant),
                        FractionallySizedBox(
                          widthFactor: progress.clamp(0.0, 1.0),
                          child: Container(
                            height: 6,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFF34D47A),
                                  AppColors.primary,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
