import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/errors/app_exception.dart';
import '../../core/models/mission.dart';
import '../../core/network/api_client.dart';
import '../../shared/widgets/arise_button.dart';
import '../../shared/widgets/error_view.dart';
import 'mission_provider.dart';

// ── Solo Leveling palette ──────────────────────────────────────────────────────
const _kBg     = Color(0xFF0A0A0F);
const _kCard   = Color(0xFF1C1C2E);
const _kBorder = Color(0xFF2A2A3E);
const _kBlue   = Color(0xFF4FC3F7);
const _kPurple = Color(0xFF9B59B6);
const _kGold   = Color(0xFFFFD700);
const _kGreen  = Color(0xFF34D399);
const _kOrange = Color(0xFFE67E22);
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

Color _freqColor(String f) {
  switch (f) {
    case 'daily':   return _kBlue;
    case 'weekly':  return _kPurple;
    case 'monthly': return _kGold;
    default:        return _kDim;
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _kBg,
        body: Column(
          children: [
            _MissionHeader(
              onAdd: () => _showCreateSheet(context, ref),
              onTemplates: () => _showTemplatesSheet(context, ref),
            ),
            _FilterTabs(
              selected: _filter,
              onSelected: (v) => setState(() => _filter = v),
            ),
            Expanded(
              child: async.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: _kBlue, strokeWidth: 2),
                ),
                error: (e, _) => ErrorView(
                  message: e.toString(),
                  onRetry: () => ref.read(missionListProvider.notifier).refresh(),
                ),
                data: (missions) {
                  final filtered = _applyFilter(missions);
                  if (filtered.isEmpty) {
                    return _EmptyMissions(
                      isEmpty: missions.isEmpty,
                      filter: _filter,
                      onCreate: () => _showCreateSheet(context, ref),
                    );
                  }
                  return RefreshIndicator(
                    color: _kBlue,
                    backgroundColor: _kCard,
                    onRefresh: () => ref.read(missionListProvider.notifier).refresh(),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _MissionCard(
                          mission: filtered[i],
                          onCheckin: () => _showCheckinSheet(context, ref, filtered[i]),
                        )
                            .animate()
                            .fadeIn(delay: (i * 50).ms, duration: 300.ms)
                            .slideY(begin: 0.08, end: 0, duration: 300.ms),
                      ),
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

// ── Mission Header ─────────────────────────────────────────────────────────────
class _MissionHeader extends StatelessWidget {
  final VoidCallback onAdd;
  final VoidCallback onTemplates;

  const _MissionHeader({required this.onAdd, required this.onTemplates});

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
                  Container(
                    width: 5, height: 5,
                    decoration: const BoxDecoration(color: _kBlue, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'MISSION LOG',
                    style: TextStyle(
                      color: _kBlue, fontSize: 10,
                      fontWeight: FontWeight.w700, letterSpacing: 2.5,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 5, height: 5,
                    decoration: const BoxDecoration(color: _kBlue, shape: BoxShape.circle),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              const Text(
                'Daily Quests & Habits',
                style: TextStyle(color: _kText, fontSize: 18, fontWeight: FontWeight.w700),
              ),
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
                  Text(
                    'TEMPLATES',
                    style: TextStyle(
                      color: _kPurple, fontSize: 9,
                      fontWeight: FontWeight.w700, letterSpacing: 1,
                    ),
                  ),
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
                color: _kBlue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kBlue.withValues(alpha: 0.4)),
              ),
              child: const Icon(Icons.add_rounded, color: _kBlue, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter Tabs ────────────────────────────────────────────────────────────────
class _FilterTabs extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const _FilterTabs({required this.selected, required this.onSelected});

  static const _options = ['all', 'daily', 'weekly', 'monthly'];
  static const _colors = {
    'all': _kText, 'daily': _kBlue, 'weekly': _kPurple, 'monthly': _kGold,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
      color: _kBg,
      child: Row(
        children: _options.map((opt) {
          final isSelected = selected == opt;
          final color = _colors[opt] ?? _kText;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: isSelected ? color.withValues(alpha: 0.12) : _kCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? color.withValues(alpha: 0.5) : _kBorder,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  opt == 'all' ? 'ALL' : opt.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: isSelected ? color : _kDim,
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

// ── Mission Card ───────────────────────────────────────────────────────────────
class _MissionCard extends StatelessWidget {
  final MissionResponse mission;
  final VoidCallback onCheckin;

  const _MissionCard({required this.mission, required this.onCheckin});

  @override
  Widget build(BuildContext context) {
    final isDue   = mission.canCheckinNow;
    final dColor  = _diffColor(mission.difficulty);
    final cColor  = _catColor(mission.category);
    final fColor  = _freqColor(mission.frequency);

    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDue ? dColor.withValues(alpha: 0.5) : _kBorder,
        ),
        boxShadow: isDue
            ? [BoxShadow(color: dColor.withValues(alpha: 0.12), blurRadius: 12)]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(left: 0, top: 0, bottom: 0, child: Container(width: 4, color: dColor)),
          Padding(
            padding: const EdgeInsets.fromLTRB(17, 13, 13, 13),
            child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 34, height: 34,
                          decoration: BoxDecoration(
                            color: cColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(_catIcon(mission.category), color: cColor, size: 16),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (isDue) ...[
                                    Container(
                                      width: 6, height: 6,
                                      decoration: const BoxDecoration(
                                        color: _kOrange, shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                  ],
                                  Expanded(
                                    child: Text(
                                      mission.title,
                                      style: const TextStyle(
                                        color: _kText, fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              if (mission.description?.isNotEmpty == true) ...[
                                const SizedBox(height: 3),
                                Text(
                                  mission.description ?? '',
                                  style: const TextStyle(color: _kDim, fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (mission.currentStreak > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                            decoration: BoxDecoration(
                              color: _kOrange.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _kOrange.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.local_fire_department, color: _kOrange, size: 12),
                                const SizedBox(width: 3),
                                Text(
                                  '${mission.currentStreak}',
                                  style: const TextStyle(
                                    color: _kOrange, fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _SysTag(mission.frequency.toUpperCase(), fColor),
                        const SizedBox(width: 6),
                        _SysTag(mission.difficulty.toUpperCase(), dColor),
                        const Spacer(),
                        GestureDetector(
                          onTap: onCheckin,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDue ? _kBlue : _kBlue.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDue ? _kBlue : _kBlue.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              'CHECK IN',
                              style: TextStyle(
                                color: isDue ? _kBg : _kBlue,
                                fontSize: 9, fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (mission.completionCount > 0) ...[
                      const SizedBox(height: 7),
                      Text(
                        '${mission.completionCount} check-ins · best streak ${mission.longestStreak}',
                        style: TextStyle(color: _kDim.withValues(alpha: 0.6), fontSize: 10),
                      ),
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
        style: TextStyle(
          color: color, fontSize: 9,
          fontWeight: FontWeight.w700, letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────
class _EmptyMissions extends StatelessWidget {
  final bool isEmpty;
  final String filter;
  final VoidCallback onCreate;

  const _EmptyMissions({
    required this.isEmpty,
    required this.filter,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: _kBlue.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: _kBlue.withValues(alpha: 0.2)),
            ),
            child: const Icon(Icons.task_alt_outlined, color: _kBlue, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            isEmpty ? 'NO MISSIONS YET' : 'NO ${filter.toUpperCase()} MISSIONS',
            style: const TextStyle(
              color: _kText, fontSize: 13,
              fontWeight: FontWeight.w700, letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isEmpty
                ? 'Build recurring habits. Earn bonus XP with streaks.'
                : 'Try a different frequency filter.',
            style: const TextStyle(color: _kDim, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          if (isEmpty) ...[
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onCreate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: _kBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _kBlue.withValues(alpha: 0.4)),
                ),
                child: const Text(
                  'CREATE FIRST MISSION',
                  style: TextStyle(
                    color: _kBlue, fontSize: 10,
                    fontWeight: FontWeight.w700, letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM SHEETS — preserved exactly
// ─────────────────────────────────────────────────────────────────────────────

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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.primary),
              ),
              if (widget.mission.currentStreak > 0) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.local_fire_department, color: Color(0xFFE67E22), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.mission.currentStreak}-day streak',
                      style: const TextStyle(
                          color: Color(0xFFE67E22), fontWeight: FontWeight.w600, fontSize: 13),
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
                  if (v.trim().length < 30) return 'Provide at least 30 characters';
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
              AriseButton(label: 'Submit Check-in', loading: _submitting, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}

class _MissionTemplatesSheet extends ConsumerStatefulWidget {
  final void Function(MissionTemplate) onUse;

  const _MissionTemplatesSheet({required this.onUse});

  @override
  ConsumerState<_MissionTemplatesSheet> createState() =>
      _MissionTemplatesSheetState();
}

class _MissionTemplatesSheetState extends ConsumerState<_MissionTemplatesSheet> {
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
                  Text('Mission Templates', style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
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
                      ? Center(child: Text(_error!, style: TextStyle(color: cs.error)))
                      : _visible.isEmpty
                          ? Center(
                              child: Text('No templates',
                                  style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5))))
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
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}
