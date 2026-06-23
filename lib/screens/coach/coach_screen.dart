import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/food_log_provider.dart';
import '../../providers/tracking_providers.dart';
import '../../services/api_service.dart';

class CoachScreen extends ConsumerStatefulWidget {
  const CoachScreen({super.key});

  @override
  ConsumerState<CoachScreen> createState() => _CoachScreenState();
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;
  _ChatMessage(this.text, this.isUser) : time = DateTime.now();
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
      "Hi! I'm your AI nutrition coach. I've reviewed your recent intake and goals. "
      "Ask me anything or tap a suggestion below.",
      false,
    ));
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(text.trim(), true));
      _isTyping = true;
      _inputCtrl.clear();
    });
    _scrollToBottom();

    try {
      final api = ref.read(apiServiceProvider);
      final reply = await api.askCoach(text.trim());
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(reply, false));
        _isTyping = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage('Sorry, I couldn\'t process that: ${e.message}', false));
        _isTyping = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage('Something went wrong. Please try again.', false));
        _isTyping = false;
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 120), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  static const _suggestions = [
    ('🍳 Suggest breakfast', 'Suggest a healthy breakfast for my goal'),
    ('📊 How\'s my progress?', 'How is my weight and nutrition progress this week?'),
    ('💧 Water intake?', 'Am I drinking enough water for my goals?'),
    ('🥦 Protein sources', 'What are the best protein sources for my diet?'),
  ];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final streak = user?.currentStreak ?? 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            const Text('AI Coach'),
          ],
        ),
        actions: [
          if (streak > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      '$streak day streak',
                      style: AppTypography.labelMedium.copyWith(color: AppColors.accentDark),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Daily Review Banner ────────────────────────────────────────
          _DailyReviewCard(),

          // ── Messages ──────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == _messages.length) {
                  return const _AnimatedTypingBubble();
                }
                return _MessageBubble(
                  message: _messages[i],
                  isDark: isDark,
                  // Animate new messages sliding in
                  isNew: i == _messages.length - 1,
                );
              },
            ),
          ),

          // ── Suggestions ────────────────────────────────────────────────
          if (_messages.length <= 1)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _suggestions
                    .map((s) => _SuggestionChip(
                          label: s.$1,
                          onTap: () => _send(s.$2),
                          isDark: isDark,
                        ))
                    .toList(),
              ),
            ),

          // ── Input Bar ─────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surface,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.darkDivider : AppColors.divider,
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Ask your coach anything...',
                        filled: true,
                        fillColor: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        hintStyle: AppTypography.bodyMedium.copyWith(
                          color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                        ),
                      ),
                      onSubmitted: _isTyping ? null : _send,
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _isTyping ? null : () => _send(_inputCtrl.text),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: _isTyping
                            ? (isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant)
                            : AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: _isTyping
                            ? []
                            : [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                )
                              ],
                      ),
                      child: Icon(
                        Icons.arrow_upward_rounded,
                        color: _isTyping
                            ? (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)
                            : Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Daily Review Banner ──────────────────────────────────────────────────────

class _DailyReviewCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(todaySummaryProvider);
    final user = ref.watch(userProvider);
    final pct = user?.dailyCalorieTarget != null
        ? ((summary.totalCalories / user!.dailyCalorieTarget) * 100).clamp(0, 200).round()
        : 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF0D3B25), Color(0xFF0A2D1C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.insights_rounded, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today at a glance',
                  style: AppTypography.titleMedium.copyWith(color: Colors.white),
                ),
                Text(
                  '$pct% of calorie goal · ${summary.mealCount} meal${summary.mealCount == 1 ? "" : "s"} logged',
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

// ── Message Bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatefulWidget {
  final _ChatMessage message;
  final bool isDark;
  final bool isNew;

  const _MessageBubble({
    required this.message,
    required this.isDark,
    required this.isNew,
  });

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: Offset(widget.message.isUser ? 0.15 : -0.15, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    if (widget.isNew) {
      _ctrl.forward();
    } else {
      _ctrl.value = 1.0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.isUser;
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.76,
            ),
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isUser)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 10),
                        ),
                        const SizedBox(width: 6),
                        Text('AI Coach', style: AppTypography.labelSmall.copyWith(color: AppColors.primary)),
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppColors.primary
                        : (widget.isDark ? AppColors.darkSurface : AppColors.surface),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    border: isUser
                        ? null
                        : Border.all(
                            color: widget.isDark ? AppColors.darkDivider : AppColors.divider,
                          ),
                    boxShadow: [
                      BoxShadow(
                        color: isUser
                            ? AppColors.primary.withOpacity(0.2)
                            : Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    widget.message.text,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isUser
                          ? Colors.white
                          : (widget.isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Animated Typing Indicator ─────────────────────────────────────────────────

class _AnimatedTypingBubble extends StatefulWidget {
  const _AnimatedTypingBubble();

  @override
  State<_AnimatedTypingBubble> createState() => _AnimatedTypingBubbleState();
}

class _AnimatedTypingBubbleState extends State<_AnimatedTypingBubble>
    with TickerProviderStateMixin {
  late List<AnimationController> _dotCtrls;
  late List<Animation<double>> _dotAnims;

  @override
  void initState() {
    super.initState();
    _dotCtrls = List.generate(3, (i) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      );
      Future.delayed(Duration(milliseconds: i * 160), () {
        if (mounted) ctrl.repeat(reverse: true);
      });
      return ctrl;
    });
    _dotAnims = _dotCtrls
        .map((c) => Tween<double>(begin: 0.0, end: -6.0).animate(
              CurvedAnimation(parent: c, curve: Curves.easeInOut),
            ))
        .toList();
  }

  @override
  void dispose() {
    for (final c in _dotCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return AnimatedBuilder(
              animation: _dotAnims[i],
              builder: (_, __) => Transform.translate(
                offset: Offset(0, _dotAnims[i].value),
                child: Container(
                  width: 7,
                  height: 7,
                  margin: EdgeInsets.only(right: i < 2 ? 5 : 0),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ── Suggestion Chip ───────────────────────────────────────────────────────────

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  const _SuggestionChip({
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.darkDivider : AppColors.divider,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
