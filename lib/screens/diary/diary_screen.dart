import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/router/app_router.dart';
import '../../core/constants/app_constants.dart';
import '../../models/food_log_model.dart';
import '../../providers/food_log_provider.dart';
import '../../providers/user_provider.dart';

class DiaryScreen extends ConsumerWidget {
  const DiaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(diaryDateProvider);
    final allLogs = ref.watch(foodLogsProvider);
    final notifier = ref.read(foodLogsProvider.notifier);
    final todayLogs = notifier.logsForDate(selectedDate);
    final summary = DailySummary.fromLogs(selectedDate, todayLogs);
    final user = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Food Diary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 90)),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                ref.read(diaryDateProvider.notifier).state = picked;
              }
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Date selector
          SliverToBoxAdapter(
            child: _DateStrip(
              selected: selectedDate,
              onSelect: (d) => ref.read(diaryDateProvider.notifier).state = d,
            ),
          ),

          // Calorie summary bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: _DailySummaryBar(
                summary: summary,
                calorieTarget: user?.dailyCalorieTarget ?? 2000,
              ),
            ),
          ),

          // Meal sections
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                AppConstants.mealTypes.map((meal) {
                  final mealLogs = notifier.logsForMeal(selectedDate, meal);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _MealSection(
                      mealType: meal,
                      logs: mealLogs,
                      onRemove: (id) => ref.read(foodLogsProvider.notifier).removeLog(id),
                      onAdd: () => context.push(AppRoutes.scanner),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.scanner),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Food'),
      ),
    );
  }
}

// ── Date Strip ─────────────────────────────────────────────────────────────────

class _DateStrip extends StatelessWidget {
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;

  const _DateStrip({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final day = days[i];
          final isSelected = day.day == selected.day && day.month == selected.month;
          final isToday = day.day == today.day;
          return GestureDetector(
            onTap: () => onSelect(day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isToday && !isSelected ? AppColors.primary : Colors.transparent,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    ['M', 'T', 'W', 'T', 'F', 'S', 'S'][day.weekday - 1],
                    style: AppTypography.labelSmall.copyWith(
                      color: isSelected ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${day.day}',
                    style: AppTypography.titleMedium.copyWith(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Daily Summary Bar ─────────────────────────────────────────────────────────

class _DailySummaryBar extends StatelessWidget {
  final DailySummary summary;
  final double calorieTarget;

  const _DailySummaryBar({required this.summary, required this.calorieTarget});

  @override
  Widget build(BuildContext context) {
    final remaining = (calorieTarget - summary.totalCalories).clamp(0, calorieTarget);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CalItem(label: 'Eaten', value: summary.totalCalories.round(), color: AppColors.calories),
              _CalItem(label: 'Remaining', value: remaining.round(), color: AppColors.primary),
              _CalItem(label: 'Goal', value: calorieTarget.round(), color: AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (summary.totalCalories / calorieTarget).clamp(0, 1),
              backgroundColor: AppColors.secondary,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalItem extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _CalItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$value', style: AppTypography.headlineSmall.copyWith(color: color)),
        Text('kcal', style: AppTypography.labelSmall.copyWith(color: color)),
        Text(label, style: AppTypography.labelSmall),
      ],
    );
  }
}

// ── Meal Section ──────────────────────────────────────────────────────────────

class _MealSection extends StatelessWidget {
  final String mealType;
  final List<FoodLogModel> logs;
  final ValueChanged<String> onRemove;
  final VoidCallback onAdd;

  const _MealSection({
    required this.mealType,
    required this.logs,
    required this.onRemove,
    required this.onAdd,
  });

  static const _mealIcons = {
    'Breakfast': '🌅',
    'Lunch': '☀️',
    'Dinner': '🌙',
    'Snack': '🍎',
  };

  double get _totalCals => logs.fold(0, (s, l) => s + l.totalCalories);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              children: [
                Text(_mealIcons[mealType] ?? '🍽️',
                    style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Text(mealType, style: AppTypography.titleLarge),
                const Spacer(),
                if (logs.isNotEmpty)
                  Text('${_totalCals.round()} kcal',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add_rounded, color: AppColors.primary, size: 20),
                  ),
                ),
              ],
            ),
          ),
          if (logs.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text('No food logged yet',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textHint)),
            )
          else ...[
            const Divider(height: 1),
            ...logs.map((log) => _FoodLogTile(log: log, onRemove: () => onRemove(log.id))),
          ],
        ],
      ),
    );
  }
}

class _FoodLogTile extends StatelessWidget {
  final FoodLogModel log;
  final VoidCallback onRemove;
  const _FoodLogTile({required this.log, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(log.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        color: AppColors.error.withOpacity(0.1),
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
      ),
      onDismissed: (_) => onRemove(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.fastfood_outlined,
                  color: AppColors.textSecondary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(log.productName,
                      style: AppTypography.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(
                    '${log.servingsConsumed.toStringAsFixed(1)} serving · ${log.totalProtein.toStringAsFixed(1)}g protein',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),
            Text(
              '${log.totalCalories.round()} kcal',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.calories),
            ),
          ],
        ),
      ),
    );
  }
}
