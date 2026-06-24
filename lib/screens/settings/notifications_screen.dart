import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});
  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  Map<String, dynamic>? _prefs;
  List<dynamic>? _feed;
  bool _loading = true;
  String? _error;
  bool _sendingTest = false;
  String? _testResult;

  static const _categories = [
    (key: 'meal_reminders',    label: 'Meal reminders',   desc: 'Nudges to log meals you haven\'t recorded yet'),
    (key: 'achievement_alerts', label: 'Achievements',    desc: 'When you unlock a badge or hit a milestone'),
    (key: 'coach_tips',        label: 'AI coach tips',    desc: 'Daily reviews and personalized nutrition tips'),
    (key: 'streak_warnings',   label: 'Streak warnings',  desc: 'Heads up before your logging streak resets'),
  ];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final api     = ref.read(apiServiceProvider);
      final results = await Future.wait([api.getNotificationPreferences(), api.getNotifications(limit: 20)]);
      setState(() {
        _prefs = results[0] as Map<String, dynamic>;
        _feed  = results[1] as List<dynamic>;
      });
    } catch (_) {
      setState(() => _error = 'Couldn\'t load notification settings.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _togglePref(String key, bool value) async {
    setState(() => _prefs![key] = value);
    try {
      await ref.read(apiServiceProvider).updateNotificationPreferences({key: value});
    } catch (_) {
      if (mounted) setState(() => _prefs![key] = !value);
    }
  }

  Future<void> _sendTest() async {
    setState(() { _sendingTest = true; _testResult = null; });
    try {
      final result = await ref.read(apiServiceProvider).sendTestPush();
      setState(() {
        _testResult = result['status'] == 'no_device_registered'
            ? (result['message'] as String? ?? 'No device registered yet.')
            : 'Test notification sent — check your device.';
      });
    } on ApiException catch (e) {
      setState(() => _testResult = e.message);
    } catch (_) {
      setState(() => _testResult = 'Couldn\'t send a test notification.');
    } finally {
      if (mounted) setState(() => _sendingTest = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final hintTxt = isDark ? AppColors.darkTextHint : AppColors.textHint;
    final secTxt  = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final iconBg  = isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Notifications')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, style: AppTypography.bodyMedium, textAlign: TextAlign.center)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                    children: [
                      Text('Push categories', style: AppTypography.titleMedium),
                      const SizedBox(height: 8),
                      ...(_categories.map((c) => SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(c.label, style: AppTypography.bodyLarge),
                            subtitle: Text(c.desc, style: AppTypography.bodySmall.copyWith(color: hintTxt)),
                            value: (_prefs?[c.key] as bool?) ?? true,
                            activeColor: AppColors.primary,
                            onChanged: (v) => _togglePref(c.key, v),
                          ))),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _sendingTest ? null : _sendTest,
                        icon: _sendingTest
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.notifications_active_outlined, size: 18),
                        label: const Text('Send test notification'),
                      ),
                      if (_testResult != null) ...[
                        const SizedBox(height: 10),
                        Text(_testResult!, style: AppTypography.bodySmall.copyWith(color: secTxt)),
                      ],
                      const SizedBox(height: 28),
                      Text('Recent', style: AppTypography.titleMedium),
                      const SizedBox(height: 8),
                      if (_feed == null || _feed!.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text('Nothing here yet.', style: AppTypography.bodyMedium.copyWith(color: hintTxt)),
                        )
                      else
                        ...(_feed!.map((n) => _FeedTile(notification: n as Map<String, dynamic>, iconBg: iconBg, secTxt: secTxt))),
                    ],
                  ),
                ),
    );
  }
}

class _FeedTile extends StatelessWidget {
  final Map<String, dynamic> notification;
  final Color iconBg;
  final Color secTxt;
  const _FeedTile({required this.notification, required this.iconBg, required this.secTxt});

  IconData _iconFor(String type) {
    switch (type) {
      case 'achievement':    return Icons.emoji_events_outlined;
      case 'reminder':       return Icons.alarm;
      case 'ai_insight':     return Icons.psychology_outlined;
      case 'streak_warning': return Icons.local_fire_department_outlined;
      default:               return Icons.notifications_none_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRead = notification['is_read'] == true;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(_iconFor(notification['type'] as String? ?? ''), size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notification['title'] as String? ?? '',
                    style: AppTypography.bodyMedium.copyWith(fontWeight: isRead ? FontWeight.w400 : FontWeight.w700)),
                Text(notification['body'] as String? ?? '',
                    style: AppTypography.bodySmall.copyWith(color: secTxt)),
              ],
            ),
          ),
          if (!isRead)
            Container(
              margin: const EdgeInsets.only(top: 4, left: 6),
              width: 8, height: 8,
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }
}
