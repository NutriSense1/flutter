import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/user_provider.dart';
import '../../providers/tracking_providers.dart';
import '../../models/tracking_models.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  int _xpForNextLevel(int level) {
    const thresholds = [0, 100, 250, 500, 1000, 2000, 4000, 7000, 11000, 16000];
    return level < thresholds.length ? thresholds[level] : thresholds.last;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user         = ref.watch(userProvider);
    final achievements = ref.watch(achievementsProvider);
    final unlocked     = achievements.where((a) => a.isUnlocked).length;
    final isDark       = Theme.of(context).brightness == Brightness.dark;
    final surface      = isDark ? AppColors.darkSurface : AppColors.surface;
    final divider      = isDark ? AppColors.darkDivider : AppColors.divider;
    final variantBg    = isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant;

    final level         = user?.level ?? 1;
    final xp            = user?.xp ?? 0;
    final nextLevelXp   = _xpForNextLevel(level);
    final prevLevelXp   = _xpForNextLevel(level - 1);
    final levelProgress = nextLevelXp == prevLevelXp
        ? 1.0
        : ((xp - prevLevelXp) / (nextLevelXp - prevLevelXp)).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Achievements')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Level card — gradient always, no dark issue
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(gradient: AppColors.accentGradient, borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), shape: BoxShape.circle),
                    child: Center(child: Text('$level', style: AppTypography.headlineLarge.copyWith(color: Colors.white))),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Level $level', style: AppTypography.titleLarge.copyWith(color: Colors.white)),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: levelProgress,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            valueColor: const AlwaysStoppedAnimation(Colors.white),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text('$xp / $nextLevelXp XP', style: AppTypography.bodySmall.copyWith(color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Stats row
            Row(
              children: [
                Expanded(child: _StatPill(icon: '🏆', value: '$unlocked/${achievements.length}', label: 'Unlocked', surface: surface, divider: divider)),
                const SizedBox(width: 10),
                Expanded(child: _StatPill(icon: '🔥', value: '${user?.currentStreak ?? 0}',     label: 'Day Streak', surface: surface, divider: divider)),
                const SizedBox(width: 10),
                Expanded(child: _StatPill(icon: '🔍', value: '${user?.totalScans ?? 0}',         label: 'Scans',     surface: surface, divider: divider)),
              ],
            ),
            const SizedBox(height: 24),

            Text('All Achievements', style: AppTypography.headlineSmall),
            const SizedBox(height: 12),
            ...achievements.map((a) => _AchievementTile(achievement: a, isDark: isDark, surface: surface, divider: divider, variantBg: variantBg)),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String icon;
  final String value;
  final String label;
  final Color surface;
  final Color divider;
  const _StatPill({required this.icon, required this.value, required this.label, required this.surface, required this.divider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: divider),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(value, style: AppTypography.titleLarge),
          Text(label, style: AppTypography.labelSmall),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final AchievementModel achievement;
  final bool isDark;
  final Color surface;
  final Color divider;
  final Color variantBg;
  const _AchievementTile({required this.achievement, required this.isDark, required this.surface, required this.divider, required this.variantBg});

  @override
  Widget build(BuildContext context) {
    final unlockedBg = isDark
        ? AppColors.primary.withOpacity(0.15)
        : AppColors.secondary;
    final lockedBg = surface;
    final iconBg = achievement.isUnlocked
        ? AppColors.primary.withOpacity(0.15)
        : variantBg;
    final borderColor = achievement.isUnlocked
        ? AppColors.primary.withOpacity(0.3)
        : divider;
    final titleColor = achievement.isUnlocked
        ? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)
        : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: achievement.isUnlocked ? unlockedBg : lockedBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Center(
              child: Opacity(
                opacity: achievement.isUnlocked ? 1.0 : 0.4,
                child: Text(achievement.icon, style: const TextStyle(fontSize: 24)),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(achievement.title, style: AppTypography.titleMedium.copyWith(color: titleColor)),
                Text(achievement.description, style: AppTypography.bodySmall),
                if (!achievement.isUnlocked && achievement.progress > 0) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: achievement.progress,
                      backgroundColor: variantBg,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                      minHeight: 5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (achievement.isUnlocked)
            const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22)
          else
            Text('+${achievement.xpReward}', style: AppTypography.labelMedium.copyWith(color: AppColors.accent)),
        ],
      ),
    );
  }
}
