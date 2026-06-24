import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/nutrition_calculator.dart';
import '../../models/tracking_models.dart';
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

class _WeightScreenState extends ConsumerState<WeightScreen>
    with SingleTickerProviderStateMixin {
  bool _initialLoading = true;
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadAllLogs();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAllLogs() async {
    try {
      final logs = await ref.read(apiServiceProvider).getWeightLogs(days: 0);
      ref.read(weightLogsProvider.notifier).loadLogs(logs);
    } catch (_) {
      // Keep whatever is cached locally
    } finally {
      if (mounted) setState(() => _initialLoading = false);
    }
  }

  void _showLogDialog() {
    final user = ref.read(userProvider);
    final latest = ref.read(weightLogsProvider.notifier).latestLog;
    final initial = latest?.weightKg ?? user?.weightKg ?? 0;
    final ctrl = TextEditingController(
        text: initial > 0 ? initial.toStringAsFixed(1) : '');
    final noteCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkSurface
                : AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkDivider : AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('Log Weight', style: AppTypography.headlineMedium),
              const SizedBox(height: 20),
              TextField(
                controller: ctrl,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: AppTypography.numericMedium,
                decoration: const InputDecoration(
                  labelText: 'Weight',
                  suffixText: 'kg',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  hintText: 'e.g. after workout, morning',
                ),
              ),
              const SizedBox(height: 24),
              NsButton(
                label: 'Save',
                onPressed: () async {
                  final value = double.tryParse(ctrl.text.trim());
                  if (value == null || value <= 0) return;
                  final u = ref.read(userProvider);
                  if (u == null) return;

                  // Optimistic local add
                  final tempLog = WeightLogModel(
                    id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
                    userId: u.id,
                    weightKg: value,
                    note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                    loggedAt: DateTime.now(),
                  );
                  ref.read(weightLogsProvider.notifier).addLog(tempLog);
                  ref.read(userProvider.notifier).updateWeight(value);
                  ref.read(userProvider.notifier).addXP(8);
                  Navigator.pop(ctx);

                  try {
                    final raw = await ref.read(apiServiceProvider).logWeight(
                      value,
                      note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                    );
                    final confirmed = WeightLogModel.fromJson(raw);
                    // Replace temp with confirmed
                    ref.read(weightLogsProvider.notifier).removeLog(tempLog.id);
                    ref.read(weightLogsProvider.notifier).addLog(confirmed);
                  } on ApiException catch (e) {
                    ref.read(weightLogsProvider.notifier).removeLog(tempLog.id);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to sync: ${e.message}')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteLog(WeightLogModel log) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete entry?'),
        content: Text(
          'Remove ${log.weightKg.toStringAsFixed(1)} kg logged on ${_fmtDate(log.loggedAt)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    ref.read(weightLogsProvider.notifier).removeLog(log.id);
    try {
      await ref.read(apiServiceProvider).deleteWeightLog(log.id);
    } catch (_) {
      ref.read(weightLogsProvider.notifier).addLog(log);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final allLogs = ref.watch(weightLogsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final latest = ref.watch(latestWeightProvider);
    final currentWeight = latest?.weightKg ?? user?.weightKg ?? 0;
    final goalWeight = user?.goalWeightKg ?? 0;
    final last30 = ref.read(weightLogsProvider.notifier).last30Days;
    final chronoAll = ref.read(weightLogsProvider.notifier).chronological;

    final startWeight = chronoAll.isNotEmpty ? chronoAll.first.weightKg : currentWeight;
    final totalToLose = (startWeight - goalWeight).abs();
    final lostSoFar = (startWeight - currentWeight).abs();
    final progressPct =
        totalToLose == 0 ? 1.0 : (lostSoFar / totalToLose).clamp(0.0, 1.0);
    final weeksToGoal =
        NutritionCalculator.estimateWeeksToGoal(currentWeight, goalWeight);
    final estDate = DateTime.now().add(Duration(days: weeksToGoal * 7));

    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final dividerColor = isDark ? AppColors.darkDivider : AppColors.divider;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Weight Tracking'),
        actions: [
          if (_initialLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loadAllLogs,
            ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'All Logs'),
          ],
        ),
      ),
      body: _initialLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabCtrl,
              children: [
                // ── Overview Tab ──────────────────────────────────────────
                RefreshIndicator(
                  onRefresh: _loadAllLogs,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats row
                        Row(
                          children: [
                            Expanded(child: _StatBox(label: 'Current', value: currentWeight > 0 ? '${currentWeight.toStringAsFixed(1)} kg' : '—', color: AppColors.primary, isDark: isDark)),
                            const SizedBox(width: 12),
                            Expanded(child: _StatBox(label: 'Goal', value: goalWeight > 0 ? '${goalWeight.toStringAsFixed(1)} kg' : '—', color: AppColors.accent, isDark: isDark)),
                            const SizedBox(width: 12),
                            Expanded(child: _StatBox(label: 'Entries', value: '${allLogs.length}', color: AppColors.info, isDark: isDark)),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Progress
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: dividerColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Progress to Goal', style: AppTypography.titleLarge),
                                  Text('${(progressPct * 100).round()}%',
                                      style: AppTypography.titleLarge.copyWith(color: AppColors.primary)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0, end: progressPct),
                                  duration: const Duration(milliseconds: 700),
                                  curve: Curves.easeOut,
                                  builder: (_, val, __) => LinearProgressIndicator(
                                    value: val,
                                    backgroundColor: isDark ? AppColors.darkSurfaceVariant : AppColors.secondary,
                                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                                    minHeight: 10,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                weeksToGoal > 0
                                    ? 'Estimated: ${_fmtDate(estDate)} (~$weeksToGoal weeks)'
                                    : currentWeight == 0
                                        ? 'Log your weight to track progress'
                                        : '🎉 You\'ve reached your goal!',
                                style: AppTypography.bodySmall.copyWith(
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Chart (last 30 days)
                        Container(
                          height: 250,
                          padding: const EdgeInsets.fromLTRB(8, 20, 16, 12),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: dividerColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 12, bottom: 12),
                                child: Text('30-Day Trend', style: AppTypography.titleMedium),
                              ),
                              Expanded(
                                child: last30.length < 2
                                    ? Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.show_chart_rounded, color: isDark ? AppColors.darkTextSecondary : AppColors.textHint, size: 40),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Log weight a few more times\nto see your trend',
                                              textAlign: TextAlign.center,
                                              style: AppTypography.bodySmall.copyWith(
                                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textHint),
                                            ),
                                          ],
                                        ),
                                      )
                                    : LineChart(_buildChartData(last30, goalWeight, isDark)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // AI insight
                        if (last30.length >= 2)
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.primary.withOpacity(0.12)
                                  : AppColors.secondary,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.auto_awesome, color: AppColors.primary, size: 22),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _buildWeightInsight(last30, goalWeight, lostSoFar),
                                    style: AppTypography.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // ── All Logs Tab ──────────────────────────────────────────
                RefreshIndicator(
                  onRefresh: _loadAllLogs,
                  child: allLogs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.monitor_weight_outlined,
                                  size: 56,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textHint),
                              const SizedBox(height: 12),
                              Text(
                                'No weight logs yet',
                                style: AppTypography.titleMedium.copyWith(
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Tap the button below to log your first weight',
                                style: AppTypography.bodySmall.copyWith(
                                    color: isDark ? AppColors.darkTextHint : AppColors.textHint),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                          itemCount: allLogs.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final log = allLogs[i];
                            final prev = i < allLogs.length - 1 ? allLogs[i + 1] : null;
                            final diff = prev != null ? log.weightKg - prev.weightKg : 0.0;
                            return _LogEntryCard(
                              log: log,
                              diff: diff,
                              isDark: isDark,
                              onDelete: () => _deleteLog(log),
                            );
                          },
                        ),
                ),
              ],
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

  String _buildWeightInsight(List<WeightLogModel> logs, double goal, double lostSoFar) {
    if (logs.length < 2) return 'Keep logging to get personalised weight insights.';
    final first = logs.first;
    final last = logs.last;
    final weeklyRate = (last.weightKg - first.weightKg).abs() / 4;
    final trend = last.weightKg < first.weightKg ? 'losing' : 'gaining';
    final rateStr = weeklyRate.toStringAsFixed(2);
    if (goal > 0 && lostSoFar > 0) {
      return 'You\'re $trend ~$rateStr kg/week and have moved ${lostSoFar.toStringAsFixed(1)} kg '
          'toward your goal. Keep logging consistently for better tracking accuracy.';
    }
    return 'You\'re averaging ~$rateStr kg change per week. Log your weight '
        'every 2-3 days for the most accurate trend tracking.';
  }

  String _fmtDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  LineChartData _buildChartData(List<WeightLogModel> logs, double goalWeight, bool isDark) {
    final spots = List.generate(logs.length, (i) => FlSpot(i.toDouble(), logs[i].weightKg));
    final weights = logs.map((l) => l.weightKg).toList();
    final minY = weights.reduce((a, b) => a < b ? a : b) - 2;
    final maxY = weights.reduce((a, b) => a > b ? a : b) + 2;

    return LineChartData(
      minY: minY,
      maxY: maxY,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) => FlLine(
          color: isDark ? AppColors.darkDivider : AppColors.divider,
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 36,
            getTitlesWidget: (val, _) => Text(
              val.toStringAsFixed(0),
              style: AppTypography.labelSmall,
            ),
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          gradient: const LinearGradient(colors: [AppColors.primaryLight, AppColors.primary]),
          barWidth: 3,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
              radius: 4,
              color: AppColors.primary,
              strokeWidth: 2,
              strokeColor: Colors.white,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.primary.withOpacity(0.15), AppColors.primary.withOpacity(0.0)],
            ),
          ),
        ),
      ],
      extraLinesData: goalWeight > 0
          ? ExtraLinesData(horizontalLines: [
              HorizontalLine(
                y: goalWeight,
                color: AppColors.accent,
                strokeWidth: 2,
                dashArray: [6, 4],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  style: AppTypography.labelSmall.copyWith(color: AppColors.accent),
                  labelResolver: (_) => 'Goal',
                ),
              ),
            ])
          : null,
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;
  const _StatBox({required this.label, required this.value, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.labelSmall),
          const SizedBox(height: 4),
          Text(value, style: AppTypography.titleMedium.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _LogEntryCard extends StatelessWidget {
  final WeightLogModel log;
  final double diff;
  final bool isDark;
  final VoidCallback onDelete;

  const _LogEntryCard({
    required this.log,
    required this.diff,
    required this.isDark,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = '${months[log.loggedAt.month - 1]} ${log.loggedAt.day}, ${log.loggedAt.year}';
    final timeStr = '${log.loggedAt.hour.toString().padLeft(2, '0')}:${log.loggedAt.minute.toString().padLeft(2, '0')}';

    Color diffColor = AppColors.success;
    String diffStr = '';
    IconData diffIcon = Icons.remove_rounded;

    if (diff.abs() > 0.01) {
      diffStr = '${diff > 0 ? '+' : ''}${diff.toStringAsFixed(1)} kg';
      if (diff < 0) {
        diffColor = AppColors.success;
        diffIcon = Icons.arrow_downward_rounded;
      } else {
        diffColor = AppColors.error;
        diffIcon = Icons.arrow_upward_rounded;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(Icons.monitor_weight_outlined, color: AppColors.primary, size: 22),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${log.weightKg.toStringAsFixed(1)} kg',
                      style: AppTypography.titleLarge.copyWith(color: AppColors.primary),
                    ),
                    if (diff.abs() > 0.01) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: diffColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(diffIcon, color: diffColor, size: 12),
                            const SizedBox(width: 2),
                            Text(diffStr, style: AppTypography.labelSmall.copyWith(color: diffColor)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$dateStr  ·  $timeStr',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
                if (log.note != null && log.note!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    log.note!,
                    style: AppTypography.labelSmall.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: Icon(
              Icons.delete_outline_rounded,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textHint,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
