import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/router/app_router.dart';
import '../../providers/user_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile header
            Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.secondary,
                  child: Text(
                    user?.name.isNotEmpty == true ? user!.name[0] : 'U',
                    style: AppTypography.headlineLarge.copyWith(color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.name ?? 'User', style: AppTypography.headlineSmall),
                      Text(user?.email ?? '', style: AppTypography.bodySmall),
                      const SizedBox(height: 6),
                      if (user?.isPremium == true)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: AppColors.accentGradient,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('PREMIUM',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 24),

            // BMI Card
            if (user != null)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    _BmiStat(label: 'BMI', value: user.bmi.toStringAsFixed(1)),
                    _Divider(),
                    _BmiStat(label: 'Category', value: user.bmiCategory),
                    _Divider(),
                    _BmiStat(label: 'Goal', value: user.goal),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            // Premium upsell (if not premium)
            if (user?.isPremium != true)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.workspace_premium_rounded, color: AppColors.accent, size: 28),
                        const SizedBox(width: 10),
                        Text('Go Premium', style: AppTypography.headlineSmall.copyWith(color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Unlimited scans, advanced analytics, AI meal planning & more.',
                      style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                        ),
                        child: const Text('Upgrade — \$9.99/mo'),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            Text('Settings', style: AppTypography.titleLarge),
            const SizedBox(height: 12),
            _SettingsTile(icon: Icons.person_outline, label: 'Personal Details', onTap: () {}),
            _SettingsTile(icon: Icons.flag_outlined, label: 'Goals & Targets', onTap: () {}),
            _SettingsTile(icon: Icons.restaurant_menu_outlined, label: 'Dietary Preferences', onTap: () {}),
            _SettingsTile(icon: Icons.emoji_events_outlined, label: 'Achievements', onTap: () => context.push(AppRoutes.achievements)),
            _SettingsTile(icon: Icons.notifications_outlined, label: 'Notifications', onTap: () {}),
            _SettingsTile(icon: Icons.dark_mode_outlined, label: 'Appearance', onTap: () {}),
            _SettingsTile(icon: Icons.lock_outline, label: 'Privacy & Security', onTap: () {}),
            _SettingsTile(icon: Icons.help_outline, label: 'Help & Support', onTap: () {}),
            const SizedBox(height: 12),
            _SettingsTile(
              icon: Icons.logout_rounded,
              label: 'Sign Out',
              color: AppColors.error,
              onTap: () => context.go(AppRoutes.auth),
            ),
          ],
        ),
      ),
    );
  }
}

class _BmiStat extends StatelessWidget {
  final String label;
  final String value;
  const _BmiStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: AppTypography.titleLarge.copyWith(color: AppColors.primary)),
          const SizedBox(height: 4),
          Text(label, style: AppTypography.labelSmall),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36, color: AppColors.divider);
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color ?? AppColors.textSecondary, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(label,
                  style: AppTypography.bodyLarge.copyWith(color: color ?? AppColors.textPrimary)),
            ),
            if (color == null)
              const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}
