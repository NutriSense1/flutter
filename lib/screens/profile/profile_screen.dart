import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/router/app_router.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user    = ref.watch(userProvider);
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final divider = isDark ? AppColors.darkDivider : AppColors.divider;
    final secTxt  = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final hintTxt = isDark ? AppColors.darkTextHint : AppColors.textHint;
    final avatarBg = isDark ? AppColors.primary.withOpacity(0.18) : AppColors.secondary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar + name ────────────────────────────────────────────
            Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: avatarBg,
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
                      Text(user?.email ?? '',     style: AppTypography.bodySmall.copyWith(color: secTxt)),
                      const SizedBox(height: 6),
                      if (user?.isPremium == true)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(gradient: AppColors.accentGradient, borderRadius: BorderRadius.circular(8)),
                          child: const Text('PREMIUM', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () {}),
              ],
            ),
            const SizedBox(height: 24),

            // ── BMI card ─────────────────────────────────────────────────
            if (user != null)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: divider),
                ),
                child: Row(
                  children: [
                    _BmiStat(label: 'BMI',      value: user.bmi.toStringAsFixed(1)),
                    _BmiDivider(color: divider),
                    _BmiStat(label: 'Category', value: user.bmiCategory),
                    _BmiDivider(color: divider),
                    _BmiStat(label: 'Goal',     value: user.goal),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            // ── Premium upsell ────────────────────────────────────────────
            if (user?.isPremium != true)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(20)),
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
                        onPressed: () => context.push(AppRoutes.upgrade),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary),
                        child: const Text('Upgrade Now'),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            Text('Settings', style: AppTypography.titleLarge),
            const SizedBox(height: 12),
            _SettingsTile(icon: Icons.person_outline,        label: 'Personal Details',     secTxt: secTxt, hintTxt: hintTxt, onTap: () => context.push(AppRoutes.personalDetails)),
            _SettingsTile(icon: Icons.flag_outlined,         label: 'Goals & Targets',      secTxt: secTxt, hintTxt: hintTxt, onTap: () => context.push(AppRoutes.goalsTargets)),
            _SettingsTile(icon: Icons.restaurant_menu_outlined, label: 'Dietary Preferences', secTxt: secTxt, hintTxt: hintTxt, onTap: () => context.push(AppRoutes.dietaryPreferences)),
            _SettingsTile(icon: Icons.emoji_events_outlined, label: 'Achievements',          secTxt: secTxt, hintTxt: hintTxt, onTap: () => context.push(AppRoutes.achievements)),
            _SettingsTile(icon: Icons.notifications_outlined, label: 'Notifications',        secTxt: secTxt, hintTxt: hintTxt, onTap: () => context.push(AppRoutes.notificationSettings)),
            _SettingsTile(icon: Icons.dark_mode_outlined,    label: 'Appearance',            secTxt: secTxt, hintTxt: hintTxt, onTap: () => context.push(AppRoutes.appearance)),
            _SettingsTile(icon: Icons.lock_outline,          label: 'Privacy & Security',    secTxt: secTxt, hintTxt: hintTxt, onTap: () => context.push(AppRoutes.privacySecurity)),
            _SettingsTile(icon: Icons.help_outline,          label: 'Help & Support',        secTxt: secTxt, hintTxt: hintTxt, onTap: () => context.push(AppRoutes.helpSupport)),
            const SizedBox(height: 12),
            _SettingsTile(
              icon: Icons.logout_rounded,
              label: 'Sign Out',
              color: AppColors.error,
              secTxt: secTxt,
              hintTxt: hintTxt,
              onTap: () async {
                await ref.read(notificationServiceProvider).removeTokenOnSignOut();
                await ref.read(authServiceProvider).signOut();
                ref.read(userProvider.notifier).clearUser();
                if (context.mounted) context.go(AppRoutes.auth);
              },
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secTxt = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    return Expanded(
      child: Column(
        children: [
          Text(value, style: AppTypography.titleLarge.copyWith(color: AppColors.primary)),
          const SizedBox(height: 4),
          Text(label, style: AppTypography.labelSmall.copyWith(color: secTxt)),
        ],
      ),
    );
  }
}

class _BmiDivider extends StatelessWidget {
  final Color color;
  const _BmiDivider({required this.color});
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 36, color: color);
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final Color secTxt;
  final Color hintTxt;
  const _SettingsTile({required this.icon, required this.label, required this.onTap, required this.secTxt, required this.hintTxt, this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = color ??
        (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary);
    final iconColor = color ?? secTxt;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyLarge.copyWith(color: labelColor),
              ),
            ),
            if (color == null) Icon(Icons.chevron_right_rounded, color: hintTxt),
          ],
        ),
      ),
    );
  }
}
