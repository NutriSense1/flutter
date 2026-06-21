import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/theme_provider.dart';

class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  static const _options = [
    (mode: ThemeMode.system, label: 'System', desc: 'Match your device setting', icon: Icons.brightness_auto_rounded),
    (mode: ThemeMode.light, label: 'Light', desc: 'Always use the light theme', icon: Icons.light_mode_rounded),
    (mode: ThemeMode.dark, label: 'Dark', desc: 'Always use the dark theme', icon: Icons.dark_mode_rounded),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Appearance')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          Text('Theme', style: AppTypography.titleMedium),
          const SizedBox(height: 4),
          Text('Applies instantly across the whole app.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textHint)),
          const SizedBox(height: 16),
          ..._options.map((o) {
            final selected = current == o.mode;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(o.mode),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected ? AppColors.primary : (Theme.of(context).dividerColor),
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(o.icon, color: selected ? AppColors.primary : AppColors.textSecondary),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(o.label, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                            Text(o.desc, style: AppTypography.bodySmall.copyWith(color: AppColors.textHint)),
                          ],
                        ),
                      ),
                      if (selected)
                        const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                      else
                        Icon(Icons.circle_outlined, color: AppColors.textHint.withOpacity(0.5)),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
