import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/user_provider.dart';
import '../../providers/food_log_provider.dart';
import '../../providers/tracking_providers.dart';
import '../../services/api_service.dart';
import '../../models/food_log_model.dart';
import '../../models/scan_result_model.dart';
import '../../models/tracking_models.dart';

// ══════════════════════════════════════════════════════════════════════════════
// Local data models
// ══════════════════════════════════════════════════════════════════════════════

class _LoggedAction {
  final String type;
  final String display;
  final String icon;
  final Color color;

  const _LoggedAction({
    required this.type,
    required this.display,
    required this.icon,
    required this.color,
  });

  factory _LoggedAction.fromJson(Map<String, dynamic> j) {
    final t = j['type'] as String? ?? '';
    return _LoggedAction(
      type:    t,
      display: j['display'] as String? ?? '',
      icon:    _icon(t),
      color:   _color(t),
    );
  }

  static String _icon(String t) => const {
    'water': '💧', 'food': '🍽️', 'weight': '⚖️',
    'exercise': '🏃', 'sleep': '😴',
  }[t] ?? '📊';

  static Color _color(String t) => {
    'water':    const Color(0xFF38BDF8),
    'food':     const Color(0xFFFB923C),
    'weight':   const Color(0xFFA78BFA),
    'exercise': const Color(0xFFF87171),
    'sleep':    const Color(0xFF818CF8),
  }[t] ?? const Color(0xFF64748B);
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;
  final List<_LoggedAction> actions;

  _ChatMessage(this.text, this.isUser, {this.actions = const []})
      : time = DateTime.now();

