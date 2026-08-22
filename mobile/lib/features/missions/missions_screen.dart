import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/errors/app_exception.dart';
import '../../core/models/mission.dart';
import '../../core/network/api_client.dart';
import '../../shared/widgets/arise_card.dart';
import '../../shared/widgets/arise_button.dart';
import '../../shared/widgets/rank_badge.dart';
import '../../shared/widgets/error_view.dart';
import 'mission_provider.dart';

class MissionsScreen extends ConsumerStatefulWidget {
  const MissionsScreen({super.key});

  @override
  ConsumerState<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends ConsumerState<MissionsScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(missionListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Missions'),
        actions: [
          TextButton.icon(
            onPressed: () => _showTemplatesSheet(context, ref),
            icon: const Icon(Icons.grid_view_rounded, size: 18),
            label: const Text('Templates'),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showCreateSheet(context, ref),
            tooltip: 'New mission',
          ),
        ],
      ),
      body: Column(
        children: [
          _FilterTabs(selected: _filter, onSelected: (v) => setState(() => _filter = v)),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorView(
                message: e.toString(),
                onRetry: () => ref.read(missionListProvider.notifier).refresh(),
              ),
              data: (missions) {
                final filtered = _applyFilter(missions);
                if (filtered.isEmpty) {
                  return EmptyState(
                    icon: Icons.task_alt_outlined,
                    title: missions.isEmpty ? 'No missions yet' : 'No $_filter missions',
                    subtitle: missions.isEmpty
                        ? 'Missions are recurring habits. Build streaks to earn bonus XP.'
                        : 'Try a different filter.',
                    actionLabel:
                        missions.isEmpty ? 'Create first mission' : null,
                    onAction: missions.isEmpty
                        ? () => _showCreateSheet(context, ref)
                        : null,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(missionListProvider.notifier).refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _MissionCard(
                      mission: filtered[i],
                      onCheckin: () =>
                          _showCheckinSheet(context, ref, filtered[i]),
                    ).animate().fadeIn(
                          delay: (i * 50).ms,
                          duration: 280.ms,
                        ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<MissionResponse> _applyFilter(List<MissionResponse> missions) {
    final active = missions.where((m) => m.isActive).toList();
    if (_filter == 'all') return active;
    return active.where((m) => m.frequency == _filter).toList();
  }

  void _showCreateSheet(BuildContext ctx, WidgetRef ref, {MissionTemplate? template}) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateMissionSheet(ref: ref, template: template),
    );
  }

  void _showTemplatesSheet(BuildContext ctx, WidgetRef ref) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MissionTemplatesSheet(
        onUse: (t) => _showCreateSheet(ctx, ref, template: t),
      ),
    );
  }

  void _showCheckinSheet(BuildContext ctx, WidgetRef ref, MissionResponse m) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CheckinSheet(ref: ref, mission: m),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const _FilterTabs({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const options = ['all', 'daily', 'weekly', 'monthly'];
    return Container(
      height: 44,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: options.map((opt) {
          final isSelected = selected == opt;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isSelected ? cs.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  opt[0].toUpperCase() + opt.substring(1),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? cs.onSurface
                        : cs.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  final MissionResponse mission;
  final VoidCallback onCheckin;

  const _MissionCard({required this.mission, required this.onCheckin});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDue = mission.canCheckinNow;

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
                    Row(
                      children: [
                        if (isDue)
                          Container(
                            width: 7,
                            height: 7,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF97316),
                              shape: BoxShape.circle,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            mission.title,
                            style:
                                Theme.of(context).textTheme.titleSmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (mission.description?.isNotEmpty == true) ...[
                      const SizedBox(height: 3),
                      Text(
                        mission.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.5),
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (mission.currentStreak > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF97316).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department,
                          color: Color(0xFFF97316), size: 14),
                      const SizedBox(width: 3),
                      Text(
                        '${mission.currentStreak}',
                        style: const TextStyle(
                          color: Color(0xFFF97316),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              FrequencyChip(frequency: mission.frequency),
              const SizedBox(width: 6),
              DifficultyChip(difficulty: mission.difficulty),
              const Spacer(),
              SizedBox(
                height: 30,
                child: ElevatedButton(
                  onPressed: onCheckin,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  child: const Text('Check in'),
                ),
              ),
            ],
          ),
          if (mission.completionCount > 0) ...[
            const SizedBox(height: 8),
            Text(
              '${mission.completionCount} total check-ins · best streak ${mission.longestStreak}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.35),
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Create Mission Sheet ───────────────────────────────────────────────────────

class _CreateMissionSheet extends StatefulWidget {
  final WidgetRef ref;
  final MissionTemplate? template;

  const _CreateMissionSheet({required this.ref, this.template});

  @override
  State<_CreateMissionSheet> createState() => _CreateMissionSheetState();
}

class _CreateMissionSheetState extends State<_CreateMissionSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late String _category;
  late String _frequency;
  late String _difficulty;
  bool _submitting = false;
  String? _error;

  static const _categories = [
    'vitality', 'strength', 'intelligence',
    'wisdom', 'charisma', 'discipline',
  ];
  static const _difficulties = ['easy', 'medium', 'hard', 'epic'];
  static const _frequencies = ['daily', 'weekly', 'monthly'];

  @override
  void initState() {
    super.initState();
    final t = widget.template;
    _titleCtrl = TextEditingController(text: t?.title ?? '');
    _descCtrl  = TextEditingController(text: t?.description ?? '');
    _category  = t?.category ?? 'vitality';
    _frequency = t?.frequency ?? 'daily';
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
      await widget.ref.read(missionListProvider.notifier).create(
            CreateMissionRequest(
              title: _titleCtrl.text.trim(),
              description: _descCtrl.text.trim().isEmpty
                  ? null
                  : _descCtrl.text.trim(),
              category: _category,
              frequency: _frequency,
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
              Text(
                widget.template != null ? 'Mission from Template' : 'New Mission',
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
                decoration: const InputDecoration(labelText: 'Mission title'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (v.trim().length < 5) return 'At least 5 characters';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descCtrl,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),
              Text('Frequency', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Row(
                children: _frequencies.map((f) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f[0].toUpperCase() + f.substring(1)),
                      selected: _frequency == f,
                      onSelected: (_) => setState(() => _frequency = f),
                    ),
                  ),
                )).toList(),
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
              AriseButton(label: 'Create Mission', loading: _submitting, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Checkin Sheet ──────────────────────────────────────────────────────────────

class _CheckinSheet extends StatefulWidget {
  final WidgetRef ref;
  final MissionResponse mission;

  const _CheckinSheet({required this.ref, required this.mission});

  @override
  State<_CheckinSheet> createState() => _CheckinSheetState();
}

class _CheckinSheetState extends State<_CheckinSheet> {
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
      final result =
          await widget.ref.read(missionListProvider.notifier).checkin(
                widget.mission.id,
                CheckinRequest(
                  evidenceText: _evidenceCtrl.text.trim(),
                  reflection: _reflectionCtrl.text.trim().isEmpty
                      ? null
                      : _reflectionCtrl.text.trim(),
                  effortLevel: _effort,
                ),
              );
      if (mounted) {
        Navigator.of(context).pop();
        final msg = result.leveledUp
            ? 'Level up! You reached Level ${result.levelsGained.last}! +${result.xpAwarded} XP'
            : 'Streak: ${result.newStreak} 🔥  +${result.xpAwarded} XP';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: const Color(0xFF34D399),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } on AppException catch (e) {
      setState(() { _error = e.message; _submitting = false; });
    }
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
              Text('Check In', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                widget.mission.title,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: cs.primary),
              ),
              if (widget.mission.currentStreak > 0) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.local_fire_department,
                        color: Color(0xFFF97316), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.mission.currentStreak}-day streak',
                      style: const TextStyle(
                          color: Color(0xFFF97316),
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                  ],
                ),
              ],
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
                  hintText: 'Be specific about what you completed...',
                  alignLabelWithHint: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (v.trim().length < 30) {
                    return 'Provide at least 30 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _reflectionCtrl,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Reflection (optional)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),
              Text('Effort level', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (i) {
                  final val = i + 1;
                  final sel = _effort >= val;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _effort = val),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        height: 40,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: sel
                              ? cs.primary.withValues(alpha: 0.9)
                              : cs.onSurface.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$val',
                          style: TextStyle(
                            color: sel ? cs.onPrimary : cs.onSurface.withValues(alpha: 0.5),
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
                label: 'Submit Check-in',
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

// ── Mission Templates Sheet ────────────────────────────────────────────────────

class _MissionTemplatesSheet extends ConsumerStatefulWidget {
  final void Function(MissionTemplate) onUse;

  const _MissionTemplatesSheet({required this.onUse});

  @override
  ConsumerState<_MissionTemplatesSheet> createState() =>
      _MissionTemplatesSheetState();
}

class _MissionTemplatesSheetState
    extends ConsumerState<_MissionTemplatesSheet> {
  List<MissionTemplate> _all = [];
  bool _loading = true;
  String? _error;
  String? _catFilter;
  String? _freqFilter;

  static const _categories = [
    'vitality', 'strength', 'intelligence',
    'wisdom', 'charisma', 'discipline',
  ];
  static const _frequencies = ['daily', 'weekly', 'monthly'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final dio = ref.read(dioProvider);
      final resp = await dio.get<List<dynamic>>('/missions/templates');
      final templates = (resp.data ?? [])
          .map((e) => MissionTemplate.fromJson(e as Map<String, dynamic>))
          .toList();
      if (mounted) setState(() { _all = templates; _loading = false; });
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.response?.data?['detail'] as String? ?? 'Failed to load templates';
          _loading = false;
        });
      }
    }
  }

  List<MissionTemplate> get _visible => _all.where((t) {
        if (_catFilter != null && t.category != _catFilter) return false;
        if (_freqFilter != null && t.frequency != _freqFilter) return false;
        return true;
      }).toList();

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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Text('Mission Templates',
                      style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Category filter
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: const Text('All'),
                      selected: _catFilter == null,
                      onSelected: (_) => setState(() => _catFilter = null),
                    ),
                  ),
                  ..._categories.map((c) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(c[0].toUpperCase() + c.substring(1)),
                          selected: _catFilter == c,
                          onSelected: (_) => setState(() =>
                              _catFilter = _catFilter == c ? null : c),
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 6),
            // Frequency filter
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: const Text('Any frequency'),
                      selected: _freqFilter == null,
                      onSelected: (_) => setState(() => _freqFilter = null),
                    ),
                  ),
                  ..._frequencies.map((f) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(f[0].toUpperCase() + f.substring(1)),
                          selected: _freqFilter == f,
                          onSelected: (_) => setState(() =>
                              _freqFilter = _freqFilter == f ? null : f),
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Text(_error!,
                              style: TextStyle(color: cs.error)))
                      : _visible.isEmpty
                          ? Center(
                              child: Text('No templates',
                                  style: TextStyle(
                                      color: cs.onSurface
                                          .withValues(alpha: 0.5))))
                          : ListView.builder(
                              controller: scrollCtrl,
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              itemCount: _visible.length,
                              itemBuilder: (_, i) => _MissionTemplateCard(
                                template: _visible[i],
                                onUse: () {
                                  Navigator.of(context).pop();
                                  widget.onUse(_visible[i]);
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissionTemplateCard extends StatelessWidget {
  final MissionTemplate template;
  final VoidCallback onUse;

  const _MissionTemplateCard({required this.template, required this.onUse});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(template.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(template.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _Badge(template.category, cs.primary),
                      const SizedBox(width: 6),
                      _Badge(template.frequency, const Color(0xFF8B5CF6)),
                      const SizedBox(width: 6),
                      _Badge(template.difficulty, cs.secondary),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    template.description,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: cs.onSurface.withValues(alpha: 0.7)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: onUse,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('Use this template'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
