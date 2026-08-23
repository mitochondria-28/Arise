import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/errors/app_exception.dart';
import '../../core/models/journal.dart';
import '../../shared/widgets/arise_button.dart';
import '../../shared/widgets/error_view.dart';
import 'journal_provider.dart';

// ── Solo Leveling palette ──────────────────────────────────────────────────────
const _kBg     = Color(0xFF0A0A0F);
const _kCard   = Color(0xFF1C1C2E);
const _kBorder = Color(0xFF2A2A3E);
const _kBlue   = Color(0xFF4FC3F7);
const _kPurple = Color(0xFF9B59B6);
const _kOrange = Color(0xFFF97316);
const _kText   = Color(0xFFE2E8F0);
const _kDim    = Color(0xFF64748B);

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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _kBg,
        body: listAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: _kBlue, strokeWidth: 2),
          ),
          error: (e, _) => ErrorView(
            message: e.toString(),
            onRetry: () => ref.read(journalProvider.notifier).refresh(),
          ),
          data: (list) {
            final today = DateTime.now().toIso8601String().split('T').first;
            final past  = list.entries.where((e) => e.entryDate != today).toList();

            return RefreshIndicator(
              color: _kBlue,
              backgroundColor: _kCard,
              onRefresh: () async {
                await ref.read(journalProvider.notifier).refresh();
                await _loadToday();
              },
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _JournalHeader(
                      total: list.total,
                      streak: list.streak,
                      onWrite: _todayLoaded ? _showEditor : null,
                    ).animate().fadeIn(duration: 350.ms),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FieldLabel('TODAY\'S ENTRY', _kBlue),
                          const SizedBox(height: 10),
                          if (!_todayLoaded)
                            _LoadingCard()
                          else
                            _TodayCard(
                              entry: _todayEntry,
                              onTap: _showEditor,
                              onReflectionGenerated: (entry) =>
                                  setState(() => _todayEntry = entry),
                            ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 100.ms, duration: 350.ms),
                  ),
                  if (past.isNotEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                        child: _FieldLabel('PAST ENTRIES', _kDim),
                      ),
                    ),
                  if (past.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _PastEntryCard(entry: past[i])
                                .animate()
                                .fadeIn(delay: (i * 40).ms, duration: 250.ms),
                          ),
                          childCount: past.length,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Journal Header ─────────────────────────────────────────────────────────────
class _JournalHeader extends StatelessWidget {
  final int total;
  final int streak;
  final VoidCallback? onWrite;

  const _JournalHeader({required this.total, required this.streak, this.onWrite});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(16, top + 14, 16, 18),
      decoration: const BoxDecoration(
        color: _kCard,
        border: Border(bottom: BorderSide(color: _kBorder, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 5, height: 5, decoration: const BoxDecoration(color: _kBlue, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    const Text('FIELD NOTES', style: TextStyle(color: _kBlue, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2.5)),
                    const SizedBox(width: 6),
                    Container(width: 5, height: 5, decoration: const BoxDecoration(color: _kBlue, shape: BoxShape.circle)),
                  ],
                ),
                const SizedBox(height: 3),
                const Text('Hunter\'s Journal', style: TextStyle(color: _kText, fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _StatChip(label: 'ENTRIES', value: '$total', color: _kBlue),
                    if (streak > 0) ...[
                      const SizedBox(width: 10),
                      _StatChip(label: 'STREAK', value: '$streak 🔥', color: _kOrange),
                    ],
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onWrite,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: _kBlue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kBlue.withValues(alpha: 0.4)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_outlined, color: _kBlue, size: 15),
                  SizedBox(width: 6),
                  Text('WRITE', style: TextStyle(color: _kBlue, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1)),
        ],
      ),
    );
  }
}

// ── Field label ────────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String text;
  final Color color;

  const _FieldLabel(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3, height: 14,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2)),
      ],
    );
  }
}

