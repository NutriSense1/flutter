import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/user_provider.dart';
import '../../providers/tracking_providers.dart';

class WaterScreen extends ConsumerWidget {
  const WaterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final consumed = ref.watch(todayWaterProvider);
    final target = user?.waterGoalLiters ?? AppConstants.defaultWaterGoalLiters;
    final progress = (consumed / target).clamp(0.0, 1.0);

    void addWater(double liters) {
      if (user == null) return;
      ref.read(waterLogsProvider.notifier).addWater(user.id, liters);
      ref.read(userProvider.notifier).addXP(3);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Water Tracking')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        child: Column(
          children: [
            // Progress Ring
            SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 16,
                      backgroundColor: AppColors.secondary,
                      valueColor: const AlwaysStoppedAnimation(AppColors.water),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.water_drop_rounded, color: AppColors.water, size: 32),
                      const SizedBox(height: 8),
                      Text('${(consumed * 1000).round()}',
                          style: AppTypography.numericLarge.copyWith(color: AppColors.water)),
                      Text('of ${(target * 1000).round()} ml',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text('${(progress * 100).round()}% of daily goal',
                style: AppTypography.titleMedium.copyWith(color: AppColors.water)),
            const SizedBox(height: 32),

            // Quick add buttons
            Text('Quick Add', style: AppTypography.titleLarge),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.2,
              children: [
                _QuickAddTile(label: '250 ml', sublabel: 'Glass', icon: Icons.local_drink_outlined, onTap: () => addWater(0.25)),
                _QuickAddTile(label: '500 ml', sublabel: 'Bottle', icon: Icons.water_drop_outlined, onTap: () => addWater(0.5)),
                _QuickAddTile(label: '330 ml', sublabel: 'Can', icon: Icons.sports_bar_outlined, onTap: () => addWater(0.33)),
                _QuickAddTile(label: '1000 ml', sublabel: 'Large Bottle', icon: Icons.local_bar_outlined, onTap: () => addWater(1.0)),
              ],
            ),
            const SizedBox(height: 24),

            // Custom amount
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Custom Amount', style: AppTypography.titleMedium),
                  Row(
                    children: [
                      _CircleBtn(icon: Icons.remove_rounded, onTap: () => addWater(-0.1)),
                      const SizedBox(width: 12),
                      _CircleBtn(icon: Icons.add_rounded, onTap: () => addWater(0.1), filled: true),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Reminder settings
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active_outlined, color: AppColors.water),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hydration Reminders', style: AppTypography.titleMedium),
                        Text('Every 2 hours, 8am–8pm', style: AppTypography.bodySmall),
                      ],
                    ),
                  ),
                  Switch(value: true, onChanged: (_) {}, activeColor: AppColors.water),
                ],
              ),
            ),
          ],
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.water.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.water.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.water, size: 26),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.titleMedium.copyWith(color: AppColors.water)),
                Text(sublabel, style: AppTypography.labelSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  const _CircleBtn({required this.icon, required this.onTap, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: filled ? AppColors.water : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: filled ? Colors.white : AppColors.textSecondary, size: 20),
      ),
    );
  }
}
