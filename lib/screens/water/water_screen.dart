import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../models/tracking_models.dart';
import '../../providers/user_provider.dart';
import '../../providers/tracking_providers.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class WaterScreen extends ConsumerStatefulWidget {
  const WaterScreen({super.key});

  @override
  ConsumerState<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends ConsumerState<WaterScreen> {
  bool _loading = true;
  bool _customInputVisible = false;
  final TextEditingController _customCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTodayWater();
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTodayWater() async {
    try {
      final api = ref.read(apiServiceProvider);
      final data = await api.getTodayWater();
      final logs = (data['logs'] as List<dynamic>? ?? [])
          .map((e) => WaterLogModel.fromJson(e as Map<String, dynamic>))
          .toList();
      ref.read(waterLogsProvider.notifier).loadLogs(logs);
    } catch (_) {
      // Use whatever is cached locally
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addWater(double liters) async {
    final user = ref.read(userProvider);
    if (user == null) return;

    // Optimistic
    final tempLog = ref.read(waterLogsProvider.notifier).addWaterOptimistic(user.id, liters);
    ref.read(userProvider.notifier).addXP(3);

    try {
      final api = ref.read(apiServiceProvider);
      final raw = await api.logWater(liters);
      final confirmed = WaterLogModel.fromJson(raw);
      ref.read(waterLogsProvider.notifier).replaceLog(tempLog.id, confirmed);
    } on ApiException catch (e) {
      // Rollback
      ref.read(waterLogsProvider.notifier).removeLog(tempLog.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to log water: ${e.message}')),
        );
      }
    }
  }

  Future<void> _deleteLog(WaterLogModel log) async {
    // Optimistic remove
    ref.read(waterLogsProvider.notifier).removeLog(log.id);

    try {
      await ref.read(apiServiceProvider).deleteWaterLog(log.id);
    } catch (_) {
      // Rollback
      ref.read(waterLogsProvider.notifier).addLog(log);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete log. Please try again.')),
        );
      }
    }
  }

  void _showCustomInput() {
    setState(() => _customInputVisible = !_customInputVisible);
    _customCtrl.clear();
  }

  void _submitCustom() {
    final ml = double.tryParse(_customCtrl.text.trim());
    if (ml != null && ml > 0) {
      _addWater(ml / 1000);
      setState(() => _customInputVisible = false);
      _customCtrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final consumed = ref.watch(todayWaterProvider);
    final todayLogs = ref.watch(todayWaterLogsProvider);
    final target = user?.waterGoalLiters ?? AppConstants.defaultWaterGoalLiters;
    final progress = (consumed / target).clamp(0.0, 1.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Water Tracking'),
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTodayWater,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Progress Ring ────────────────────────────────────────────
              Center(
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: progress),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOut,
                          builder: (_, val, __) => CircularProgressIndicator(
                            value: val,
                            strokeWidth: 14,
                            backgroundColor: isDark
                                ? AppColors.darkSurfaceVariant
                                : AppColors.secondary,
                            valueColor: const AlwaysStoppedAnimation(AppColors.water),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.water_drop_rounded, color: AppColors.water, size: 28),
                          const SizedBox(height: 6),
                          Text(
                            '${(consumed * 1000).round()}',
                            style: AppTypography.numericLarge.copyWith(color: AppColors.water),
                          ),
                          Text(
                            'of ${(target * 1000).round()} ml',
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),
              Center(
                child: Text(
                  progress >= 1.0
                      ? '🎉 Goal reached!'
                      : '${(progress * 100).round()}% of daily goal',
                  style: AppTypography.titleMedium.copyWith(color: AppColors.water),
                ),
              ),
              const SizedBox(height: 28),

              // ── Quick Add ────────────────────────────────────────────────
              Text('Quick Add', style: AppTypography.titleLarge),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.4,
                children: [
                  _QuickAddTile(label: '250 ml', sublabel: 'Small Glass', icon: Icons.local_drink_outlined, onTap: () => _addWater(0.25)),
                  _QuickAddTile(label: '330 ml', sublabel: 'Can', icon: Icons.sports_bar_outlined, onTap: () => _addWater(0.33)),
                  _QuickAddTile(label: '500 ml', sublabel: 'Bottle', icon: Icons.water_drop_outlined, onTap: () => _addWater(0.5)),
                  _QuickAddTile(label: '1000 ml', sublabel: 'Large Bottle', icon: Icons.water_damage_outlined, onTap: () => _addWater(1.0)),
                ],
              ),
              const SizedBox(height: 12),

              // ── Custom Amount ────────────────────────────────────────────
              GestureDetector(
                onTap: _showCustomInput,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(14),
                    border: _customInputVisible
                        ? Border.all(color: AppColors.water, width: 1.5)
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.add_circle_outline_rounded, color: AppColors.water, size: 22),
                      const SizedBox(width: 12),
                      Text('Custom amount', style: AppTypography.titleMedium),
                      const Spacer(),
                      Icon(
                        _customInputVisible ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
              if (_customInputVisible) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customCtrl,
                        autofocus: true,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          hintText: 'Enter amount',
                          suffixText: 'ml',
                        ),
                        onSubmitted: (_) => _submitCustom(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _submitCustom,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.water,
                        minimumSize: const Size(72, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 28),

              // ── Today's Log ──────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Today's Log", style: AppTypography.titleLarge),
                  if (todayLogs.isNotEmpty)
                    Text(
                      '${todayLogs.length} entries',
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              if (todayLogs.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? AppColors.darkDivider : AppColors.divider,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'No water logged yet today. Tap a quick-add button above!',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? AppColors.darkDivider : AppColors.divider,
                    ),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: todayLogs.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: isDark ? AppColors.darkDivider : AppColors.divider,
                    ),
                    itemBuilder: (context, i) {
                      final log = todayLogs[i];
                      final ml = (log.amountLiters * 1000).round();
                      final time = '${log.loggedAt.hour.toString().padLeft(2, '0')}:${log.loggedAt.minute.toString().padLeft(2, '0')}';
                      return ListTile(
                        leading: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.water.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.water_drop_rounded, color: AppColors.water, size: 18),
                        ),
                        title: Text(
                          '$ml ml',
                          style: AppTypography.titleMedium.copyWith(color: AppColors.water),
                        ),
                        subtitle: Text(time, style: AppTypography.bodySmall),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textHint,
                            size: 20,
                          ),
                          onPressed: () => _deleteLog(log),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAddTile extends StatelessWidget {
  final String label;
  final String sublabel;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickAddTile({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.water.withOpacity(isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.water.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.water, size: 22),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: AppTypography.titleMedium.copyWith(color: AppColors.water)),
                Text(sublabel, style: AppTypography.labelSmall.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
