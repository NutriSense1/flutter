import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class UpgradeScreen extends ConsumerStatefulWidget {
  const UpgradeScreen({super.key});

  @override
  ConsumerState<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends ConsumerState<UpgradeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedPlan = 1; // 0 = Monthly, 1 = Annual (default — best value)
  bool _processing = false;
  late AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  static const _plans = [
    _Plan(
      id: 'monthly',
      name: 'Monthly',
      price: '₹299',
      period: '/ month',
      annualNote: null,
      savings: null,
    ),
    _Plan(
      id: 'annual',
      name: 'Annual',
      price: '₹179',
      period: '/ month',
      annualNote: 'Billed ₹2,149 / year',
      savings: 'Save 40%',
    ),
    _Plan(
      id: 'lifetime',
      name: 'Lifetime',
      price: '₹5,999',
      period: 'one-time',
      annualNote: 'Pay once, own forever',
      savings: 'Best deal',
    ),
  ];

  static const _features = [
    _Feature(Icons.qr_code_scanner_rounded, 'Unlimited food scans', 'No daily cap — scan as much as you want'),
    _Feature(Icons.auto_awesome_rounded, 'Full AI Coach access', 'Unlimited AI coaching conversations'),
    _Feature(Icons.bar_chart_rounded, 'Advanced analytics', 'Weekly & monthly trends, macro breakdowns'),
    _Feature(Icons.insights_rounded, 'Daily AI nutrition tips', 'Personalised to your data, every day'),
    _Feature(Icons.download_rounded, 'Export your data', 'Download your full nutrition history as CSV'),
    _Feature(Icons.notifications_active_rounded, 'Smart reminders', 'AI-powered meal and hydration reminders'),
    _Feature(Icons.support_agent_rounded, 'Priority support', 'Get help within 24 hours'),
  ];

  Future<void> _subscribe() async {
    setState(() => _processing = true);
    // TODO: Integrate with in-app purchase (RevenueCat / Google Play Billing)
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _processing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Payment integration coming soon! Thank you for your interest.'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final dividerColor = isDark ? AppColors.darkDivider : AppColors.divider;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // ── Hero Header ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: isDark
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0D3B25), Color(0xFF0A1628)],
                      )
                    : AppColors.primaryGradient,
              ),
              padding: EdgeInsets.fromLTRB(
                  24, MediaQuery.of(context).padding.top + 20, 24, 36),
              child: Column(
                children: [
                  // Close button
                  Align(
                    alignment: Alignment.topLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: AppColors.accent, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'NutriSense Premium',
                          style: AppTypography.labelMedium.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Unlock Your Full\nNutrition Potential',
                    textAlign: TextAlign.center,
                    style: AppTypography.displayMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Get unlimited scans, full AI coaching,\nand advanced analytics — all in one plan.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.85),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── Plans ────────────────────────────────────────────────
                Text('Choose your plan', style: AppTypography.titleLarge),
                const SizedBox(height: 12),
                Row(
                  children: List.generate(_plans.length, (i) {
                    final plan = _plans[i];
                    final selected = _selectedPlan == i;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedPlan = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: EdgeInsets.only(left: i > 0 ? 8 : 0),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primary.withOpacity(isDark ? 0.18 : 0.07)
                                : surfaceColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected ? AppColors.primary : dividerColor,
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (plan.savings != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  margin: const EdgeInsets.only(bottom: 6),
                                  decoration: BoxDecoration(
                                    color: plan.id == 'lifetime'
                                        ? AppColors.accent.withOpacity(0.15)
                                        : AppColors.success.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    plan.savings!,
                                    style: AppTypography.labelSmall.copyWith(
                                      color: plan.id == 'lifetime' ? AppColors.accentDark : AppColors.success,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              Text(plan.name, style: AppTypography.labelMedium),
                              const SizedBox(height: 4),
                              Text(
                                plan.price,
                                style: AppTypography.titleLarge.copyWith(
                                  color: selected ? AppColors.primary : null,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                plan.period,
                                style: AppTypography.labelSmall.copyWith(
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                ),
                              ),
                              if (plan.annualNote != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  plan.annualNote!,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 28),

                // ── Features ─────────────────────────────────────────────
                Text('Everything included', style: AppTypography.titleLarge),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: dividerColor),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _features.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: dividerColor),
                    itemBuilder: (context, i) {
                      final f = _features[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(isDark ? 0.15 : 0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(f.icon, color: AppColors.primary, size: 18),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(f.title, style: AppTypography.titleMedium),
                                  Text(
                                    f.description,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 28),

                // ── Social Proof ──────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: isDark
                        ? LinearGradient(colors: [AppColors.accent.withOpacity(0.12), AppColors.accent.withOpacity(0.06)])
                        : LinearGradient(colors: [AppColors.accent.withOpacity(0.08), AppColors.accent.withOpacity(0.03)]),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.accent.withOpacity(0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('⭐', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '"NutriSense Premium completely changed how I think about food. The AI coaching is incredibly accurate!"',
                              style: AppTypography.bodyMedium.copyWith(
                                fontStyle: FontStyle.italic,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '— Priya S., lost 8 kg in 3 months',
                              style: AppTypography.labelMedium.copyWith(
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── CTA ───────────────────────────────────────────────────
                ElevatedButton(
                  onPressed: _processing ? null : _subscribe,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  child: _processing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _selectedPlan == 2
                              ? 'Get Lifetime Access — ${_plans[2].price}'
                              : 'Start Premium — ${_plans[_selectedPlan].price}${_selectedPlan == 0 ? "/mo" : "/mo"}',
                          style: AppTypography.titleMedium.copyWith(
                              color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    _selectedPlan == 1
                        ? 'Billed as ₹2,149/year · Cancel anytime'
                        : _selectedPlan == 0
                            ? 'Billed monthly · Cancel anytime'
                            : 'One-time payment · No subscription',
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'Secure payment via Google Play · No hidden fees',
                    style: AppTypography.labelSmall.copyWith(
                      color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── FAQ ───────────────────────────────────────────────────
                const _FaqSection(),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Plan {
  final String id;
  final String name;
  final String price;
  final String period;
  final String? annualNote;
  final String? savings;
  const _Plan({required this.id, required this.name, required this.price, required this.period, this.annualNote, this.savings});
}

class _Feature {
  final IconData icon;
  final String title;
  final String description;
  const _Feature(this.icon, this.title, this.description);
}

class _FaqSection extends StatelessWidget {
  const _FaqSection();

  static const _faqs = [
    _Faq('Can I cancel anytime?', 'Yes — monthly and annual plans can be cancelled anytime from Google Play. No cancellation fees.'),
    _Faq('Is there a free trial?', 'All new users get 7 days of Premium features free. No card required.'),
    _Faq("What's included in the free plan?", 'The free plan includes 3 food scans per day, basic AI coaching, and standard analytics.'),
    _Faq('What happens to my data if I cancel?', 'Your logs, history, and progress are preserved. You simply revert to the free tier features.'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Common Questions', style: AppTypography.titleLarge),
        const SizedBox(height: 12),
        ..._faqs.map((faq) => _FaqItem(faq: faq, isDark: isDark)),
      ],
    );
  }
}

class _Faq {
  final String question;
  final String answer;
  const _Faq(this.question, this.answer);
}

class _FaqItem extends StatefulWidget {
  final _Faq faq;
  final bool isDark;
  const _FaqItem({required this.faq, required this.isDark});

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.isDark ? AppColors.darkDivider : AppColors.divider),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(widget.faq.question, style: AppTypography.titleMedium)),
                  Icon(
                    _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: widget.isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 8),
                Text(
                  widget.faq.answer,
                  style: AppTypography.bodySmall.copyWith(
                    color: widget.isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
