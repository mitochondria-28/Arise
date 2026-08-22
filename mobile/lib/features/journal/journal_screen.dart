import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/errors/app_exception.dart';
import '../../core/models/journal.dart';
import '../../shared/widgets/arise_card.dart';
import '../../shared/widgets/arise_button.dart';
import '../../shared/widgets/error_view.dart';
import 'journal_provider.dart';

// ── Mood helpers ───────────────────────────────────────────────────────────────

const _moods = [
  (value: 1, emoji: '😔', label: 'Low'),
  (value: 2, emoji: '😕', label: 'Below average'),
  (value: 3, emoji: '😐', label: 'Neutral'),
  (value: 4, emoji: '🙂', label: 'Good'),
  (value: 5, emoji: '😄', label: 'Great'),
];

// ── Screen ─────────────────────────────────────────────────────────────────────

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  JournalEntry? _todayEntry;
  bool _todayLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadToday();
  }

  Future<void> _loadToday() async {
    try {
      final entry = await ref.read(journalProvider.notifier).fetchToday();
      if (mounted) setState(() { _todayEntry = entry; _todayLoaded = true; });
    } catch (_) {
      if (mounted) setState(() => _todayLoaded = true);
    }
  }

  void _showEditor() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditorSheet(
        initial: _todayEntry,
        onSaved: (entry) {
          setState(() => _todayEntry = entry);
          ref.read(journalProvider.notifier).refresh();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(journalProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _todayLoaded ? _showEditor : null,
            tooltip: "Today's entry",
          ),
        ],
      ),
      body: listAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.read(journalProvider.notifier).refresh(),
        ),
        data: (list) {
          final today = DateTime.now().toIso8601String().split('T').first;
          final past = list.entries.where((e) => e.entryDate != today).toList();

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(journalProvider.notifier).refresh();
              await _loadToday();
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Streak + summary
                AriseCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${list.total} ${list.total == 1 ? "entry" : "entries"}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              'in your journal',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: cs.onSurface.withValues(alpha: 0.45),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      if (list.streak > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF97316).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFFF97316)
                                    .withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.local_fire_department,
                                  color: Color(0xFFF97316), size: 18),
                              const SizedBox(width: 4),
                              Text(
                                '${list.streak}',
                                style: const TextStyle(
                                  color: Color(0xFFF97316),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Today's entry card
                if (!_todayLoaded)
                  const SizedBox(
                    height: 80,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  _TodayCard(
                    entry: _todayEntry,
                    onTap: _showEditor,
                    onReflectionGenerated: (entry) =>
                        setState(() => _todayEntry = entry),
                  ),
                const SizedBox(height: 20),

                // Past entries
                if (past.isNotEmpty) ...[
                  Text(
                    'Past Entries',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                  ),
                  const SizedBox(height: 10),
                  ...past.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _PastEntryCard(entry: e.value),
                      ).animate().fadeIn(delay: (e.key * 40).ms, duration: 250.ms)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Today card ─────────────────────────────────────────────────────────────────

class _TodayCard extends ConsumerStatefulWidget {
  final JournalEntry? entry;
  final VoidCallback onTap;
  final ValueChanged<JournalEntry> onReflectionGenerated;

  const _TodayCard({
    required this.entry,
    required this.onTap,
    required this.onReflectionGenerated,
  });

  @override
  ConsumerState<_TodayCard> createState() => _TodayCardState();
}

class _TodayCardState extends ConsumerState<_TodayCard> {
  bool _reflectionLoading = false;
  String? _reflectionError;

  Future<void> _generateReflection() async {
    if (widget.entry == null) return;
    setState(() { _reflectionLoading = true; _reflectionError = null; });
    try {
      final updated = await ref
          .read(journalProvider.notifier)
          .generateReflection(widget.entry!.id);
      widget.onReflectionGenerated(updated);
    } on AppException catch (e) {
      setState(() => _reflectionError =
          e.message.contains('configure') ? 'AI not configured on this server.' : e.message);
    } finally {
      if (mounted) setState(() => _reflectionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final entry = widget.entry;
    final today = DateTime.now();
    final dateStr =
        '${_weekday(today.weekday)}, ${_month(today.month)} ${today.day}';

    return AriseCard(
      onTap: widget.onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today",
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: cs.primary,
                        ),
                  ),
                  Text(
                    dateStr,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.4),
                        ),
                  ),
                ],
              ),
              if (entry == null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Write',
                    style: TextStyle(
                        color: cs.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                )
              else if (entry.mood != null)
                Text(
                  _moods.firstWhere((m) => m.value == entry.mood,
                          orElse: () => _moods[2])
                      .emoji,
                  style: const TextStyle(fontSize: 22),
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (entry == null) ...[
            Text(
              "Tap to write today's entry",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.35),
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ] else ...[
            Text(
              entry.content.length > 200
                  ? '${entry.content.substring(0, 200)}…'
                  : entry.content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.75),
                  ),
            ),
            const SizedBox(height: 12),

            // AI reflection
            if (entry.hasReflection) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome, color: cs.primary, size: 13),
                        const SizedBox(width: 5),
                        Text(
                          'AI Reflection',
                          style: TextStyle(
                            color: cs.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      entry.aiReflection!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.7),
                          ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              if (_reflectionError != null)
                Text(
                  _reflectionError!,
                  style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.4), fontSize: 11),
                ),
              SizedBox(
                height: 34,
                child: OutlinedButton.icon(
                  onPressed: _reflectionLoading ? null : _generateReflection,
                  icon: _reflectionLoading
                      ? SizedBox(
                          width: 13,
                          height: 13,
                          child: CircularProgressIndicator(
                              strokeWidth: 1.5, color: cs.primary),
                        )
                      : Icon(Icons.auto_awesome, size: 14, color: cs.primary),
                  label: Text(
                    _reflectionLoading ? 'Generating…' : 'Get AI Reflection',
                    style: TextStyle(fontSize: 12, color: cs.primary),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    side: BorderSide(color: cs.primary.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _weekday(int d) {
    const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return days[(d - 1) % 7];
  }

  String _month(int m) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[m - 1];
  }
}

// ── Past entry card ─────────────────────────────────────────────────────────────

class _PastEntryCard extends StatefulWidget {
  final JournalEntry entry;

  const _PastEntryCard({required this.entry});

  @override
  State<_PastEntryCard> createState() => _PastEntryCardState();
}

class _PastEntryCardState extends State<_PastEntryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final e = widget.entry;
    final parts = e.entryDate.split('-');
    final dateLabel = parts.length == 3 ? '${parts[2]}/${parts[1]}' : e.entryDate;
    final mood = e.mood != null
        ? _moods.firstWhere((m) => m.value == e.mood, orElse: () => _moods[2])
        : null;

    return AriseCard(
      onTap: () => setState(() => _expanded = !_expanded),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  dateLabel,
                  style: TextStyle(
                    color: cs.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _expanded
                      ? e.content
                      : (e.content.length > 100
                          ? '${e.content.substring(0, 100)}…'
                          : e.content),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.65),
                      ),
                ),
              ),
              if (mood != null) ...[
                const SizedBox(width: 6),
                Text(mood.emoji, style: const TextStyle(fontSize: 16)),
              ],
              const SizedBox(width: 4),
              Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                size: 18,
                color: cs.onSurface.withValues(alpha: 0.3),
              ),
            ],
          ),
          if (_expanded && e.hasReflection) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cs.primary.withValues(alpha: 0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, color: cs.primary, size: 11),
                      const SizedBox(width: 4),
                      Text(
                        'AI Reflection',
                        style: TextStyle(
                          color: cs.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    e.aiReflection!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.6),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Editor sheet ───────────────────────────────────────────────────────────────

class _EditorSheet extends ConsumerStatefulWidget {
  final JournalEntry? initial;
  final ValueChanged<JournalEntry> onSaved;

  const _EditorSheet({required this.initial, required this.onSaved});

  @override
  ConsumerState<_EditorSheet> createState() => _EditorSheetState();
}

class _EditorSheetState extends ConsumerState<_EditorSheet> {
  late final TextEditingController _ctrl;
  int? _mood;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initial?.content ?? '');
    _mood = widget.initial?.mood;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_ctrl.text.trim().length < 20) {
      setState(() => _error = 'Write at least 20 characters');
      return;
    }
    setState(() { _saving = true; _error = null; });
    try {
      final entry = await ref.read(journalProvider.notifier).saveEntry(
            content: _ctrl.text.trim(),
            mood: _mood,
          );
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSaved(entry);
      }
    } on AppException catch (e) {
      setState(() { _error = e.message; _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final wordCount =
        _ctrl.text.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.97,
      minChildSize: 0.5,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.fromLTRB(20, 0, 20, bottom + 20),
        child: ListView(
          controller: scrollCtrl,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Today's Entry",
                    style: Theme.of(context).textTheme.titleLarge),
                Text(
                  '$wordCount words',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.4),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Mood picker
            Text('Mood', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Row(
              children: _moods.map((m) {
                final isSelected = _mood == m.value;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(
                        () => _mood = isSelected ? null : m.value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? cs.primary.withValues(alpha: 0.15)
                            : cs.onSurface.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? cs.primary.withValues(alpha: 0.5)
                              : Colors.transparent,
                        ),
                      ),
                      child: Text(m.emoji,
                          style: const TextStyle(fontSize: 20),
                          textAlign: TextAlign.center),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_error!,
                    style: TextStyle(color: cs.error, fontSize: 13)),
              ),
              const SizedBox(height: 12),
            ],

            // Content
            TextField(
              controller: _ctrl,
              maxLines: 12,
              minLines: 8,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText:
                    'What happened today? What did you do, learn, or feel? Be honest and specific…',
                hintStyle: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.3), fontSize: 14),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: cs.onSurface.withValues(alpha: 0.15))),
                alignLabelWithHint: true,
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 24),
            AriseButton(label: 'Save Entry', loading: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
