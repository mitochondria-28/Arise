import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/app_exception.dart';
import '../../core/network/api_client.dart';
import '../../shared/widgets/arise_button.dart';
import 'ai_provider.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class ConversationSummary {
  final String id;
  final String title;
  final DateTime updatedAt;

  const ConversationSummary({
    required this.id,
    required this.title,
    required this.updatedAt,
  });

  factory ConversationSummary.fromJson(Map<String, dynamic> j) =>
      ConversationSummary(
        id: j['id'] as String,
        title: j['title'] as String,
        updatedAt: DateTime.parse(j['updated_at'] as String),
      );
}

class ChatMessage {
  final String id;
  final String role;
  final String content;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: j['id'] as String,
        role: j['role'] as String,
        content: j['content'] as String,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

class WeeklyReview {
  final String id;
  final String weekStart;
  final String weekEnd;
  final String content;
  final String modelUsed;
  final DateTime createdAt;

  const WeeklyReview({
    required this.id,
    required this.weekStart,
    required this.weekEnd,
    required this.content,
    required this.modelUsed,
    required this.createdAt,
  });

  factory WeeklyReview.fromJson(Map<String, dynamic> j) => WeeklyReview(
        id: j['id'] as String,
        weekStart: j['week_start'] as String,
        weekEnd: j['week_end'] as String,
        content: j['content'] as String,
        modelUsed: j['model_used'] as String,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

// ── Chat Tab ──────────────────────────────────────────────────────────────────

class _ChatTab extends ConsumerStatefulWidget {
  const _ChatTab();

  @override
  ConsumerState<_ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends ConsumerState<_ChatTab> {
  List<ConversationSummary>? _conversations;
  bool _loadingConvs = true;
  String? _activeConvId;
  List<ChatMessage> _messages = [];
  bool _loadingMsgs = false;
  bool _sending = false;
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    try {
      final res = await ref.read(dioProvider).get<List<dynamic>>('/coach/conversations');
      if (mounted) {
        setState(() {
          _conversations = res.data!
              .map((e) => ConversationSummary.fromJson(e as Map<String, dynamic>))
              .toList();
          _loadingConvs = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingConvs = false);
    }
  }

  Future<void> _newConversation() async {
    try {
      final res = await ref
          .read(dioProvider)
          .post<Map<String, dynamic>>('/coach/conversations', data: {'title': 'New Conversation'});
      final conv = ConversationSummary.fromJson(res.data!);
      setState(() {
        _conversations = [conv, ...?_conversations];
        _activeConvId = conv.id;
        _messages = [];
      });
    } catch (_) {}
  }

  Future<void> _selectConversation(String convId) async {
    setState(() {
      _activeConvId = convId;
      _loadingMsgs = true;
      _messages = [];
    });
    try {
      final res = await ref
          .read(dioProvider)
          .get<Map<String, dynamic>>('/coach/conversations/$convId');
      final data = res.data!;
      if (mounted) {
        setState(() {
          _messages = (data['messages'] as List)
              .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
              .toList();
          _loadingMsgs = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) setState(() => _loadingMsgs = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _sending || _activeConvId == null) return;
    _inputCtrl.clear();
    final userMsg = ChatMessage(
      id: UniqueKey().toString(),
      role: 'user',
      content: text,
      createdAt: DateTime.now(),
    );
    setState(() {
      _messages = [..._messages, userMsg];
      _sending = true;
    });
    _scrollToBottom();
    try {
      final res = await ref.read(dioProvider).post<Map<String, dynamic>>(
        '/coach/conversations/${_activeConvId!}/messages',
        data: {'content': text},
      );
      final aiMsg = ChatMessage.fromJson(res.data!);
      if (mounted) {
        setState(() {
          _messages = [..._messages, aiMsg];
          _sending = false;
        });
        _scrollToBottom();
        _loadConversations(); // refresh titles
      }
    } catch (_) {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    final cs = Theme.of(context).colorScheme;

    if (_loadingConvs) {
      return const Center(child: CircularProgressIndicator());
    }

    final convs = _conversations ?? [];

    return Column(
      children: [
        // Conversations list
        if (_activeConvId == null) ...[
          Padding(
            padding: const EdgeInsets.all(16),
            child: AriseButton(
              label: 'New Chat',
              onPressed: _newConversation,
              icon: const Icon(Icons.add, size: 18),
            ),
          ),
          if (convs.isEmpty)
            Center(
              child: Text(
                'No conversations yet',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4)),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: convs.length,
                itemBuilder: (_, i) {
                  final c = convs[i];
                  return ListTile(
                    leading: Icon(Icons.chat_bubble_outline, color: cs.primary, size: 20),
                    title: Text(c.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14)),
                    subtitle: Text(
                      _fmtDate(c.updatedAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                    onTap: () => _selectConversation(c.id),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  );
                },
              ),
            ),
        ] else ...[
          // Back button row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3))),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 16),
                  onPressed: () => setState(() {
                    _activeConvId = null;
                    _messages = [];
                  }),
                ),
                Expanded(
                  child: Text(
                    convs
                        .firstWhere((c) => c.id == _activeConvId,
                            orElse: () => ConversationSummary(
                                id: '', title: 'Chat', updatedAt: DateTime.now()))
                        .title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_comment_outlined, size: 18),
                  onPressed: _newConversation,
                  tooltip: 'New chat',
                ),
              ],
            ),
          ),
          // Messages
          Expanded(
            child: _loadingMsgs
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length + (_sending ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (_sending && i == _messages.length) {
                        return _TypingBubble(cs: cs);
                      }
                      return _MessageBubble(msg: _messages[i], cs: cs);
                    },
                  ),
          ),
          // Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3))),
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
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Ask your coach anything…',
                        hintStyle: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.35), fontSize: 14),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                              color: cs.outlineVariant.withValues(alpha: 0.5)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                              color: cs.outlineVariant.withValues(alpha: 0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: cs.primary, width: 1.5),
                        ),
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: _sending ? null : _sendMessage,
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _fmtDate(DateTime dt) {
    final d = dt.toLocal();
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month]} ${d.day}';
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage msg;
  final ColorScheme cs;
  const _MessageBubble({required this.msg, required this.cs});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: cs.primary.withValues(alpha: 0.12),
              child: Icon(Icons.smart_toy_outlined, size: 14, color: cs.primary),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? cs.primary : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Text(
                msg.content,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isUser ? Colors.white : cs.onSurface.withValues(alpha: 0.9),
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 14,
              backgroundColor: cs.primary.withValues(alpha: 0.12),
              child: Icon(Icons.person_outline, size: 14, color: cs.primary),
            ),
          ],
        ],
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  final ColorScheme cs;
  const _TypingBubble({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: cs.primary.withValues(alpha: 0.12),
            child: Icon(Icons.smart_toy_outlined, size: 14, color: cs.primary),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Text(
              'Thinking…',
              style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurface.withValues(alpha: 0.45),
                  fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Weekly Review Tab ─────────────────────────────────────────────────────────

class _WeeklyReviewTab extends ConsumerStatefulWidget {
  const _WeeklyReviewTab();

  @override
  ConsumerState<_WeeklyReviewTab> createState() => _WeeklyReviewTabState();
}

class _WeeklyReviewTabState extends ConsumerState<_WeeklyReviewTab> {
  List<WeeklyReview>? _reviews;
  bool _loading = true;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      final res =
          await ref.read(dioProvider).get<List<dynamic>>('/coach/weekly-reviews');
      if (mounted) {
        setState(() {
          _reviews = res.data!
              .map((e) => WeeklyReview.fromJson(e as Map<String, dynamic>))
              .toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _generate() async {
    setState(() => _generating = true);
    try {
      final res = await ref
          .read(dioProvider)
          .post<Map<String, dynamic>>('/coach/weekly-reviews/generate');
      final review = WeeklyReview.fromJson(res.data!);
      if (mounted) {
        setState(() {
          final existing = _reviews ?? [];
          final idx = existing.indexWhere((r) => r.id == review.id);
          if (idx >= 0) {
            existing[idx] = review;
            _reviews = [...existing];
          } else {
            _reviews = [review, ...existing];
          }
          _generating = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final reviews = _reviews ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AriseButton(
          label: _generating ? 'Generating…' : "Generate This Week's Review",
          onPressed: _generating ? null : _generate,
          icon: _generating
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.refresh_rounded, size: 18),
        ),
        const SizedBox(height: 20),
        if (reviews.isEmpty)
          Center(
            child: Text(
              'No weekly reviews yet — tap Generate to create your first one.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: cs.onSurface.withValues(alpha: 0.4), fontSize: 13),
            ),
          )
        else
          ...reviews.map((r) => _ReviewCard(review: r, cs: cs)),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final WeeklyReview review;
  final ColorScheme cs;
  const _ReviewCard({required this.review, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 14, color: cs.primary),
                const SizedBox(width: 6),
                Text(
                  '${review.weekStart} → ${review.weekEnd}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              review.content,
              style: TextStyle(
                  fontSize: 13.5,
                  height: 1.65,
                  color: cs.onSurface.withValues(alpha: 0.85)),
            ),
            const SizedBox(height: 10),
            Text(
              review.modelUsed,
              style: TextStyle(
                  fontSize: 11, color: cs.onSurface.withValues(alpha: 0.35)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Growth Report Tab ─────────────────────────────────────────────────────────

class _GrowthReportTab extends ConsumerWidget {
  const _GrowthReportTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(growthReportProvider);
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) {
            final msg = e is ServerException && e.message.contains('503')
                ? 'AI Coach requires a Gemini API key on the server.'
                : e is AppException
                    ? e.message
                    : 'Something went wrong.';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AriseButton(
                  label: 'Generate Growth Report',
                  onPressed: () => ref.read(growthReportProvider.notifier).generate(),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cs.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.error.withValues(alpha: 0.2)),
                  ),
                  child: Text(msg,
                      style: TextStyle(color: cs.error, fontSize: 13)),
                ),
              ],
            );
          },
          data: (report) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AriseButton(
                label: report == null ? 'Generate Growth Report' : 'Regenerate',
                onPressed: () => ref.read(growthReportProvider.notifier).generate(),
                icon: Icon(
                  report == null
                      ? Icons.auto_awesome_outlined
                      : Icons.refresh_rounded,
                  size: 18,
                ),
              ),
              if (report != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: cs.primary.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.auto_awesome_outlined,
                                color: cs.primary, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Growth Report',
                                  style: Theme.of(context).textTheme.titleSmall),
                              Text(
                                report.modelUsed,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: cs.onSurface.withValues(alpha: 0.4)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        report.content,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: cs.onSurface.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ── Main Screen ───────────────────────────────────────────────────────────────

class AICoachScreen extends StatefulWidget {
  const AICoachScreen({super.key});

  @override
  State<AICoachScreen> createState() => _AICoachScreenState();
}

class _AICoachScreenState extends State<AICoachScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Coach'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(icon: Icon(Icons.chat_bubble_outline, size: 18), text: 'Chat'),
            Tab(icon: Icon(Icons.calendar_today_outlined, size: 18), text: 'Weekly'),
            Tab(icon: Icon(Icons.auto_awesome_outlined, size: 18), text: 'Report'),
          ],
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurface.withValues(alpha: 0.4),
          indicatorColor: cs.primary,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _ChatTab(),
          _WeeklyReviewTab(),
          _GrowthReportTab(),
        ],
      ),
    );
  }
}
