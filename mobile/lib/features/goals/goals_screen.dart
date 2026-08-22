import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/errors/app_exception.dart';
import '../../core/models/goal.dart';
import '../../core/network/api_client.dart';
import '../../shared/widgets/arise_card.dart';
import '../../shared/widgets/arise_button.dart';
import '../../shared/widgets/rank_badge.dart';
import '../../shared/widgets/error_view.dart';
import 'goal_provider.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(goalListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals'),
        actions: [
          TextButton.icon(
            onPressed: () => _showTemplatesSheet(context, ref),
            icon: const Icon(Icons.grid_view_rounded, size: 18),
            label: const Text('Templates'),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showCreateSheet(context, ref),
            tooltip: 'New goal',
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.read(goalListProvider.notifier).refresh(),
        ),
        data: (goals) {
          final active =
              goals.where((g) => g.status == 'active').toList();
          final completed =
              goals.where((g) => g.status == 'completed').toList();

          if (goals.isEmpty) {
            return EmptyState(
              icon: Icons.flag_outlined,
              title: 'No goals yet',
              subtitle: 'Set a meaningful goal and commit to seeing it through.',
              actionLabel: 'Create first goal',
              onAction: () => _showCreateSheet(context, ref),
            );
          }

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(goalListProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (active.isNotEmpty) ...[
                  Text('Active (${active.length})',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 10),
                  ...active.asMap().entries.map((entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _GoalCard(
                          goal: entry.value,
                          onComplete: () =>
                              _showCompleteSheet(context, ref, entry.value),
                        ),
                      ).animate().fadeIn(
                            delay: (entry.key * 60).ms,
                            duration: 300.ms,
                          )),
                ],
                if (completed.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Completed (${completed.length})',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.45),
                        ),
                  ),
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

  void _showCompleteSheet(
      BuildContext context, WidgetRef ref, GoalResponse goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CompleteGoalSheet(ref: ref, goal: goal),
    );
  }
}

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
    final cs = Theme.of(context).colorScheme;
    final isCompleted = widget.goal.isCompleted;
    final done = _milestones.where((m) => m.isCompleted).length;

    return AriseCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.goal.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: isCompleted
                                ? cs.onSurface.withValues(alpha: 0.45)
                                : null,
                          ),
                    ),
                    if (widget.goal.description?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.goal.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.55),
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (isCompleted)
                const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF34D399), size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              DifficultyChip(difficulty: widget.goal.difficulty),
              const SizedBox(width: 8),
              _CategoryChip(category: widget.goal.category),
              const Spacer(),
              if (!isCompleted && widget.onComplete != null)
                SizedBox(
                  height: 30,
                  child: ElevatedButton(
                    onPressed: widget.onComplete,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    child: const Text('Complete'),
                  ),
                ),
            ],
          ),
          // ── Milestones ──
          const SizedBox(height: 8),
          Divider(color: cs.outlineVariant, height: 1),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () {
              setState(() => _milestonesOpen = !_milestonesOpen);
              if (!_milestonesOpen) _loadMilestones();
            },
            child: Row(
              children: [
                Icon(
                  _milestonesOpen ? Icons.expand_less : Icons.expand_more,
                  size: 14,
                  color: cs.onSurface.withValues(alpha: 0.4),
                ),
                const SizedBox(width: 4),
                Text(
                  'Milestones',
                  style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.5)),
                ),
                if (_milestones.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Text(
                    '($done/${_milestones.length})',
                    style: TextStyle(
                      fontSize: 11,
                      color: done == _milestones.length
                          ? const Color(0xFF34D399)
                          : cs.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_milestonesOpen) ...[
            const SizedBox(height: 8),
            if (_loadingMs)
              const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
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
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            ms.title,
                            style: TextStyle(
                              fontSize: 12,
                              color: ms.isCompleted
                                  ? cs.onSurface.withValues(alpha: 0.4)
                                  : cs.onSurface.withValues(alpha: 0.8),
                              decoration: ms.isCompleted ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                        if (!isCompleted)
                          GestureDetector(
                            onTap: () => _delete(ms.id),
                            child: Icon(Icons.close, size: 13, color: cs.onSurface.withValues(alpha: 0.3)),
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
                          style: const TextStyle(fontSize: 12),
                          decoration: const InputDecoration(
                            hintText: 'Milestone title...',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          ),
                          onSubmitted: (_) => _addMilestone(),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _submittingMs
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          : TextButton(
                              onPressed: _addMilestone,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                minimumSize: const Size(0, 30),
                              ),
                              child: const Text('Add', style: TextStyle(fontSize: 12)),
                            ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 14),
                        onPressed: () => setState(() { _addingMs = false; _newTitleCtrl.clear(); }),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  )
                else
                  TextButton.icon(
                    onPressed: () => setState(() => _addingMs = true),
                    icon: const Icon(Icons.add, size: 13),
                    label: const Text('Add milestone', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
            ],
          ],
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String category;

  const _CategoryChip({required this.category});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        category,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
      ),
    );
  }
}

// ── Create Goal Sheet ──────────────────────────────────────────────────────────

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
    _titleCtrl = TextEditingController(text: t?.title ?? '');
    _descCtrl  = TextEditingController(text: t?.description ?? '');
    _category  = t?.category ?? 'vitality';
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
                  width: 36,
                  height: 4,
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
                spacing: 8,
                runSpacing: 8,
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
              AriseButton(
                label: 'Create Goal',
                loading: _submitting,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Goal Templates Sheet ───────────────────────────────────────────────────────

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
            // Handle
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
            const SizedBox(height: 16),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Goal Templates',
                            style: Theme.of(context).textTheme.titleLarge),
                        Text('Pick one to pre-fill your goal',
                            style: Theme.of(context).textTheme.bodySmall),
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
            // Category filter
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
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
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
            // Content
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Text(_error!,
                              style: TextStyle(color: cs.error)),
                        )
                      : _visible.isEmpty
                          ? const Center(
                              child: Text('No templates in this category.'),
                            )
                          : ListView.separated(
                              controller: scrollCtrl,
                              padding: const EdgeInsets.all(16),
                              itemCount: _visible.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (_, i) {
                                final t = _visible[i];
                                return _TemplateCard(
                                  template: t,
                                  onUse: () => widget.onUse(t),
                                );
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
              Text(template.emoji,
                  style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(template.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            template.category,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: cs.primary),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: diffColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            template.difficulty,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: diffColor),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            template.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.65),
                ),
          ),
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
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.primary)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Complete Goal Sheet ────────────────────────────────────────────────────────

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
            const Icon(Icons.arrow_upward_rounded,
                size: 48, color: Color(0xFF34D399)),
            const SizedBox(height: 12),
            Text(
              'You reached Level $newLevel!',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Awesome!'),
          ),
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
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Complete Goal', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                widget.goal.title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.primary,
                    ),
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
                  if (v.trim().length < 30) {
                    return 'Please provide at least 30 characters of evidence';
                  }
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
              AriseButton(
                label: 'Complete & Earn XP',
                loading: _submitting,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