// ── Loading card ───────────────────────────────────────────────────────────────
class _LoadingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: _kCard, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: const Center(child: CircularProgressIndicator(color: _kBlue, strokeWidth: 2)),
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
    final entry   = widget.entry;
    final today   = DateTime.now();
    final dateStr = '${_weekday(today.weekday)}, ${_month(today.month)} ${today.day}';

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: entry != null ? _kBlue.withValues(alpha: 0.4) : _kBorder,
          ),
          boxShadow: entry != null
              ? [BoxShadow(color: _kBlue.withValues(alpha: 0.08), blurRadius: 12)]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _kBlue.withValues(alpha: 0.06),
                  border: const Border(bottom: BorderSide(color: _kBorder)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.today_outlined, color: _kBlue, size: 14),
                    const SizedBox(width: 6),
                    const Text('TODAY', style: TextStyle(color: _kBlue, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2)),
                    const SizedBox(width: 8),
                    Text(dateStr, style: const TextStyle(color: _kDim, fontSize: 10)),
                    const Spacer(),
                    if (entry?.mood != null)
                      Text(
                        _moods.firstWhere((m) => m.value == entry!.mood, orElse: () => _moods[2]).emoji,
                        style: const TextStyle(fontSize: 18),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _kBlue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _kBlue.withValues(alpha: 0.3)),
                        ),
                        child: const Text('WRITE', style: TextStyle(color: _kBlue, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1)),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (entry == null)
                      const Text(
                        'Tap to write today\'s entry…',
                        style: TextStyle(color: _kDim, fontSize: 14, fontStyle: FontStyle.italic),
                      )
                    else ...[
                      Text(
                        entry.content.length > 200
                            ? '${entry.content.substring(0, 200)}…'
                            : entry.content,
                        style: TextStyle(color: _kText.withValues(alpha: 0.85), fontSize: 13, height: 1.5),
                      ),
                      const SizedBox(height: 12),
                      if (entry.hasReflection) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _kPurple.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _kPurple.withValues(alpha: 0.25)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.auto_awesome, color: _kPurple, size: 12),
                                  SizedBox(width: 5),
                                  Text('AI REFLECTION', style: TextStyle(color: _kPurple, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(entry.aiReflection!, style: TextStyle(color: _kText.withValues(alpha: 0.75), fontSize: 12, height: 1.5)),
                            ],
                          ),
                        ),
                      ] else ...[
                        if (_reflectionError != null) ...[
                          Text(_reflectionError!, style: const TextStyle(color: _kDim, fontSize: 11)),
                          const SizedBox(height: 8),
                        ],
                        GestureDetector(
                          onTap: _reflectionLoading ? null : _generateReflection,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: _kPurple.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _kPurple.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_reflectionLoading)
                                  const SizedBox(
                                    width: 12, height: 12,
                                    child: CircularProgressIndicator(strokeWidth: 1.5, color: _kPurple),
                                  )
                                else
                                  const Icon(Icons.auto_awesome, size: 12, color: _kPurple),
                                const SizedBox(width: 6),
                                Text(
                                  _reflectionLoading ? 'GENERATING…' : 'GET AI REFLECTION',
                                  style: const TextStyle(color: _kPurple, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _weekday(int d) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[(d - 1) % 7];
  }

  String _month(int m) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
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
    final e = widget.entry;
    final parts = e.entryDate.split('-');
    final dateLabel = parts.length == 3 ? '${parts[2]}/${parts[1]}' : e.entryDate;
    final mood = e.mood != null
        ? _moods.firstWhere((m) => m.value == e.mood, orElse: () => _moods[2])
        : null;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _expanded ? _kBlue.withValues(alpha: 0.3) : _kBorder),
        ),
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: _kBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: _kBlue.withValues(alpha: 0.2)),
                  ),
                  child: Text(dateLabel, style: const TextStyle(color: _kBlue, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _expanded
                        ? e.content
                        : (e.content.length > 100 ? '${e.content.substring(0, 100)}…' : e.content),
                    style: TextStyle(color: _kText.withValues(alpha: 0.75), fontSize: 12, height: 1.4),
                  ),
                ),
                if (mood != null) ...[
                  const SizedBox(width: 6),
                  Text(mood.emoji, style: const TextStyle(fontSize: 16)),
                ],
                const SizedBox(width: 4),
                Icon(_expanded ? Icons.expand_less : Icons.expand_more, size: 16, color: _kDim),
              ],
            ),
            if (_expanded && e.hasReflection) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _kPurple.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _kPurple.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome, color: _kPurple, size: 10),
                        SizedBox(width: 4),
                        Text('AI REFLECTION', style: TextStyle(color: _kPurple, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(e.aiReflection!, style: TextStyle(color: _kText.withValues(alpha: 0.65), fontSize: 11, height: 1.4)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EDITOR SHEET — preserved exactly
// ─────────────────────────────────────────────────────────────────────────────

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
                width: 36, height: 4,
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
                Text("Today's Entry", style: Theme.of(context).textTheme.titleLarge),
                Text(
                  '$wordCount words',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.4),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Mood', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Row(
              children: _moods.map((m) {
                final isSelected = _mood == m.value;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _mood = isSelected ? null : m.value),
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
                      child: Text(m.emoji, style: const TextStyle(fontSize: 20), textAlign: TextAlign.center),
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
                child: Text(_error!, style: TextStyle(color: cs.error, fontSize: 13)),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _ctrl,
              maxLines: 12,
              minLines: 8,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'What happened today? What did you do, learn, or feel? Be honest and specific…',
                hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.3), fontSize: 14),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.15))),
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
