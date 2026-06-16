import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/food_log_provider.dart';
import '../../providers/user_provider.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  String _period = 'Week';

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(foodLogsProvider);
    final user = ref.watch(userProvider);

    // Mock weekly data (in real app, derive from logs grouped by day)
    final weeklyCalories = [1850.0, 2100.0, 1950.0, 2200.0, 1800.0, 2400.0, 2050.0];
    final weeklyScore = [72.0, 68.0, 75.0, 80.0, 65.0, 70.0, 78.0];
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    final avgCalories = weeklyCalories.reduce((a, b) => a + b) / weeklyCalories.length;
    final avgScore = weeklyScore.reduce((a, b) => a + b) / weeklyScore.length;
    final consistencyScore = logs.isEmpty ? 0 : ((logs.length / 21) * 100).clamp(0, 100).round();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: DropdownButton<String>(
              value: _period,
              underline: const SizedBox(),
              items: ['Week', 'Month'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (v) => setState(() => _period = v!),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Row
            Row(
              children: [
                Expanded(child: _KpiCard(label: 'Avg Calories', value: avgCalories.round().toString(), unit: 'kcal', color: AppColors.calories)),
                const SizedBox(width: 10),
                Expanded(child: _KpiCard(label: 'Avg Health Score', value: avgScore.round().toString(), unit: '/100', color: AppColors.scoreGood)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _KpiCard(label: 'Consistency', value: '$consistencyScore', unit: '%', color: AppColors.primary)),
                const SizedBox(width: 10),
                Expanded(child: _KpiCard(label: 'Goal Adherence', value: '${(avgCalories / (user?.dailyCalorieTarget ?? 2000) * 100).round()}', unit: '%', color: AppColors.accent)),
              ],
            ),
            const SizedBox(height: 20),

            // Calorie trend chart
            _ChartCard(
              title: '📈 Calorie Trend',
              child: SizedBox(
                height: 180,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 2800,
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) => Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(days[value.toInt() % 7], style: AppTypography.labelSmall),
                          ),
                        ),
                      ),
                    ),
                    barGroups: List.generate(weeklyCalories.length, (i) {
                      return BarChartGroupData(x: i, barRods: [
                        BarChartRodData(
                          toY: weeklyCalories[i],
                          color: AppColors.calories,
                          width: 18,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ]);
                    }),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Health score trend
            _ChartCard(
              title: '🥗 Health Score Trend',
              child: SizedBox(
                height: 180,
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: 100,
                    gridData: const FlGridData(show: true, drawVerticalLine: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) => Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(days[value.toInt() % 7], style: AppTypography.labelSmall),
                          ),
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: List.generate(weeklyScore.length, (i) => FlSpot(i.toDouble(), weeklyScore[i])),
                        isCurved: true,
                        color: AppColors.scoreGood,
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(show: true, color: AppColors.scoreGood.withOpacity(0.1)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Macro distribution
            _ChartCard(
              title: '🍽️ Macro Distribution',
              child: SizedBox(
                height: 200,
                child: Row(
                  children: [
                    Expanded(
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: [
                            PieChartSectionData(value: 30, color: AppColors.protein, title: '30%', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                            PieChartSectionData(value: 45, color: AppColors.carbs, title: '45%', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                            PieChartSectionData(value: 25, color: AppColors.fat, title: '25%', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _LegendDot(color: AppColors.protein, label: 'Protein'),
                        const SizedBox(height: 10),
                        _LegendDot(color: AppColors.carbs, label: 'Carbs'),
                        const SizedBox(height: 10),
                        _LegendDot(color: AppColors.fat, label: 'Fat'),
                      ],
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Sugar & Sodium trends
            _ChartCard(
              title: '⚠️ Sugar & Sodium',
              child: Column(
                children: [
                  _MiniTrendRow(label: 'Avg Sugar', value: '32g', target: '< 50g', color: AppColors.sugar, isGood: true),
                  const Divider(),
                  _MiniTrendRow(label: 'Avg Sodium', value: '2100mg', target: '< 2300mg', color: AppColors.sodium, isGood: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  const _KpiCard({required this.label, required this.value, required this.unit, required this.color});

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
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: AppTypography.headlineMedium.copyWith(color: color)),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(unit, style: AppTypography.labelSmall.copyWith(color: color)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _ChartCard({required this.title, required this.child});

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
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: AppTypography.bodySmall),
      ],
    );
  }
}

class _MiniTrendRow extends StatelessWidget {
  final String label;
  final String value;
  final String target;
  final Color color;
  final bool isGood;
  const _MiniTrendRow({required this.label, required this.value, required this.target, required this.color, required this.isGood});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: AppTypography.bodyMedium)),
          Text(value, style: AppTypography.titleMedium.copyWith(color: color)),
          const SizedBox(width: 8),
          Icon(isGood ? Icons.check_circle_rounded : Icons.warning_rounded,
              color: isGood ? AppColors.success : AppColors.warning, size: 16),
          const SizedBox(width: 4),
          Text(target, style: AppTypography.labelSmall),
        ],
      ),
    );
  }
}
