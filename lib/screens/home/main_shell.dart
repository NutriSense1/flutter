import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/router/app_router.dart';
import '../../providers/auth_provider.dart';

class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});
  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseScale;
  late Animation<double> _pulseOpacity;

  static const _tabs = [AppRoutes.home, AppRoutes.diary, AppRoutes.coach, AppRoutes.analytics];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    _pulseScale   = Tween<double>(begin: 1.0, end: 1.22).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _pulseOpacity = Tween<double>(begin: 0.35, end: 0.0).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeIn));

    final notifications = ref.read(notificationServiceProvider);
    notifications.onForegroundMessage = (message) {
      final title = message.notification?.title;
      final body  = message.notification?.body;
      if (title == null || !mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(body != null ? '$title — $body' : title),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    };
    notifications.initAfterSignIn();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  int _currentIndex(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final i    = _tabs.indexWhere((t) => path.startsWith(t));
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    final idx = _currentIndex(context);
    // Only show the scan FAB on Home (0) and Diary (1) — it's irrelevant and
    // obstructs content on Coach (2) and Stats (3).
    final showFab = idx == 0 || idx == 1;
    return Scaffold(
      body: widget.child,
      floatingActionButton: showFab
          ? _PremiumFAB(pulseScale: _pulseScale, pulseOpacity: _pulseOpacity)
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _PremiumNavBar(
        currentIndex: idx,
        onTap: (i) {
          HapticFeedback.selectionClick();
          context.go(_tabs[i]);
        },
      ),
    );
  }
}

// ─── Nav Bar ─────────────────────────────────────────────────────────────────

class _PremiumNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    _NavItemData(icon: Icons.home_outlined,      activeIcon: Icons.home_rounded,       label: 'Home'),
    _NavItemData(icon: Icons.menu_book_outlined,  activeIcon: Icons.menu_book_rounded,  label: 'Diary'),
    _NavItemData(icon: Icons.psychology_outlined, activeIcon: Icons.psychology_rounded, label: 'Coach'),
    _NavItemData(icon: Icons.bar_chart_outlined,  activeIcon: Icons.bar_chart_rounded,  label: 'Stats'),
  ];

  const _PremiumNavBar({required this.currentIndex, required this.onTap});

  bool get _showFabGap => currentIndex == 0 || currentIndex == 1;

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final navBg    = isDark ? AppColors.darkSurface : AppColors.surface;
    final inactive = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: navBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.07),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: _showFabGap
              // Home & Diary: split row with centre gap for the FAB
              ? Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [0, 1].map((i) => Expanded(
                          child: _NavItem(data: _items[i], isActive: currentIndex == i, onTap: () => onTap(i), inactiveColor: inactive),
                        )).toList(),
                      ),
                    ),
                    const SizedBox(width: 72),
                    Expanded(
                      child: Row(
                        children: [2, 3].map((i) => Expanded(
                          child: _NavItem(data: _items[i], isActive: currentIndex == i, onTap: () => onTap(i), inactiveColor: inactive),
                        )).toList(),
                      ),
                    ),
                  ],
                )
              // Coach & Stats: evenly spread all 4 tabs, no gap
              : Row(
                  children: List.generate(4, (i) => Expanded(
                    child: _NavItem(data: _items[i], isActive: currentIndex == i, onTap: () => onTap(i), inactiveColor: inactive),
                  )),
                ),
        ),
      ),
    );
  }
}

@immutable
class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItemData({required this.icon, required this.activeIcon, required this.label});
}

class _NavItem extends StatelessWidget {
  final _NavItemData data;
  final bool isActive;
  final VoidCallback onTap;
  final Color inactiveColor;
  const _NavItem({required this.data, required this.isActive, required this.onTap, required this.inactiveColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            width: isActive ? 52 : 36,
            height: 32,
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary.withOpacity(0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  isActive ? data.activeIcon : data.icon,
                  key: ValueKey(isActive),
                  size: 22,
                  color: isActive ? AppColors.primary : inactiveColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? AppColors.primary : inactiveColor,
            ),
            child: Text(data.label),
          ),
        ],
      ),
    );
  }
}

// ─── FAB ─────────────────────────────────────────────────────────────────────

class _PremiumFAB extends StatelessWidget {
  final Animation<double> pulseScale;
  final Animation<double> pulseOpacity;
  const _PremiumFAB({required this.pulseScale, required this.pulseOpacity});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { HapticFeedback.mediumImpact(); context.push(AppRoutes.scanner); },
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: pulseScale,
            builder: (_, __) => Transform.scale(
              scale: pulseScale.value,
              child: Container(
                width: 64, height: 64,
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary.withOpacity(pulseOpacity.value)),
              ),
            ),
          ),
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF34D47A), Color(0xFF0F9D58)],
              ),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.45), blurRadius: 20, spreadRadius: 1, offset: const Offset(0, 6))],
            ),
            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 26),
          ),
        ],
      ),
    );
  }
}
