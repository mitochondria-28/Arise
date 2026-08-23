import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/errors/app_exception.dart';
import '../../core/models/goal.dart';
import '../../core/network/api_client.dart';
import '../../shared/widgets/arise_card.dart';
import '../../shared/widgets/arise_button.dart';
import '../../shared/widgets/error_view.dart';
import 'goal_provider.dart';

// ── Solo Leveling palette ──────────────────────────────────────────────────────
const _kBg     = Color(0xFF0A0A0F);
const _kCard   = Color(0xFF1C1C2E);
const _kBorder = Color(0xFF2A2A3E);
const _kBlue   = Color(0xFF4FC3F7);
const _kPurple = Color(0xFF9B59B6);
const _kGold   = Color(0xFFFFD700);
const _kGreen  = Color(0xFF34D399);
const _kOrange = Color(0xFFF97316);
const _kRed    = Color(0xFFEF4444);
const _kText   = Color(0xFFE2E8F0);
const _kDim    = Color(0xFF64748B);

// ── Helpers ────────────────────────────────────────────────────────────────────
Color _diffColor(String d) {
  switch (d) {
    case 'easy':   return _kGreen;
    case 'medium': return _kBlue;
    case 'hard':   return _kOrange;
    case 'epic':   return _kPurple;
    default:       return _kDim;
  }
}

IconData _catIcon(String cat) {
  switch (cat) {
    case 'vitality':     return Icons.favorite_rounded;
    case 'strength':     return Icons.fitness_center_rounded;
    case 'intelligence': return Icons.psychology_rounded;
    case 'wisdom':       return Icons.auto_awesome_rounded;
    case 'charisma':     return Icons.star_rounded;
    case 'discipline':   return Icons.shield_rounded;
    default:             return Icons.circle;
  }
}

Color _catColor(String cat) {
  switch (cat) {
    case 'vitality':     return _kRed;
    case 'strength':     return _kOrange;
    case 'intelligence': return _kBlue;
    case 'wisdom':       return _kGold;
    case 'charisma':     return _kPurple;
    case 'discipline':   return _kGreen;
    default:             return _kDim;
  }
}

// ── Screen ─────────────────────────────────────────────────────────────────────
class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(goalListProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _kBg,
        body: Column(
          children: [
            _GoalHeader(
              onAdd: () => _showCreateSheet(context, ref),
              onTemplates: () => _showTemplatesSheet(context, ref),
            ),
            Expanded(
              child: async.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: _kBlue, strokeWidth: 2),
                ),
                error: (e, _) => ErrorView(
                  message: e.toString(),
                  onRetry: () => ref.read(goalListProvider.notifier).refresh(),
                ),
                data: (goals) {
                  final active    = goals.where((g) => g.status == 'active').toList();
                  final completed = goals.where((g) => g.status == 'completed').toList();

                  if (goals.isEmpty) {
                    return _EmptyGoals(onCreate: () => _showCreateSheet(context, ref));
                  }

                  return RefreshIndicator(
                    color: _kBlue,
                    backgroundColor: _kCard,
                    onRefresh: () => ref.read(goalListProvider.notifier).refresh(),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                      children: [
                        if (active.isNotEmpty) ...[
                          _SectionLabel('ACTIVE QUESTS', _kBlue, active.length),
                          const SizedBox(height: 10),
                          ...active.asMap().entries.map((entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _GoalCard(
                              goal: entry.value,
                              onComplete: () => _showCompleteSheet(context, ref, entry.value),
                            ),
                          ).animate().fadeIn(delay: (entry.key * 60).ms, duration: 300.ms)
                            .slideY(begin: 0.08, end: 0, duration: 300.ms)),
                        ],
                        if (completed.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _SectionLabel('COMPLETED', _kGreen, completed.length),
                          const SizedBox(height: 10),
                          ...completed.map((g) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _GoalCard(goal: g),
                          )),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateSheet(BuildContext context, WidgetRef ref, {GoalTemplate? template}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateGoalSheet(ref: ref, template: template),
    );
  }

  void _showTemplatesSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GoalTemplatesSheet(
        onUse: (t) {
          Navigator.of(context).pop();
          _showCreateSheet(context, ref, template: t);
        },
      ),
    );
  }

  void _showCompleteSheet(BuildContext context, WidgetRef ref, GoalResponse goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CompleteGoalSheet(ref: ref, goal: goal),
    );
  }
}

