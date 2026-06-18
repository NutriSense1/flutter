import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/nutrition_calculator.dart';
import '../../providers/user_provider.dart';
import '../../providers/tracking_providers.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/common/ns_button.dart';

class WeightScreen extends ConsumerStatefulWidget {
  const WeightScreen({super.key});

  @override
  ConsumerState<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends ConsumerState<WeightScreen> {
  void _showLogDialog() {
    final user = ref.read(userProvider);
    final ctrl = TextEditingController(text: user?.weightKg.toStringAsFixed(1) ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Log Weight', style: AppTypography.headlineMedium),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: AppTypography.numericMedium,
                decoration: const InputDecoration(suffixText: 'kg'),
              ),
              const SizedBox(height: 20),
              NsButton(
                label: 'Save',
                onPressed: () async {
                  final value = double.tryParse(ctrl.text);
                  if (value == null || value <= 0) {
                    Navigator.pop(ctx);
                    return;
                  }
                  final u = ref.read(userProvider);
                  if (u == null) {
                    Navigator.pop(ctx);
                    return;
                  }
                  // Optimistic local update
                  ref.read(weightLogsProvider.notifier).addWeight(u.id, value);
                  ref.read(userProvider.notifier).updateWeight(value);
                  ref.read(userProvider.notifier).addXP(8);
                  Navigator.pop(ctx);

                  try {
                    await ref.read(apiServiceProvider).logWeight(value);
                  } on ApiException catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to sync weight: ${e.message}')),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final logs = ref.watch(weightLogsProvider.notifier).last30Days;
    final latest = ref.watch(latestWeightProvider);
    final currentWeight = latest?.weightKg ?? user?.weightKg ?? 0;
    final goalWeight = user?.goalWeightKg ?? 0;
    final startWeight = logs.isNotEmpty ? logs.first.weightKg : currentWeight;

    final totalToLose = (startWeight - goalWeight).abs();
    final lostSoFar = (startWeight - currentWeight).abs();
    final progressPct = totalToLose == 0 ? 1.0 : (lostSoFar / totalToLose).clamp(0.0, 1.0);

    final weeksToGoal = NutritionCalculator.estimateWeeksToGoal(currentWeight, goalWeight);
    final estDate = DateTime.now().add(Duration(days: weeksToGoal * 7));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Weight Tracking')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current vs Goal
            Row(
              children: [
                Expanded(
                  child: _StatBox(
                    label: 'Current',
                    value: '${currentWeight.toStringAsFixed(1)} kg',
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatBox(
                    label: 'Goal',
                    value: '${goalWeight.toStringAsFixed(1)} kg',
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Progress
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Progress', style: AppTypography.titleLarge),
                      Text('${(progressPct * 100).round()}%',
                          style: AppTypography.titleLarge.copyWith(color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progressPct,
                      backgroundColor: AppColors.secondary,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                      minHeight: 10,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    weeksToGoal > 0
                        ? 'Estimated goal date: ${_formatDate(estDate)} (~$weeksToGoal weeks)'
                        : 'You\'ve reached your goal! 🎉',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Chart
            Container(
              height: 240,
              padding: const EdgeInsets.fromLTRB(8, 20, 16, 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 12),
                    child: Text('30-Day Trend', style: AppTypography.titleMedium),
                  ),
                  Expanded(
                    child: logs.length < 2
                        ? Center(
                            child: Text('Log weight a few times to see your trend',
                                style: AppTypography.bodySmall.copyWith(color: AppColors.textHint)))
                        : LineChart(_buildChartData(logs, goalWeight)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // AI Insight
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.auto_awesome, color: AppColors.primary, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      logs.length >= 2
                          ? 'Your weight trend looks ${lostSoFar > 0 ? 'on track' : 'stable'}. '
                              'Keep logging consistently for more accurate insights.'
                          : 'Log your weight regularly so I can analyse your trend and give personalised insights.',
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showLogDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Log Weight'),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  LineChartData _buildChartData(List logs, double goalWeight) {
    final spots = <FlSpot>[];
    for (int i = 0; i < logs.length; i++) {
      spots.add(FlSpot(i.toDouble(), logs[i].weightKg));
    }
    final minY = (logs.map((l) => l.weightKg as double).reduce((a, b) => a < b ? a : b) - 2);
    final maxY = (logs.map((l) => l.weightKg as double).reduce((a, b) => a > b ? a : b) + 2);

    return LineChartData(
      minY: minY,
      maxY: maxY,
      gridData: const FlGridData(show: true, drawVerticalLine: false),
      titlesData: const FlTitlesData(
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: true, reservedSize: 36),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: AppColors.primary,
          barWidth: 3,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: AppColors.primary.withOpacity(0.1),
          ),
        ),
      ],
      extraLinesData: ExtraLinesData(horizontalLines: [
        HorizontalLine(
          y: goalWeight,
          color: AppColors.accent,
          strokeWidth: 2,
          dashArray: [6, 4],
        ),
      ]),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatBox({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.bodySmall),
          const SizedBox(height: 4),
          Text(value, style: AppTypography.headlineMedium.copyWith(color: color)),
        ],
      ),
    );
  }
}
