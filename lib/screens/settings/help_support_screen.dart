import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const _faqs = [
    (
      q: 'How accurate is the food scanner?',
      a: 'Scans combine an AI vision model with the Open Food Facts database '
          'when a barcode is detected. Packaged foods with a matched barcode '
          'are highly accurate; AI-only estimates for homemade or loose foods '
          'are a best-effort approximation — always double check anything '
          'related to a medical condition or severe allergy.',
    ),
    (
      q: 'Why was my allergy not flagged on a scan?',
      a: 'Allergen detection relies on the ingredient list being readable in '
          'the photo (or present in the Open Food Facts entry for a matched '
          'barcode). Blurry labels or unlisted ingredients can be missed — '
          'always check the physical label yourself if you have a serious '
          'allergy.',
    ),
    (
      q: 'How do I change my daily calorie target?',
      a: 'Go to Profile → Goals & Targets and update your goal or activity '
          'level — your targets recalculate automatically.',
    ),
    (
      q: 'Can I export my data?',
      a: 'Not yet from within the app. Email us at the address below and '
          'we\'ll send you a copy.',
    ),
    (
      q: 'How do I delete my account?',
      a: 'Profile → Privacy & Security → Delete my account. This is '
          'permanent and removes everything immediately.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          Text('Frequently asked', style: AppTypography.titleMedium),
          const SizedBox(height: 8),
          ..._faqs.map((f) => _FaqTile(question: f.q, answer: f.a)),

          const SizedBox(height: 28),
          Text('Still need help?', style: AppTypography.titleMedium),
          const SizedBox(height: 10),
          _ContactRow(
            icon: Icons.email_outlined,
            // TODO: replace with your real support inbox before shipping —
            // this is a placeholder, same as the Render URL was.
            label: 'support@nutrisense.app',
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'NutriSense v1.0.0',
              style: AppTypography.bodySmall.copyWith(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextHint : AppColors.textHint),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;
  const _FaqTile({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 14),
        title: Text(question, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(answer, style: AppTypography.bodyMedium.copyWith(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ContactRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Clipboard.setData(ClipboardData(text: label));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Copied "$label" to clipboard')),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Text(label, style: AppTypography.bodyLarge),
            const Spacer(),
            Icon(Icons.copy_rounded, size: 16, color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextHint : AppColors.textHint),
          ],
        ),
      ),
    );
  }
}