// ── Goal Header ────────────────────────────────────────────────────────────────
class _GoalHeader extends StatelessWidget {
  final VoidCallback onAdd;
  final VoidCallback onTemplates;

  const _GoalHeader({required this.onAdd, required this.onTemplates});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(16, top + 14, 16, 16),
      decoration: const BoxDecoration(
        color: _kCard,
        border: Border(bottom: BorderSide(color: _kBorder, width: 1)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 5, height: 5, decoration: const BoxDecoration(color: _kGold, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  const Text('QUEST BOARD', style: TextStyle(color: _kGold, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2.5)),
                  const SizedBox(width: 6),
                  Container(width: 5, height: 5, decoration: const BoxDecoration(color: _kGold, shape: BoxShape.circle)),
                ],
              ),
              const SizedBox(height: 3),
              const Text('Goals & Objectives', style: TextStyle(color: _kText, fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: onTemplates,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: _kPurple.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _kPurple.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.grid_view_rounded, color: _kPurple, size: 13),
                  SizedBox(width: 5),
                  Text('TEMPLATES', style: TextStyle(color: _kPurple, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: _kGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kGold.withValues(alpha: 0.4)),
              ),
              child: const Icon(Icons.add_rounded, color: _kGold, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Label ──────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;
  final int count;

  const _SectionLabel(this.label, this.color, this.count);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 16, color: color, decoration: BoxDecoration(borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text('$count', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

// ── Goal Card ──────────────────────────────────────────────────────────────────
class _GoalCard extends ConsumerStatefulWidget {
  final GoalResponse goal;
  final VoidCallback? onComplete;

  const _GoalCard({required this.goal, this.onComplete});

  @override
  ConsumerState<_GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends ConsumerState<_GoalCard> {
  bool _milestonesOpen = false;
  List<GoalMilestone> _milestones = [];
  bool _loadingMs = false;
  final _newTitleCtrl = TextEditingController();
  bool _addingMs = false;
  bool _submittingMs = false;

  @override
  void dispose() {
    _newTitleCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMilestones() async {
    if (_loadingMs) return;
    setState(() => _loadingMs = true);
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get<List<dynamic>>('/goals/${widget.goal.id}/milestones');
      if (mounted) {
        setState(() {
          _milestones = (res.data ?? [])
              .map((e) => GoalMilestone.fromJson(e as Map<String, dynamic>))
              .toList();
          _loadingMs = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingMs = false);
    }
  }

  Future<void> _toggle(GoalMilestone ms, bool done) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.patch('/goals/${widget.goal.id}/milestones/${ms.id}',
          data: {'is_completed': done});
      await _loadMilestones();
    } catch (_) {}
  }

  Future<void> _delete(String msId) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.delete('/goals/${widget.goal.id}/milestones/$msId');
      await _loadMilestones();
    } catch (_) {}
  }

  Future<void> _addMilestone() async {
    final title = _newTitleCtrl.text.trim();
    if (title.length < 3) return;
    setState(() => _submittingMs = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/goals/${widget.goal.id}/milestones', data: {'title': title});
      _newTitleCtrl.clear();
      setState(() { _addingMs = false; _submittingMs = false; });
      await _loadMilestones();
    } catch (_) {
      if (mounted) setState(() => _submittingMs = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.goal.isCompleted;
    final done     = _milestones.where((m) => m.isCompleted).length;
    final dColor   = _diffColor(widget.goal.difficulty);
    final cColor   = _catColor(widget.goal.category);
    final barColor = isCompleted ? _kGreen : dColor;

    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? _kGreen.withValues(alpha: 0.35)
              : dColor.withValues(alpha: 0.35),
        ),
        boxShadow: isCompleted
            ? [BoxShadow(color: _kGreen.withValues(alpha: 0.08), blurRadius: 12)]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(left: 0, top: 0, bottom: 0, child: Container(width: 4, color: barColor)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 13, 13, 13),
            child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 34, height: 34,
                          decoration: BoxDecoration(
                            color: cColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(_catIcon(widget.goal.category), color: cColor, size: 16),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.goal.title,
                                style: TextStyle(
                                  color: isCompleted ? _kDim : _kText,
                                  fontSize: 14, fontWeight: FontWeight.w600,
                                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              if (widget.goal.description?.isNotEmpty == true) ...[
                                const SizedBox(height: 3),
                                Text(
                                  widget.goal.description ?? '',
                                  style: const TextStyle(color: _kDim, fontSize: 11),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (isCompleted)
                          const Icon(Icons.check_circle_rounded, color: _kGreen, size: 20),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Tags + action
                    Row(
                      children: [
                        _SysTag(widget.goal.difficulty.toUpperCase(), dColor),
                        const SizedBox(width: 6),
                        _SysTag(widget.goal.category.toUpperCase(), cColor),
                        const Spacer(),
                        if (!isCompleted && widget.onComplete != null)
                          GestureDetector(
                            onTap: widget.onComplete,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _kGreen.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: _kGreen.withValues(alpha: 0.4)),
                              ),
                              child: const Text(
                                'COMPLETE',
                                style: TextStyle(
                                  color: _kGreen, fontSize: 9,
                                  fontWeight: FontWeight.w800, letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    // Milestones
                    const SizedBox(height: 10),
                    Container(height: 1, color: _kBorder),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() => _milestonesOpen = !_milestonesOpen);
                        if (!_milestonesOpen) _loadMilestones();
                      },
                      child: Row(
                        children: [
                          Icon(
                            _milestonesOpen ? Icons.expand_less : Icons.expand_more,
                            size: 14, color: _kDim,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'MILESTONES',
                            style: TextStyle(
                              fontSize: 9, fontWeight: FontWeight.w700,
                              letterSpacing: 1.5, color: _kDim,
                            ),
                          ),
                          if (_milestones.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (done == _milestones.length ? _kGreen : _kBlue)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '$done/${_milestones.length}',
                                style: TextStyle(
                                  fontSize: 9, fontWeight: FontWeight.w700,
                                  color: done == _milestones.length ? _kGreen : _kBlue,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (_milestonesOpen) ...[
                      const SizedBox(height: 8),
                      if (_loadingMs)
                        const Center(
                          child: SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: _kBlue),
                          ),
                        )
                      else ...[
                        ..._milestones.map((ms) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 20, height: 20,
                                    child: Checkbox(
                                      value: ms.isCompleted,
                                      onChanged: isCompleted ? null : (v) => _toggle(ms, v!),
                                      visualDensity: VisualDensity.compact,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      checkColor: _kBg,
                                      fillColor: WidgetStateProperty.resolveWith((s) {
                                        if (s.contains(WidgetState.selected)) return _kGreen;
                                        return _kBorder;
                                      }),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      ms.title,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: ms.isCompleted ? _kDim : _kText.withValues(alpha: 0.8),
                                        decoration: ms.isCompleted ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                  ),
                                  if (!isCompleted)
                                    GestureDetector(
                                      onTap: () => _delete(ms.id),
                                      child: const Icon(Icons.close, size: 13, color: _kDim),
                                    ),
                                ],
                              ),
                            )),
                        if (!isCompleted)
                          if (_addingMs)
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _newTitleCtrl,
                                    autofocus: true,
                                    style: const TextStyle(fontSize: 12, color: _kText),
                                    decoration: const InputDecoration(
                                      hintText: 'Milestone title...',
                                      hintStyle: TextStyle(color: _kDim, fontSize: 12),
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    ),
                                    onSubmitted: (_) => _addMilestone(),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                _submittingMs
                                    ? const SizedBox(
                                        width: 14, height: 14,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: _kBlue),
                                      )
                                    : GestureDetector(
                                        onTap: _addMilestone,
                                        child: const Text('ADD', style: TextStyle(color: _kBlue, fontSize: 11, fontWeight: FontWeight.w700)),
                                      ),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () => setState(() { _addingMs = false; _newTitleCtrl.clear(); }),
                                  child: const Icon(Icons.close, size: 14, color: _kDim),
                                ),
                              ],
                            )
                          else
                            GestureDetector(
                              onTap: () => setState(() => _addingMs = true),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add, size: 12, color: _kBlue),
                                  SizedBox(width: 3),
                                  Text(
                                    'ADD MILESTONE',
                                    style: TextStyle(
                                      color: _kBlue, fontSize: 9,
                                      fontWeight: FontWeight.w700, letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                      ],
                    ],
                  ],
                ),
              ),
          ],
        ),
    );
  }
}

// ── System tag ─────────────────────────────────────────────────────────────────
class _SysTag extends StatelessWidget {
  final String label;
  final Color color;

  const _SysTag(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.8),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────
class _EmptyGoals extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyGoals({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: _kGold.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: _kGold.withValues(alpha: 0.2)),
            ),
            child: const Icon(Icons.flag_outlined, color: _kGold, size: 28),
          ),
          const SizedBox(height: 16),
          const Text(
            'NO QUESTS YET',
            style: TextStyle(color: _kText, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.5),
          ),
          const SizedBox(height: 8),
          const Text(
            'Set a meaningful goal and commit to seeing it through.',
            style: TextStyle(color: _kDim, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onCreate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _kGold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kGold.withValues(alpha: 0.4)),
              ),
              child: const Text(
                'CREATE FIRST GOAL',
                style: TextStyle(color: _kGold, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2),
              ),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM SHEETS — preserved exactly
// ─────────────────────────────────────────────────────────────────────────────

class _CreateGoalSheet extends StatefulWidget {
  final WidgetRef ref;
  final GoalTemplate? template;

  const _CreateGoalSheet({required this.ref, this.template});

  @override
  State<_CreateGoalSheet> createState() => _CreateGoalSheetState();
}

class _CreateGoalSheetState extends State<_CreateGoalSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late String _category;
  late String _difficulty;
  bool _submitting = false;
  String? _error;

  static const _categories = [
    'vitality', 'strength', 'intelligence',
    'wisdom', 'charisma', 'discipline',
  ];
  static const _difficulties = ['easy', 'medium', 'hard', 'epic'];

  @override
  void initState() {
    super.initState();
    final t = widget.template;
    _titleCtrl  = TextEditingController(text: t?.title ?? '');
    _descCtrl   = TextEditingController(text: t?.description ?? '');
    _category   = t?.category ?? 'vitality';
    _difficulty = t?.difficulty ?? 'medium';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _submitting = true; _error = null; });
    try {
      await widget.ref.read(goalListProvider.notifier).create(
            CreateGoalRequest(
              title: _titleCtrl.text.trim(),
              description: _descCtrl.text.trim().isEmpty
                  ? null
                  : _descCtrl.text.trim(),
              category: _category,
              difficulty: _difficulty,
            ),
          );
      if (mounted) Navigator.of(context).pop();
    } on AppException catch (e) {
      setState(() { _error = e.message; _submitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.fromLTRB(20, 0, 20, bottom + 20),
        child: Form(
          key: _formKey,
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
              Text(
                widget.template != null ? 'Goal from Template' : 'New Goal',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(_error!, style: TextStyle(color: cs.error, fontSize: 13)),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _titleCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Goal title'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (v.trim().length < 5) return 'At least 5 characters';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),
              Text('Category', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _categories.map((c) => ChoiceChip(
                  label: Text(c),
                  selected: _category == c,
                  onSelected: (_) => setState(() => _category = c),
                )).toList(),
              ),
              const SizedBox(height: 20),
              Text('Difficulty', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Row(
                children: _difficulties.map((d) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(d, style: const TextStyle(fontSize: 12)),
                      selected: _difficulty == d,
                      onSelected: (_) => setState(() => _difficulty = d),
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 28),
              AriseButton(label: 'Create Goal', loading: _submitting, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalTemplatesSheet extends ConsumerStatefulWidget {
  final void Function(GoalTemplate) onUse;

  const _GoalTemplatesSheet({required this.onUse});

  @override
  ConsumerState<_GoalTemplatesSheet> createState() => _GoalTemplatesSheetState();
}

class _GoalTemplatesSheetState extends ConsumerState<_GoalTemplatesSheet> {
  static const _allCategories = [
    'all', 'vitality', 'strength', 'intelligence',
    'wisdom', 'charisma', 'discipline',
  ];
  String _filter = 'all';
  List<GoalTemplate>? _templates;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get<List<dynamic>>('/goals/templates');
      final templates = (res.data ?? [])
          .map((e) => GoalTemplate.fromJson(e as Map<String, dynamic>))
          .toList();
      if (mounted) setState(() { _templates = templates; _loading = false; });
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _error = fromDioError(e).message;
          _loading = false;
        });
      }
    }
  }

  List<GoalTemplate> get _visible {
    final all = _templates ?? [];
    if (_filter == 'all') return all;
    return all.where((t) => t.category == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
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
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Goal Templates', style: Theme.of(context).textTheme.titleLarge),
                        Text('Pick one to pre-fill your goal', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _allCategories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final cat = _allCategories[i];
                  final selected = _filter == cat;
                  return GestureDetector(
                    onTap: () => setState(() => _filter = cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected ? cs.primary : cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        cat[0].toUpperCase() + cat.substring(1),
                        style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: selected ? cs.onPrimary : cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!, style: TextStyle(color: cs.error)))
                      : _visible.isEmpty
                          ? const Center(child: Text('No templates in this category.'))
                          : ListView.separated(
                              controller: scrollCtrl,
                              padding: const EdgeInsets.all(16),
                              itemCount: _visible.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (_, i) {
                                final t = _visible[i];
                                return _TemplateCard(template: t, onUse: () => widget.onUse(t));
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final GoalTemplate template;
  final VoidCallback onUse;

  const _TemplateCard({required this.template, required this.onUse});

  static const _diffColor = {
    'easy':   Color(0xFF22C55E),
    'medium': Color(0xFFF59E0B),
    'hard':   Color(0xFFF97316),
    'epic':   Color(0xFFA855F7),
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final diffColor = _diffColor[template.difficulty] ?? cs.primary;

    return AriseCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(template.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(template.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(template.category,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.primary)),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: diffColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(template.difficulty,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: diffColor)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(template.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.65))),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onUse,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
                side: BorderSide(color: cs.primary.withValues(alpha: 0.4)),
              ),
              child: Text('Use this template',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.primary)),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompleteGoalSheet extends StatefulWidget {
  final WidgetRef ref;
  final GoalResponse goal;

  const _CompleteGoalSheet({required this.ref, required this.goal});

  @override
  State<_CompleteGoalSheet> createState() => _CompleteGoalSheetState();
}

class _CompleteGoalSheetState extends State<_CompleteGoalSheet> {
  final _formKey = GlobalKey<FormState>();
  final _evidenceCtrl = TextEditingController();
  final _reflectionCtrl = TextEditingController();
  int _effort = 3;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _evidenceCtrl.dispose();
    _reflectionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _submitting = true; _error = null; });
    try {
      final result = await widget.ref.read(goalListProvider.notifier).complete(
            widget.goal.id,
            CompleteGoalRequest(
              evidenceText: _evidenceCtrl.text.trim(),
              reflection: _reflectionCtrl.text.trim().isEmpty
                  ? null
                  : _reflectionCtrl.text.trim(),
              effortLevel: _effort,
            ),
          );
      if (mounted) {
        Navigator.of(context).pop();
        if (result.leveledUp) {
          _showLevelUpDialog(context, result.levelsGained.last);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('+${result.xpAwarded} XP earned!'),
              backgroundColor: const Color(0xFF34D399),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } on AppException catch (e) {
      setState(() { _error = e.message; _submitting = false; });
    }
  }

  void _showLevelUpDialog(BuildContext context, int newLevel) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Level Up!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_upward_rounded, size: 48, color: Color(0xFF34D399)),
            const SizedBox(height: 12),
            Text('You reached Level $newLevel!',
                style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Awesome!')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.fromLTRB(20, 0, 20, bottom + 20),
        child: Form(
          key: _formKey,
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
              Text('Complete Goal', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(widget.goal.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.primary)),
              const SizedBox(height: 20),
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(_error!, style: TextStyle(color: cs.error, fontSize: 13)),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _evidenceCtrl,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'What did you actually do? *',
                  hintText: 'Describe your concrete actions and results...',
                  alignLabelWithHint: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (v.trim().length < 30) return 'Please provide at least 30 characters of evidence';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _reflectionCtrl,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Reflection (optional)',
                  hintText: 'What did you learn? What would you do differently?',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),
              Text('Effort level', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (i) {
                  final val = i + 1;
                  final selected = _effort >= val;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _effort = val),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        height: 40,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: selected
                              ? cs.primary.withValues(alpha: 0.9)
                              : cs.onSurface.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$val',
                          style: TextStyle(
                            color: selected ? cs.onPrimary : cs.onSurface.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 28),
              AriseButton(label: 'Complete & Earn XP', loading: _submitting, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
