import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/user_provider.dart';
import '../../providers/food_log_provider.dart';
import '../../providers/tracking_providers.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class CoachScreen extends ConsumerStatefulWidget {
  const CoachScreen({super.key});

  @override
  ConsumerState<CoachScreen> createState() => _CoachScreenState();
}

class _ChatMessage {
  final String text;
  final bool isUser;
  _ChatMessage(this.text, this.isUser);
}

class _CoachScreenState extends ConsumerState<CoachScreen> {
  final List<_ChatMessage> _messages = [];
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _messages.add(_ChatMessage(
      "Hi! I'm your AI nutrition coach. I've reviewed your recent intake, weight trend and activity. Ask me anything, or tap a suggestion below.",
      false,
    ));
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(text, true));
      _isTyping = true;
      _inputCtrl.clear();
    });
    _scrollToBottom();

    try {
      final api = ref.read(apiServiceProvider);
      final reply = await api.askCoach(text);
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(reply, false));
        _isTyping = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(
          "Sorry, I couldn't process that: ${e.message}",
          false,
        ));
        _isTyping = false;
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final streak = user?.currentStreak ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('AI Coach'),
        actions: [
          if (streak > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Chip(
                avatar: const Text('🔥', style: TextStyle(fontSize: 14)),
                label: Text('$streak day streak'),
                backgroundColor: AppColors.accent.withOpacity(0.15),
                labelStyle: AppTypography.labelMedium.copyWith(color: AppColors.accentDark),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Daily review card
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: _DailyReviewCard(),
          ),

          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == _messages.length) {
                  return const _TypingIndicator();
                }
                return _MessageBubble(message: _messages[i]);
              },
            ),
          ),

          // Suggestion chips
          if (_messages.length <= 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SuggestionChip(label: 'Suggest a meal', onTap: () => _send('Suggest a meal for dinner')),
                  _SuggestionChip(label: 'How\'s my progress?', onTap: () => _send('How is my weight progress?')),
                  _SuggestionChip(label: 'Should I drink more water?', onTap: () => _send('Tell me about water intake')),
                ],
              ),
            ),

          // Input bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Ask your coach anything...',
                    ),
                    onSubmitted: _send,
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _send(_inputCtrl.text),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyReviewCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(todaySummaryProvider);
    final user = ref.watch(userProvider);
    final pct = ((summary.totalCalories / (user?.dailyCalorieTarget ?? 2000)) * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.insights_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daily Review', style: AppTypography.titleMedium.copyWith(color: Colors.white)),
                Text(
                  "You're at $pct% of your calorie goal · ${summary.mealCount} meals logged",
                  style: AppTypography.bodySmall.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: message.isUser ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: message.isUser ? null : Border.all(color: AppColors.divider),
        ),
        child: Text(
          message.text,
          style: AppTypography.bodyMedium.copyWith(
            color: message.isUser ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: const SizedBox(
          width: 30,
          child: Text('•••', style: TextStyle(color: AppColors.textSecondary, letterSpacing: 2)),
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SuggestionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: AppTypography.labelMedium.copyWith(color: AppColors.primary)),
      ),
    );
  }
}
