import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/common/ns_button.dart';

class PrivacySecurityScreen extends ConsumerStatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  ConsumerState<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends ConsumerState<PrivacySecurityScreen> {
  bool _deleting = false;
  bool _showFullPolicy = false;

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete your account?'),
        content: const Text(
          'This permanently deletes your profile, scan history, food, water and weight logs, achievements, and AI coach history. This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final typedConfirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _TypeToConfirmDialog(),
    );
    if (typedConfirmed != true) return;

    setState(() => _deleting = true);
    try {
      await ref.read(apiServiceProvider).deleteAccount();
      await ref.read(notificationServiceProvider).removeTokenOnSignOut();
      await ref.read(authServiceProvider).signOut();
      ref.read(userProvider.notifier).clearUser();
      if (!mounted) return;
      context.go(AppRoutes.auth);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final variantColor = isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant;
    final dividerColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final secondaryText = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Privacy & Security')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [

          // ── Privacy Policy Section ──────────────────────────────────────
          _SectionCard(
            surfaceColor: surfaceColor,
            dividerColor: dividerColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(isDark ? 0.15 : 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.privacy_tip_rounded, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text('Privacy Policy', style: AppTypography.titleLarge),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Effective date: June 1, 2025  ·  Last updated: June 2025',
                  style: AppTypography.labelSmall.copyWith(color: secondaryText),
                ),
                const SizedBox(height: 16),

                _PolicyBlock(
                  icon: Icons.person_outline_rounded,
                  title: '1. What Data We Collect',
                  body: 'We collect the information you provide during sign-up and use of NutriSense: your name, email address, profile photo (from Google Sign-In), age, gender, height, weight, goals, dietary preferences, food and water logs, weight history, scan results, achievements, and AI coach conversation history.',
                  isDark: isDark,
                ),
                _PolicyBlock(
                  icon: Icons.lock_outline_rounded,
                  title: '2. How We Use Your Data',
                  body: 'Your data is used exclusively to power the NutriSense app: personalising nutrition insights, generating AI coaching responses, tracking your progress, and sending relevant notifications. We do not use your data for advertising or sell it to third parties under any circumstances.',
                  isDark: isDark,
                ),

                if (_showFullPolicy) ...[
                  _PolicyBlock(
                    icon: Icons.storage_rounded,
                    title: '3. How We Store Your Data',
                    body: 'Your data is stored in a Supabase (PostgreSQL) database hosted on Google Cloud Platform in the ap-northeast-1 region (Tokyo). Access is authenticated and encrypted at rest (AES-256) and in transit (TLS 1.3). Your raw database is never directly accessible from the app.',
                    isDark: isDark,
                  ),
                  _PolicyBlock(
                    icon: Icons.login_rounded,
                    title: '4. Authentication',
                    body: 'Sign-in is handled by Firebase Authentication using Google Sign-In (OAuth 2.0). We never see or store your Google password. We only receive your name, email, and profile photo from Google as part of the authentication flow.',
                    isDark: isDark,
                  ),
                  _PolicyBlock(
                    icon: Icons.psychology_rounded,
                    title: '5. AI & Third-Party Services',
                    body: 'NutriSense uses Google Gemini to analyse food photos and power the AI nutrition coach. Food images and contextual nutrition data (not personally identifiable) may be sent to Google\'s Gemini API for processing. We also use the Open Food Facts database (open-source, no personal data shared) to retrieve packaged product nutrition data.',
                    isDark: isDark,
                  ),
                  _PolicyBlock(
                    icon: Icons.notifications_none_rounded,
                    title: '6. Push Notifications',
                    body: 'If you enable push notifications, your device token is stored and used only to deliver in-app reminders (e.g. logging reminders, goal milestones). You can disable notifications at any time in Settings → Notifications.',
                    isDark: isDark,
                  ),
                  _PolicyBlock(
                    icon: Icons.share_rounded,
                    title: '7. Data Sharing',
                    body: 'We do not share, sell, rent, or trade your personal data with any third party for their independent use. Data is only shared with Google (Firebase/Gemini) and Supabase to operate the service, and only under strict data processing agreements.',
                    isDark: isDark,
                  ),
                  _PolicyBlock(
                    icon: Icons.child_care_rounded,
                    title: "8. Children's Privacy",
                    body: 'NutriSense is intended for users aged 16 and above. We do not knowingly collect personal information from children under 16. If you believe a child has provided us with personal information, please contact us and we will delete it promptly.',
                    isDark: isDark,
                  ),
                  _PolicyBlock(
                    icon: Icons.edit_note_rounded,
                    title: '9. Your Rights',
                    body: 'You have the right to access, correct, or delete any personal data we hold about you. You can export your data or delete your account permanently from within the app at any time. For any privacy concerns, contact us at privacy@nutrisense.app.',
                    isDark: isDark,
                  ),
                  _PolicyBlock(
                    icon: Icons.update_rounded,
                    title: '10. Policy Updates',
                    body: 'We may update this Privacy Policy from time to time. When we do, we will update the "Last updated" date above and notify you in the app if the changes are material. Continued use of NutriSense after updates means you accept the revised policy.',
                    isDark: isDark,
                  ),
                ],

                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => setState(() => _showFullPolicy = !_showFullPolicy),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _showFullPolicy ? 'Show less' : 'Read full policy',
                        style: AppTypography.labelMedium.copyWith(color: AppColors.primary),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _showFullPolicy ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Security Section ────────────────────────────────────────────
          _SectionCard(
            surfaceColor: surfaceColor,
            dividerColor: dividerColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(isDark ? 0.15 : 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.security_rounded, color: AppColors.info, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text('Security', style: AppTypography.titleLarge),
                  ],
                ),
                const SizedBox(height: 14),
                _SecurityItem(
                  icon: Icons.lock_outlined,
                  label: 'End-to-end encrypted storage',
                  isDark: isDark,
                ),
                Divider(color: dividerColor, height: 1),
                _SecurityItem(
                  icon: Icons.token_outlined,
                  label: 'OAuth 2.0 via Google Sign-In',
                  isDark: isDark,
                ),
                Divider(color: dividerColor, height: 1),
                _SecurityItem(
                  icon: Icons.verified_user_outlined,
                  label: 'JWT-authenticated API calls',
                  isDark: isDark,
                ),
                Divider(color: dividerColor, height: 1),
                _SecurityItem(
                  icon: Icons.cloud_done_outlined,
                  label: 'Data hosted on Google Cloud (Tokyo)',
                  isDark: isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Contact ─────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: variantColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.mail_outline_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Privacy questions?', style: AppTypography.titleMedium),
                      Text(
                        'Contact us at privacy@nutrisense.app',
                        style: AppTypography.bodySmall.copyWith(color: secondaryText),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Divider(color: dividerColor),
          const SizedBox(height: 24),

          // ── Danger Zone ─────────────────────────────────────────────────
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
              const SizedBox(width: 8),
              Text('Danger Zone', style: AppTypography.titleMedium.copyWith(color: AppColors.error)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Permanently delete your account and all associated data. '
            'This is irreversible — your profile, logs, achievements, and '
            'AI coach history will be deleted immediately.',
            style: AppTypography.bodySmall.copyWith(color: secondaryText),
          ),
          const SizedBox(height: 16),
          NsButton(
            label: 'Delete my account',
            icon: Icons.delete_outline_rounded,
            color: AppColors.error,
            outlined: true,
            loading: _deleting,
            onPressed: _confirmDelete,
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  final Color surfaceColor;
  final Color dividerColor;
  const _SectionCard({required this.child, required this.surfaceColor, required this.dividerColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dividerColor),
      ),
      child: child,
    );
  }
}

class _PolicyBlock extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final bool isDark;
  const _PolicyBlock({required this.icon, required this.title, required this.body, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 16),
              const SizedBox(width: 8),
              Text(title, style: AppTypography.titleMedium),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  const _SecurityItem({required this.icon, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.info, size: 18),
          const SizedBox(width: 12),
          Text(label, style: AppTypography.bodyMedium),
          const Spacer(),
          const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
        ],
      ),
    );
  }
}

class _TypeToConfirmDialog extends StatefulWidget {
  @override
  State<_TypeToConfirmDialog> createState() => _TypeToConfirmDialogState();
}

class _TypeToConfirmDialogState extends State<_TypeToConfirmDialog> {
  final _ctrl = TextEditingController();
  bool _canConfirm = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Type DELETE to confirm'),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'DELETE'),
        onChanged: (v) => setState(() => _canConfirm = v.trim() == 'DELETE'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        TextButton(
          onPressed: _canConfirm ? () => Navigator.of(context).pop(true) : null,
          child: const Text('Delete forever', style: TextStyle(color: AppColors.error)),
        ),
      ],
    );
  }
}
