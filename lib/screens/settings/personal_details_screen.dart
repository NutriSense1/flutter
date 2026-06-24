import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/common/ns_button.dart';

class PersonalDetailsScreen extends ConsumerStatefulWidget {
  const PersonalDetailsScreen({super.key});
  @override
  ConsumerState<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends ConsumerState<PersonalDetailsScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _weightCtrl;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProvider);
    _nameCtrl   = TextEditingController(text: user?.name ?? '');
    _weightCtrl = TextEditingController(text: user?.weightKg.toStringAsFixed(1) ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final user = ref.read(userProvider);
    if (user == null) return;

    final newWeight = double.tryParse(_weightCtrl.text.trim());
    if (_nameCtrl.text.trim().isEmpty) { setState(() => _error = 'Name can\'t be empty.'); return; }
    if (newWeight == null || newWeight <= 0) { setState(() => _error = 'Enter a valid weight.'); return; }

    final updates = <String, dynamic>{};
    if (_nameCtrl.text.trim() != user.name) updates['name'] = _nameCtrl.text.trim();
    if (newWeight != user.weightKg)         updates['weight_kg'] = newWeight;

    if (updates.isEmpty) { if (mounted) Navigator.of(context).pop(); return; }

    setState(() { _saving = true; _error = null; });
    try {
      final updated = await ref.read(apiServiceProvider).updateProfile(updates);
      ref.read(userProvider.notifier).setUser(updated);
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user    = ref.watch(userProvider);
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final secTxt  = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final hintTxt = isDark ? AppColors.darkTextHint : AppColors.textHint;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Personal Details')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          NsTextField(controller: _nameCtrl, label: 'Name', prefixIcon: Icons.person_outline),
          const SizedBox(height: 16),
          Text(user?.email ?? '', style: AppTypography.bodySmall.copyWith(color: hintTxt)),
          const SizedBox(height: 24),
          NsTextField(
            controller: _weightCtrl,
            label: 'Current weight (kg)',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixIcon: Icons.monitor_weight_outlined,
          ),
          const SizedBox(height: 24),
          _ReadOnlyRow(label: 'Age',    value: '${user?.age ?? '—'} years', secTxt: secTxt, hintTxt: hintTxt),
          _ReadOnlyRow(label: 'Gender', value: user?.gender ?? '—',          secTxt: secTxt, hintTxt: hintTxt),
          _ReadOnlyRow(label: 'Height', value: '${user?.heightCm.toStringAsFixed(0) ?? '—'} cm', secTxt: secTxt, hintTxt: hintTxt),
          const SizedBox(height: 8),
          Text(
            'Age, gender, and height can\'t be edited here. Contact support if one of these was entered incorrectly during onboarding.',
            style: AppTypography.bodySmall.copyWith(color: hintTxt),
          ),
          if (_error != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.error.withOpacity(0.07), borderRadius: BorderRadius.circular(10)),
              child: Text(_error!, style: AppTypography.bodySmall.copyWith(color: AppColors.error)),
            ),
          ],
          const SizedBox(height: 32),
          NsButton(label: 'Save changes', onPressed: _save, loading: _saving),
        ],
      ),
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  final String label;
  final String value;
  final Color secTxt;
  final Color hintTxt;
  const _ReadOnlyRow({required this.label, required this.value, required this.secTxt, required this.hintTxt});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTypography.bodyMedium.copyWith(color: secTxt))),
          Text(value, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          Icon(Icons.lock_outline_rounded, size: 15, color: hintTxt),
        ],
      ),
    );
  }
}