  factory _ChatMessage.fromHistory(Map<String, dynamic> j) => _ChatMessage(
    j['content'] as String? ?? '',
    j['role'] == 'user',
    actions: (j['actions'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(_LoggedAction.fromJson)
        .toList(),
  );
}

class _ChatSession {
  final String id;
  final String title;
  final String preview;
  final DateTime updatedAt;

  const _ChatSession({
    required this.id,
    required this.title,
    required this.preview,
    required this.updatedAt,
  });

  factory _ChatSession.fromJson(Map<String, dynamic> j) => _ChatSession(
    id:        j['id'] as String,
    title:     j['title'] as String? ?? 'New Chat',
    preview:   j['preview'] as String? ?? '',
    updatedAt: DateTime.tryParse(j['updated_at'] as String? ?? '') ?? DateTime.now(),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// CoachScreen
// ══════════════════════════════════════════════════════════════════════════════

class CoachScreen extends ConsumerStatefulWidget {
  const CoachScreen({super.key});

  @override
  ConsumerState<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends ConsumerState<CoachScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _inputCtrl   = TextEditingController();
  final _scrollCtrl  = ScrollController();

  List<_ChatMessage>  _messages        = [];
  List<_ChatSession>  _sessions        = [];
  String?             _activeSessionId;
  String              _activeChatTitle = 'AI Coach';
  bool                _isTyping        = false;
  bool                _loadingSessions = false;
  bool                _loadingHistory  = false;

  static const _suggestions = [
    ('💧 Log water',    'I just had 300ml of water'),
    ('🍽️ Log meal',     'I just had maggi for lunch'),
    ('📉 Log weight',   'I lost 1kg this week, now at 72kg'),
    ('🏃 Log workout',  'Just went for a 30 minute walk'),
    ('📊 My progress',  'How is my nutrition progress today?'),
    ('💡 Suggest meal', 'What should I eat for dinner tonight?'),
  ];

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _resetToWelcome();
    _loadSessions();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _resetToWelcome() {
    _messages = [
      _ChatMessage(
        "Hi! I'm your AI nutrition coach 👋\n\n"
        "Just tell me what you've eaten, drank, or done — "
        "I'll automatically log it for you and give you personalised guidance.",
        false,
      ),
    ];
  }

  // ── Session helpers ────────────────────────────────────────────────────────

  Future<void> _loadSessions() async {
    setState(() => _loadingSessions = true);
    try {
      final api  = ref.read(apiServiceProvider);
      final data = await api.getChatSessions();
      setState(() {
        _sessions = data.map(_ChatSession.fromJson).toList();
      });
    } catch (_) {}
    if (mounted) setState(() => _loadingSessions = false);
  }

  Future<void> _openSession(_ChatSession session) async {
    Navigator.of(context).pop(); // close drawer
    setState(() {
      _activeSessionId = session.id;
      _activeChatTitle = session.title;
      _loadingHistory  = true;
      _messages        = [];
    });
    try {
      final api  = ref.read(apiServiceProvider);
      final data = await api.getChatMessages(session.id);
      setState(() {
        _messages = data.map(_ChatMessage.fromHistory).toList();
      });
    } catch (_) {
      setState(() {
        _messages = [_ChatMessage("Couldn't load history. Start a new message!", false)];
      });
    }
    if (mounted) setState(() => _loadingHistory = false);
    _scrollToBottom();
  }

  Future<void> _newChat() async {
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
    setState(() {
      _activeSessionId = null;
      _activeChatTitle = 'AI Coach';
      _messages        = [];
    });
    _resetToWelcome();
  }

  // ── Send message ───────────────────────────────────────────────────────────

  Future<void> _send(String text) async {
    final msg = text.trim();
    if (msg.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(msg, true));
      _isTyping = true;
      _inputCtrl.clear();
    });
    _scrollToBottom();

    try {
      final api    = ref.read(apiServiceProvider);
      final result = await api.askCoach(msg, sessionId: _activeSessionId);
      if (!mounted) return;

      final reply   = result['reply']         as String? ?? '';
      final newSid  = result['session_id']    as String?;
      final newTitle= result['session_title'] as String? ?? 'AI Coach';
      final rawActs = result['actions']       as List<dynamic>? ?? [];
      final actions = rawActs
          .whereType<Map<String, dynamic>>()
          .map(_LoggedAction.fromJson)
          .toList();

      // Apply actions to local Riverpod providers for immediate UI updates
      _applyActionsLocally(rawActs);

      setState(() {
        _messages.add(_ChatMessage(reply, false, actions: actions));
        _isTyping        = false;
        _activeSessionId = newSid;
        _activeChatTitle = newTitle;
      });

      // Refresh sidebar sessions list
      _loadSessions();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage('Sorry, something went wrong: ${e.message}', false));
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

  /// Update local Riverpod providers after the backend logs the data,
  /// so the home screen / diary / water screen all refresh without re-fetching.
  void _applyActionsLocally(List<dynamic> rawActions) {
    final user = ref.read(userProvider);
    if (user == null) return;

    for (final raw in rawActions) {
      if (raw is! Map<String, dynamic>) continue;
      final type = raw['type'] as String?;

      switch (type) {
        case 'water':
          final liters = (raw['amount_liters'] as num?)?.toDouble() ?? 0;
          if (liters > 0) {
            ref
                .read(waterLogsProvider.notifier)
                .addWaterOptimistic(user.id, liters);
          }

        case 'food':
          final calories = (raw['calories'] as num?)?.toDouble() ?? 0;
          if (calories > 0) {
            ref.read(foodLogsProvider.notifier).addFromChat(
              FoodLogModel(
                id:              'chat_${DateTime.now().millisecondsSinceEpoch}',
                userId:          user.id,
                productName:     raw['name']      as String? ?? 'Unknown food',
                mealType:        raw['meal_type'] as String? ?? 'snack',
                servingSize:     1,
                servingUnit:     'serving',
                servingsConsumed: 1,
                nutritionInfo: NutritionInfo(
                  calories: calories,
                  protein:  (raw['protein'] as num?)?.toDouble() ?? 0,
                  carbs:    (raw['carbs']   as num?)?.toDouble() ?? 0,
                  fat:      (raw['fat']     as num?)?.toDouble() ?? 0,
                ),
                healthScore: 55,
                loggedAt:    DateTime.now(),
              ),
            );
          }

        case 'weight':
          final kg = (raw['weight_kg'] as num?)?.toDouble() ?? 0;
          if (kg > 0) {
            ref.read(weightLogsProvider.notifier).addLog(
              WeightLogModel(
                id:        'chat_${DateTime.now().millisecondsSinceEpoch}',
                userId:    user.id,
                weightKg:  kg,
                loggedAt:  DateTime.now(),
              ),
            );
          }
      }
    }
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

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final user    = ref.watch(userProvider);
    final streak  = user?.currentStreak ?? 0;

    return Scaffold(
      key:             _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      // ── History Drawer ──────────────────────────────────────────────────
      drawer: _HistoryDrawer(
        sessions:        _sessions,
        loading:         _loadingSessions,
        activeId:        _activeSessionId,
        isDark:          isDark,
        onNewChat:       _newChat,
        onSelectSession: _openSession,
      ),

      // ── App Bar ─────────────────────────────────────────────────────────
      appBar: AppBar(
        leading: IconButton(
          icon:    const Icon(Icons.menu_rounded),
          tooltip: 'Chat history',
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28, height: 28,
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape:    BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _activeChatTitle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          if (streak > 0)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color:        AppColors.accent.withOpacity(isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 3),
                    Text(
                      '$streak day',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.accentDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          IconButton(
            icon:    const Icon(Icons.add_rounded),
            tooltip: 'New chat',
            onPressed: _newChat,
          ),
        ],
      ),

      // ── Body ─────────────────────────────────────────────────────────────
      body: Column(
        children: [
          // Daily review banner
          _DailyReviewCard(),

          // Messages list
          Expanded(
            child: _loadingHistory
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding:    const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    itemCount:  _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (i == _messages.length) {
                        return const _AnimatedTypingBubble();
                      }
                      return _MessageBubble(
                        message: _messages[i],
                        isDark:  isDark,
                        isNew:   i == _messages.length - 1,
                      );
                    },
                  ),
          ),

          // Quick suggestions (only when conversation just started)
          if (_messages.length <= 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Wrap(
                spacing:    8,
                runSpacing: 8,
                children: _suggestions
                    .map((s) => _SuggestionChip(
                          label:  s.$1,
                          onTap:  () => _send(s.$2),
                          isDark: isDark,
                        ))
                    .toList(),
              ),
            ),

          // Input bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surface,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.darkDivider : AppColors.divider,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller:           _inputCtrl,
                      minLines:             1,
                      maxLines:             4,
                      textCapitalization:   TextCapitalization.sentences,
                      onSubmitted: _isTyping ? null : _send,
                      decoration: InputDecoration(
                        hintText:  'Tell me what you ate, drank, or did…',
                        filled:    true,
                        fillColor: isDark
                            ? AppColors.darkSurfaceVariant
                            : AppColors.surfaceVariant,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide:   BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                        hintStyle: AppTypography.bodyMedium.copyWith(
                          color: isDark
                              ? AppColors.darkTextHint
                              : AppColors.textHint,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _isTyping ? null : () => _send(_inputCtrl.text),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 46, height: 46,
                      decoration: BoxDecoration(
                        color: _isTyping
                            ? (isDark
                                ? AppColors.darkSurfaceVariant
                                : AppColors.surfaceVariant)
                            : AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: _isTyping
                            ? []
                            : [
                                BoxShadow(
                                  color:      AppColors.primary.withOpacity(0.35),
                                  blurRadius: 10,
                                  offset:     const Offset(0, 3),
                                ),
                              ],
                      ),
                      child: Icon(
                        Icons.arrow_upward_rounded,
                        color: _isTyping
                            ? (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary)
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

// ══════════════════════════════════════════════════════════════════════════════
// History Drawer
// ══════════════════════════════════════════════════════════════════════════════

class _HistoryDrawer extends StatelessWidget {
  final List<_ChatSession> sessions;
  final bool              loading;
  final String?           activeId;
  final bool              isDark;
  final VoidCallback               onNewChat;
  final void Function(_ChatSession) onSelectSession;

  const _HistoryDrawer({
    required this.sessions,
    required this.loading,
    required this.activeId,
    required this.isDark,
    required this.onNewChat,
    required this.onSelectSession,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    List<_ChatSession> group(Duration min, Duration? max) => sessions.where((s) {
      final age = now.difference(s.updatedAt);
      return age >= min && (max == null || age < max);
    }).toList();

    final today     = group(Duration.zero,               const Duration(hours: 24));
    final yesterday = group(const Duration(hours: 24),   const Duration(hours: 48));
    final thisWeek  = group(const Duration(hours: 48),   const Duration(days: 7));
    final older     = group(const Duration(days: 7),     null);

    return Drawer(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
      child: Column(
        children: [
          // Header
          DrawerHeader(
            decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color:        Colors.white.withOpacity(0.2),
                    shape:        BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(height: 10),
                const Text(
                  'AI Coach',
                  style: TextStyle(
                    color:      Colors.white,
                    fontSize:   20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Text(
                  'Conversation History',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),

          // New Chat button
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: ElevatedButton.icon(
              onPressed: onNewChat,
              icon:  const Icon(Icons.add_rounded, size: 18),
              label: const Text('New Chat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize:     const Size.fromHeight(40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          // Sessions list
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : sessions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 40,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No chats yet.\nStart a conversation!',
                              textAlign: TextAlign.center,
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          if (today.isNotEmpty) ...[
                            _GroupLabel('Today', isDark: isDark),
                            ...today.map((s) => _SessionTile(
                                  session:  s,
                                  isActive: s.id == activeId,
                                  isDark:   isDark,
                                  onTap:    () => onSelectSession(s),
                                )),
                          ],
                          if (yesterday.isNotEmpty) ...[
                            _GroupLabel('Yesterday', isDark: isDark),
                            ...yesterday.map((s) => _SessionTile(
                                  session:  s,
                                  isActive: s.id == activeId,
                                  isDark:   isDark,
                                  onTap:    () => onSelectSession(s),
                                )),
                          ],
                          if (thisWeek.isNotEmpty) ...[
                            _GroupLabel('This Week', isDark: isDark),
                            ...thisWeek.map((s) => _SessionTile(
                                  session:  s,
                                  isActive: s.id == activeId,
                                  isDark:   isDark,
                                  onTap:    () => onSelectSession(s),
                                )),
                          ],
                          if (older.isNotEmpty) ...[
                            _GroupLabel('Older', isDark: isDark),
                            ...older.map((s) => _SessionTile(
                                  session:  s,
                                  isActive: s.id == activeId,
                                  isDark:   isDark,
                                  onTap:    () => onSelectSession(s),
                                )),
                          ],
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  final String label;
  final bool   isDark;
  const _GroupLabel(this.label, {required this.isDark});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
    child: Text(
      label.toUpperCase(),
      style: AppTypography.labelSmall.copyWith(
        color:           isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        letterSpacing:   0.8,
        fontWeight:      FontWeight.w600,
      ),
    ),
  );
}

class _SessionTile extends StatelessWidget {
  final _ChatSession session;
  final bool         isActive;
  final bool         isDark;
  final VoidCallback onTap;

  const _SessionTile({
    required this.session,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    onTap:            onTap,
    selected:         isActive,
    selectedTileColor: AppColors.primary.withOpacity(0.1),
    leading: Icon(
      Icons.chat_bubble_outline_rounded,
      size:  18,
      color: isActive
          ? AppColors.primary
          : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
    ),
    title: Text(
      session.title,
      maxLines:  1,
      overflow:  TextOverflow.ellipsis,
      style: AppTypography.bodyMedium.copyWith(
        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
        color: isActive
            ? AppColors.primary
            : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
      ),
    ),
    subtitle: session.preview.isNotEmpty
        ? Text(
            session.preview,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          )
        : null,
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// Message Bubble + Action Badges
// ══════════════════════════════════════════════════════════════════════════════

class _MessageBubble extends StatefulWidget {
  final _ChatMessage message;
  final bool         isDark;
  final bool         isNew;

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
  late final AnimationController _ctrl;
  late final Animation<double>   _fade;
  late final Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 320));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: Offset(widget.message.isUser ? 0.15 : -0.15, 0.08),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    if (widget.isNew) _ctrl.forward();
    else              _ctrl.value = 1.0;
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.isUser;
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin:      const EdgeInsets.only(bottom: 10),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Coach avatar label
                if (!isUser)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 20, height: 20,
                          decoration: const BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape:    BoxShape.circle,
                          ),
                          child: const Icon(Icons.auto_awesome,
                              color: Colors.white, size: 10),
                        ),
                        const SizedBox(width: 6),
                        Text('AI Coach',
                            style: AppTypography.labelSmall
                                .copyWith(color: AppColors.primary)),
                      ],
                    ),
                  ),

                // Bubble
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppColors.primary
                        : (widget.isDark
                            ? AppColors.darkSurface
                            : AppColors.surface),
                    borderRadius: BorderRadius.only(
                      topLeft:     const Radius.circular(18),
                      topRight:    const Radius.circular(18),
                      bottomLeft:  Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    border: isUser
                        ? null
                        : Border.all(
                            color: widget.isDark
                                ? AppColors.darkDivider
                                : AppColors.divider,
                          ),
                    boxShadow: [
                      BoxShadow(
                        color: isUser
                            ? AppColors.primary.withOpacity(0.2)
                            : Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset:     const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    widget.message.text,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isUser
                          ? Colors.white
                          : (widget.isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary),
                      height: 1.45,
                    ),
                  ),
                ),

                // Auto-logged action badges
                if (widget.message.actions.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing:    6,
                    runSpacing: 5,
                    children: widget.message.actions
                        .map((a) => _ActionBadge(action: a, isNew: widget.isNew))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Action Badge (pop-in animation) ──────────────────────────────────────────

class _ActionBadge extends StatefulWidget {
  final _LoggedAction action;
  final bool          isNew;
  const _ActionBadge({required this.action, required this.isNew});

  @override
  State<_ActionBadge> createState() => _ActionBadgeState();
}

class _ActionBadgeState extends State<_ActionBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);

    if (widget.isNew) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _ctrl.forward();
      });
    } else {
      _ctrl.value = 1.0;
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => ScaleTransition(
    scale: _scale,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color:        widget.action.color.withOpacity(0.1),
        border:       Border.all(color: widget.action.color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.action.icon,
              style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 5),
          Text(
            widget.action.display,
            style: TextStyle(
              color:      widget.action.color,
              fontSize:   12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color:        widget.action.color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'LOGGED',
              style: TextStyle(
                color:       Colors.white,
                fontSize:    9,
                fontWeight:  FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// Daily Review Banner
// ══════════════════════════════════════════════════════════════════════════════

class _DailyReviewCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(todaySummaryProvider);
    final user    = ref.watch(userProvider);
    final pct     = user?.dailyCalorieTarget != null
        ? ((summary.totalCalories / user!.dailyCalorieTarget) * 100)
            .clamp(0, 200)
            .round()
        : 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin:  const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF0D3B25), Color(0xFF0A2D1C)],
                begin:  Alignment.topLeft,
                end:    Alignment.bottomRight,
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
                Text('Today at a glance',
                    style: AppTypography.titleMedium
                        .copyWith(color: Colors.white)),
                Text(
                  '$pct% of calorie goal · '
                  '${summary.mealCount} meal${summary.mealCount == 1 ? "" : "s"} logged',
                  style: AppTypography.bodySmall
                      .copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Typing indicator
// ══════════════════════════════════════════════════════════════════════════════

class _AnimatedTypingBubble extends StatefulWidget {
  const _AnimatedTypingBubble();

  @override
  State<_AnimatedTypingBubble> createState() => _AnimatedTypingBubbleState();
}

class _AnimatedTypingBubbleState extends State<_AnimatedTypingBubble>
    with TickerProviderStateMixin {
  late final List<AnimationController> _ctrls;
  late final List<Animation<double>>   _anims;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(3, (i) {
      final c = AnimationController(
          vsync: this, duration: const Duration(milliseconds: 500));
      Future.delayed(Duration(milliseconds: i * 160), () {
        if (mounted) c.repeat(reverse: true);
      });
      return c;
    });
    _anims = _ctrls
        .map((c) => Tween<double>(begin: 0.0, end: -6.0)
            .animate(CurvedAnimation(parent: c, curve: Curves.easeInOut)))
        .toList();
  }

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin:  const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: const BorderRadius.only(
            topLeft:     Radius.circular(18),
            topRight:    Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft:  Radius.circular(4),
          ),
          border: Border.all(
              color: isDark ? AppColors.darkDivider : AppColors.divider),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset:     const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) => AnimatedBuilder(
            animation: _anims[i],
            builder: (_, __) => Transform.translate(
              offset: Offset(0, _anims[i].value),
              child: Container(
                width:  7, height: 7,
                margin: EdgeInsets.only(right: i < 2 ? 5 : 0),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          )),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Suggestion Chip
// ══════════════════════════════════════════════════════════════════════════════

class _SuggestionChip extends StatelessWidget {
  final String       label;
  final VoidCallback onTap;
  final bool         isDark;

  const _SuggestionChip({
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color:        isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(
            color: isDark ? AppColors.darkDivider : AppColors.divider),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset:     const Offset(0, 1),
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
