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

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete your account?'),
        content: const Text(
          'This permanently deletes your profile, scan history, food/water/weight '
          'logs, achievements, and chat history with the AI coach. This cannot be '
          'undone.',
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

    // Second, typed confirmation — deliberately a little more friction
    // than a single tap for something this destructive and irreversible.
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your account has been deleted.')),
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Privacy & Security')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          Text('What we store', style: AppTypography.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Your profile (name, email, age, gender, height/weight, goals), scan '
            'history, food/water/weight logs, achievements, and AI coach chat '
            'history are stored to power the app\'s features. Your Google account '
            'is used only to sign you in — we never see your Google password.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Text(
            'Sign-in is handled by Firebase Authentication via Google Sign-In. '
            'App data is stored in a Supabase (PostgreSQL) database, accessed '
            'only by our backend — never directly from the app.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 24),

          Text('Danger zone', style: AppTypography.titleMedium.copyWith(color: AppColors.error)),
          const SizedBox(height: 8),
          Text(
            'Permanently delete your account and all associated data. This cannot be undone.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
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
