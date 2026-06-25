import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/tracking_providers.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

// ─── AiInsightCard ─────────────────────────────────────────────────────────────
// Displays a real personalised nutrition tip fetched from the Gemini backend.
// Shows a shimmer-style skeleton while loading and an error state on failure.

class AiInsightCard extends ConsumerStatefulWidget {
  const AiInsightCard({super.key});

  @override
  ConsumerState<AiInsightCard> createState() => _AiInsightCardState();
}

class _AiInsightCardState extends ConsumerState<AiInsightCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchTip());
  }

  Future<void> _fetchTip() async {
    final notifier = ref.read(nutritionTipProvider.notifier);
    notifier.setLoading();
    try {
      final data = await ref.read(apiServiceProvider).getNutritionTip();
      notifier.setTip(
        data['title'] as String? ?? 'Today\'s Tip',
        data['tip'] as String? ?? '',
      );
    } catch (_) {
      notifier.setFallback();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tipState = ref.watch(nutritionTipProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D3B25), Color(0xFF0A2D1C)],
              )
            : AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(isDark ? 0.2 : 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: tipState.when(
          loading: () => _LoadingSkeleton(),
          error: (_, __) => _TipContent(
            title: 'Tip of the Day',
            tip: 'Keep logging your meals consistently to unlock personalised AI nutrition insights!',
            onRefresh: _fetchTip,
          ),
          data: (tip) => _TipContent(
            title: tip.title,
            tip: tip.tip,
            onRefresh: _fetchTip,
          ),
        ),
      ),
    );
  }
}

class _TipContent extends StatelessWidget {
  final String title;
  final String tip;
  final VoidCallback onRefresh;

  const _TipContent({required this.title, required this.tip, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'AI Nutrition Insight',
                style: AppTypography.labelMedium.copyWith(
                  color: Colors.white.withOpacity(0.8),
                  letterSpacing: 0.5,
                ),
              ),
            ),
            GestureDetector(
              onTap: onRefresh,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: AppTypography.titleLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          tip,
          style: AppTypography.bodyMedium.copyWith(
            color: Colors.white.withOpacity(0.9),
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _LoadingSkeleton extends StatefulWidget {
  @override
  State<_LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<_LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 0.9).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Bar(width: 36, height: 36, radius: 10, opacity: _anim.value),
              const SizedBox(width: 10),
              _Bar(width: 120, height: 14, radius: 6, opacity: _anim.value),
            ],
          ),
          const SizedBox(height: 14),
          _Bar(width: double.infinity, height: 18, radius: 6, opacity: _anim.value),
          const SizedBox(height: 10),
          _Bar(width: double.infinity, height: 14, radius: 6, opacity: _anim.value * 0.8),
          const SizedBox(height: 6),
          _Bar(width: 200, height: 14, radius: 6, opacity: _anim.value * 0.6),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  final double opacity;
  const _Bar({required this.width, required this.height, required this.radius, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(opacity * 0.3),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ─── MacroRingCard ─────────────────────────────────────────────────────────────

class MacroRingCard extends StatelessWidget {
  final double calories;
  final double caloriesTarget;
  final double protein;
  final double proteinTarget;
  final double carbs;
  final double carbsTarget;
  final double fat;
  final double fatTarget;

  const MacroRingCard({
    super.key,
    required this.calories,
    required this.caloriesTarget,
    required this.protein,
    required this.proteinTarget,
    required this.carbs,
    required this.carbsTarget,
    required this.fat,
    required this.fatTarget,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final dividerColor = isDark ? AppColors.darkDivider : AppColors.divider;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Macronutrients', style: AppTypography.titleLarge),
              Text(
                '${calories.round()} / ${caloriesTarget.round()} kcal',
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MacroBar(label: 'Protein', value: protein, target: proteinTarget, color: AppColors.protein, unit: 'g'),
              const SizedBox(width: 10),
              _MacroBar(label: 'Carbs', value: carbs, target: carbsTarget, color: AppColors.carbs, unit: 'g'),
              const SizedBox(width: 10),
              _MacroBar(label: 'Fat', value: fat, target: fatTarget, color: AppColors.fat, unit: 'g'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroBar extends StatelessWidget {
  final String label;
  final double value;
  final double target;
  final Color color;
  final String unit;

  const _MacroBar({
    required this.label,
    required this.value,
    required this.target,
    required this.color,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = target > 0 ? (value / target).clamp(0.0, 1.0) : 0.0;
    final secTxt = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final priTxt = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.labelSmall.copyWith(color: secTxt)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOut,
              builder: (_, val, __) => LinearProgressIndicator(
                value: val,
                backgroundColor: isDark ? AppColors.darkSurfaceVariant : color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${value.round()}$unit',
            style: AppTypography.labelMedium.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
          Text(
            '/ ${target.round()}$unit',
            style: AppTypography.labelSmall.copyWith(color: secTxt),
          ),
        ],
      ),
    );
  }
}
