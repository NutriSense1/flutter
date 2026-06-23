import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class QuickActionsCard extends StatelessWidget {
  final VoidCallback onScan;
  final VoidCallback onWeight;
  final VoidCallback onWater;
  final VoidCallback onDiary;

  const QuickActionsCard({
    super.key,
    required this.onScan,
    required this.onWeight,
    required this.onWater,
    required this.onDiary,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: AppTypography.titleLarge),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _ActionTile(
              icon: Icons.qr_code_scanner_rounded,
              label: 'Scan Food',
              color: AppColors.primary,
              onTap: onScan,
              isDark: isDark,
            )),
            const SizedBox(width: 10),
            Expanded(child: _ActionTile(
              icon: Icons.water_drop_rounded,
              label: 'Log Water',
              color: AppColors.water,
              onTap: onWater,
              isDark: isDark,
            )),
            const SizedBox(width: 10),
            Expanded(child: _ActionTile(
              icon: Icons.monitor_weight_outlined,
              label: 'Log Weight',
              color: AppColors.protein,
              onTap: onWeight,
              isDark: isDark,
            )),
            const SizedBox(width: 10),
            Expanded(child: _ActionTile(
              icon: Icons.menu_book_rounded,
              label: 'Diary',
              color: AppColors.accent,
              onTap: onDiary,
              isDark: isDark,
            )),
          ],
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.12 : 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
