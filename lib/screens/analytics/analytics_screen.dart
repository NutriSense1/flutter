import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/food_log_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  Map<String, dynamic>? _weeklyData;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ref.read(apiServiceProvider).getWeeklyReport();
      if (mounted) setState(() { _weeklyData = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Could not load analytics. Pull down to refresh.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final logs = ref.watch(foodLogsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final dailyCalories = (_weeklyData?['daily_calories'] as List<dynamic>?)
        ?.map((e) => (e as num).toDouble()).toList() ?? [];
    final dailyScores = (_weeklyData?['daily_health_scores'] as List<dynamic>?)
        ?.map((e) => (e as num).toDouble()).toList() ?? [];
    final avgCalories = (_weeklyData?['avg_calories'] as num?)?.toDouble() ?? 0;
    final avgScore = (_weeklyData?['avg_health_score'] as num?)?.toDouble() ?? 0;
    final consistency = (_weeklyData?['consistency_score'] as num?)?.toDouble() ?? 0;
    final goalAdherence = (_weeklyData?['goal_adherence_score'] as num?)?.toDouble() ?? 0;

    // Derive macro split from today's local logs
    double totalProt = 0, totalCarbs = 0, totalFat = 0;
    for (final log in logs) {
      final n = log.nutritionInfo;
      totalProt += n.protein * log.servingsConsumed;
      totalCarbs += n.carbs * log.servingsConsumed;
      totalFat += n.fat * log.servingsConsumed;
    }
    final macroTotal = totalProt + totalCarbs + totalFat;
    final protPct = macroTotal > 0 ? (totalProt / macroTotal * 100).round() : 30;
    final carbsPct = macroTotal > 0 ? (totalCarbs / macroTotal * 100).round() : 45;
    final fatPct = macroTotal > 0 ? (totalFat / macroTotal * 100).round() : 25;

    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final dividerColor = isDark ? AppColors.darkDivider : AppColors.divider;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 18),
                            const SizedBox(width: 10),
                            Expanded(child: Text(_error!, style: AppTypography.bodySmall)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── KPI Row ────────────────────────────────────────────
                    Row(children: [
                      Expanded(child: _KpiCard(label: 'Avg Calories', value: avgCalories.round().toString(), unit: 'kcal', color: AppColors.calories, isDark: isDark)),
                      const SizedBox(width: 10),
                      Expanded(child: _KpiCard(label: 'Avg Health Score', value: avgScore.round().toString(), unit: '/100', color: AppColors.scoreGood, isDark: isDark)),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: _KpiCard(label: 'Consistency', value: '${consistency.round()}', unit: '%', color: AppColors.primary, isDark: isDark)),
                      const SizedBox(width: 10),
                      Expanded(child: _KpiCard(label: 'Goal Adherence', value: '${goalAdherence.round()}', unit: '%', color: AppColors.accent, isDark: isDark)),
                    ]),
                    const SizedBox(height: 20),

                    // ── Calorie Trend ──────────────────────────────────────
                    _ChartCard(
                      title: '📈 Calorie Trend (Last 7 Days)',
                      surfaceColor: surfaceColor,
                      dividerColor: dividerColor,
                      child: SizedBox(
                        height: 180,
                        child: dailyCalories.isEmpty
                            ? _EmptyChart(message: 'No meals logged this week yet.')
                            : BarChart(BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: (dailyCalories.isEmpty ? 2500 : dailyCalories.reduce((a, b) => a > b ? a : b) * 1.2),
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval: 500,
                                  getDrawingHorizontalLine: (_) => FlLine(
                                    color: dividerColor,
                                    strokeWidth: 1,
                                  ),
                                ),
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
                                        child: Text(days[value.toInt() % days.length], style: AppTypography.labelSmall),
                                      ),
                                    ),
                                  ),
                                ),
                                barGroups: List.generate(dailyCalories.length, (i) {
                                  final isTarget = user?.dailyCalorieTarget != null &&
                                      dailyCalories[i] <= (user!.dailyCalorieTarget * 1.05);
                                  return BarChartGroupData(x: i, barRods: [
                                    BarChartRodData(
                                      toY: dailyCalories[i],
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: isTarget
                                            ? [AppColors.primary.withOpacity(0.7), AppColors.primary]
                                            : [AppColors.calories.withOpacity(0.7), AppColors.calories],
                                      ),
                                      width: 22,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ]);
                                }),
                                // Target line
                                extraLinesData: user?.dailyCalorieTarget != null
                                    ? ExtraLinesData(horizontalLines: [
                                        HorizontalLine(
                                          y: user!.dailyCalorieTarget,
                                          color: AppColors.primary.withOpacity(0.5),
                                          strokeWidth: 1.5,
                                          dashArray: [6, 4],
                                          label: HorizontalLineLabel(
                                            show: true,
                                            style: AppTypography.labelSmall.copyWith(color: AppColors.primary),
                                            alignment: Alignment.topRight,
                                            labelResolver: (_) => 'Target',
                                          ),
                                        ),
                                      ])
                                    : null,
                              )),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Health Score Trend ─────────────────────────────────
                    _ChartCard(
                      title: '🥗 Health Score Trend',
                      surfaceColor: surfaceColor,
                      dividerColor: dividerColor,
                      child: SizedBox(
                        height: 180,
                        child: dailyScores.isEmpty
                            ? _EmptyChart(message: 'Scan and log meals to see your health score trend.')
                            : LineChart(LineChartData(
                                minY: 0,
                                maxY: 100,
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval: 25,
                                  getDrawingHorizontalLine: (_) => FlLine(color: dividerColor, strokeWidth: 1),
                                ),
                                titlesData: FlTitlesData(
                                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) => Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(days[value.toInt() % days.length], style: AppTypography.labelSmall),
                                      ),
                                    ),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: List.generate(dailyScores.length, (i) => FlSpot(i.toDouble(), dailyScores[i])),
                                    isCurved: true,
                                    gradient: const LinearGradient(colors: [AppColors.scoreGood, AppColors.primary]),
                                    barWidth: 3,
                                    dotData: FlDotData(
                                      show: true,
                                      getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                                        radius: 4,
                                        color: AppColors.scoreGood,
                                        strokeWidth: 2,
                                        strokeColor: Colors.white,
                                      ),
                                    ),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [AppColors.scoreGood.withOpacity(0.25), AppColors.scoreGood.withOpacity(0.0)],
                                      ),
                                    ),
                                  ),
                                ],
                              )),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Macro Distribution ─────────────────────────────────
                    _ChartCard(
                      title: '🍽️ Macro Distribution (Today)',
                      surfaceColor: surfaceColor,
                      dividerColor: dividerColor,
                      child: SizedBox(
                        height: 200,
                        child: macroTotal == 0
                            ? _EmptyChart(message: 'Log meals today to see your macro split.')
                            : Row(
                                children: [
                                  Expanded(
                                    child: PieChart(PieChartData(
                                      sectionsSpace: 3,
                                      centerSpaceRadius: 44,
                                      sections: [
                                        PieChartSectionData(value: protPct.toDouble(), color: AppColors.protein, title: '$protPct%', radius: 52, titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                                        PieChartSectionData(value: carbsPct.toDouble(), color: AppColors.carbs, title: '$carbsPct%', radius: 52, titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                                        PieChartSectionData(value: fatPct.toDouble(), color: AppColors.fat, title: '$fatPct%', radius: 52, titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                                      ],
                                    )),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _LegendDot(color: AppColors.protein, label: 'Protein', value: '${totalProt.round()}g'),
                                      const SizedBox(height: 12),
                                      _LegendDot(color: AppColors.carbs, label: 'Carbs', value: '${totalCarbs.round()}g'),
                                      const SizedBox(height: 12),
                                      _LegendDot(color: AppColors.fat, label: 'Fat', value: '${totalFat.round()}g'),
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Weekly Summary ─────────────────────────────────────
                    if (_weeklyData != null)
                      _ChartCard(
                        title: '📊 Weekly Summary',
                        surfaceColor: surfaceColor,
                        dividerColor: dividerColor,
                        child: Column(
                          children: [
                            _SummaryRow(
                              label: 'Days logged',
                              value: '${((consistency / 100) * 7).round()}/7 days',
                              color: consistency >= 70 ? AppColors.success : AppColors.warning,
                              isGood: consistency >= 70,
                            ),
                            Divider(color: dividerColor, height: 1),
                            _SummaryRow(
                              label: 'Avg calories vs target',
                              value: user?.dailyCalorieTarget != null
                                  ? '${avgCalories.round()} / ${user!.dailyCalorieTarget.round()} kcal'
                                  : '${avgCalories.round()} kcal',
                              color: goalAdherence >= 80 ? AppColors.success : AppColors.warning,
                              isGood: goalAdherence >= 80,
                            ),
                            Divider(color: dividerColor, height: 1),
                            _SummaryRow(
                              label: 'Avg health score',
                              value: '${avgScore.round()}/100',
                              color: avgScore >= 70 ? AppColors.scoreGood : avgScore >= 50 ? AppColors.scoreFair : AppColors.scorePoor,
                              isGood: avgScore >= 70,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
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
  final bool isDark;
  const _KpiCard({required this.label, required this.value, required this.unit, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
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
  final Color surfaceColor;
  final Color dividerColor;
  const _ChartCard({required this.title, required this.child, required this.surfaceColor, required this.dividerColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dividerColor),
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

class _EmptyChart extends StatelessWidget {
  final String message;
  const _EmptyChart({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bar_chart_rounded, color: AppColors.textHint, size: 40),
          const SizedBox(height: 8),
          Text(message, style: AppTypography.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  const _LegendDot({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.labelSmall),
            Text(value, style: AppTypography.labelMedium.copyWith(color: color, fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isGood;
  const _SummaryRow({required this.label, required this.value, required this.color, required this.isGood});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTypography.bodyMedium)),
          Text(value, style: AppTypography.titleMedium.copyWith(color: color)),
          const SizedBox(width: 8),
          Icon(isGood ? Icons.check_circle_rounded : Icons.warning_rounded,
              color: isGood ? AppColors.success : AppColors.warning, size: 16),
        ],
      ),
    );
  }
}
