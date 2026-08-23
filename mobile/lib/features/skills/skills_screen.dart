import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/app_exception.dart';
import '../../core/models/skill.dart';
import '../../shared/widgets/arise_button.dart';
import '../../shared/widgets/error_view.dart';
import 'skill_provider.dart';

// ── Category colours ───────────────────────────────────────────────────────────

const _catColor = {
  'vitality':     Color(0xFFEF4444),
  'strength':     Color(0xFFE67E22),
  'intelligence': Color(0xFF3B82F6),
  'wisdom':       Color(0xFFA855F7),
  'charisma':     Color(0xFFEAB308),
  'discipline':   Color(0xFF22C55E),
};

Color _color(String cat) => _catColor[cat] ?? const Color(0xFF6B7280);

const _maxLevel = 10;

// ── Level ring ─────────────────────────────────────────────────────────────────

class _LevelRing extends StatelessWidget {
  final int level;
  final Color color;

  const _LevelRing({required this.level, required this.color});

  @override
  Widget build(BuildContext context) {
    final pct = level / _maxLevel;
    return SizedBox(
      width: 52, height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: pct,
            backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            strokeWidth: 4,
          ),
          Text(
            '$level',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── My skill card ──────────────────────────────────────────────────────────────

class _MySkillCard extends StatelessWidget {
  final UserSkillResponse us;
  final VoidCallback onPractice;

  const _MySkillCard({required this.us, required this.onPractice});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _color(us.skill.category);

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _LevelRing(level: us.level, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${us.skill.emoji} ${us.skill.name}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          us.skill.category,
                          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
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
                Text(
                  '${us.sessionCount} sessions',
                  style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.5)),
                ),
                const Spacer(),
                if (us.level < _maxLevel)
                  Text(
                    '${us.sessionsToNextLevel} to L${us.level + 1}',
                    style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.5)),
                  )
                else
                  Text('Max Level', style: TextStyle(fontSize: 11, color: color)),
              ],
            ),
            if (us.level < _maxLevel) ...[
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: us.level * 5 == 0
                    ? 1.0
                    : ((us.level * 5 - us.sessionsToNextLevel) / (us.level * 5)).clamp(0.0, 1.0),
                backgroundColor: cs.onSurface.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                borderRadius: BorderRadius.circular(4),
                minHeight: 5,
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '+${us.xpPerSession} XP per session',
                  style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.5)),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: onPractice,
                  icon: const Icon(Icons.bolt_rounded, size: 14),
                  label: const Text('Practice', style: TextStyle(fontSize: 12)),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    backgroundColor: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Catalog card ───────────────────────────────────────────────────────────────

class _CatalogCard extends StatelessWidget {
  final SkillResponse skill;
  final bool unlocked;
  final bool unlocking;
  final VoidCallback onUnlock;

  const _CatalogCard({
    required this.skill,
    required this.unlocked,
    required this.unlocking,
    required this.onUnlock,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _color(skill.category);

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: unlocked ? color.withValues(alpha: 0.25) : cs.outlineVariant,
        ),
      ),
      child: Opacity(
        opacity: unlocked ? 0.7 : 1.0,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(skill.emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      skill.name,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  skill.category,
                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                skill.description,
                style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.65)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              if (unlocked)
                Row(
                  children: [
                    Icon(Icons.check_circle_outline, size: 14, color: color),
                    const SizedBox(width: 4),
                    Text('Unlocked', style: TextStyle(fontSize: 11, color: color)),
                  ],
                )
              else
                OutlinedButton.icon(
                  onPressed: unlocking ? null : onUnlock,
                  icon: unlocking
                      ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.lock_open_outlined, size: 14),
                  label: const Text('Unlock', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    side: BorderSide(color: color),
                    foregroundColor: color,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Practice sheet ─────────────────────────────────────────────────────────────

class _PracticeSheet extends ConsumerStatefulWidget {
  final UserSkillResponse userSkill;

  const _PracticeSheet({required this.userSkill});

  @override
  ConsumerState<_PracticeSheet> createState() => _PracticeSheetState();
}

class _PracticeSheetState extends ConsumerState<_PracticeSheet> {
  final _notesCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  bool _submitting = false;
  String? _error;
  PracticeResult? _result;

  @override
  void dispose() {
    _notesCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final notes = _notesCtrl.text.trim();
    if (notes.length < 10) {
      setState(() => _error = 'Notes must be at least 10 characters.');
      return;
    }
    setState(() { _submitting = true; _error = null; });
    try {
      final dur = int.tryParse(_durationCtrl.text.trim());
      final result = await ref.read(userSkillsProvider.notifier).practice(
            widget.userSkill.skillId,
            notes: notes,
            durationMinutes: dur,
          );
      if (mounted) setState(() { _result = result; _submitting = false; });
    } on AppException catch (e) {
      if (mounted) setState(() { _error = e.message; _submitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _color(widget.userSkill.skill.category);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
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
            if (_result != null) ...[
              Center(
                child: Column(
                  children: [
                    Text(widget.userSkill.skill.emoji, style: const TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    Text(
                      '+${_result!.xpAwarded} XP',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
                    ),
                    if (_result!.leveledUp) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Level up! Now Level ${_result!.userSkill.level}',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Great work. Keep the momentum going.',
                      style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.6)),
                    ),
                    const SizedBox(height: 24),
                    AriseButton(
                      label: 'Done',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Text(
                'Practice · ${widget.userSkill.skill.emoji} ${widget.userSkill.skill.name}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _LevelRing(level: widget.userSkill.level, color: color),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Level ${widget.userSkill.level} · ${widget.userSkill.sessionCount} sessions',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      if (widget.userSkill.level < _maxLevel)
                        Text(
                          '${widget.userSkill.sessionsToNextLevel} more to Level ${widget.userSkill.level + 1}',
                          style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
                        ),
                      Text(
                        '+${widget.userSkill.xpPerSession} XP this session',
                        style: TextStyle(fontSize: 12, color: color),
                      ),
                    ],
                  ),
                ],
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
                controller: _notesCtrl,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'What did you practice? *',
                  hintText: 'Describe what you actually did (min 10 characters)...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _durationCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duration in minutes (optional)',
                  hintText: 'e.g. 30',
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Longer sessions (30+ min) earn bonus XP (up to 2×).',
                style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.5)),
              ),
              const SizedBox(height: 24),
              AriseButton(
                label: _submitting
                    ? 'Logging...'
                    : 'Log Practice · +${widget.userSkill.xpPerSession} XP',
                loading: _submitting,
                onPressed: _submit,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Main screen ────────────────────────────────────────────────────────────────

class SkillsScreen extends ConsumerStatefulWidget {
  const SkillsScreen({super.key});

  @override
  ConsumerState<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends ConsumerState<SkillsScreen> {
  bool _showMy = true;
  String? _catFilter;
  String? _unlockingId;

  static const _categories = [
    'vitality', 'strength', 'intelligence',
    'wisdom', 'charisma', 'discipline',
  ];

  void _showPracticeSheet(UserSkillResponse us) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PracticeSheet(userSkill: us),
    );
  }

  Future<void> _unlock(String skillId) async {
    setState(() => _unlockingId = skillId);
    try {
      await ref.read(userSkillsProvider.notifier).unlock(skillId);
    } catch (_) {
      // Error is reflected in provider state
    } finally {
      if (mounted) setState(() => _unlockingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final myAsync = ref.watch(userSkillsProvider);
    final catAsync = ref.watch(skillCatalogProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Skill Tree')),
      body: Column(
        children: [
          // Segment control
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Container(
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(3),
              child: Row(
                children: [
                  _Tab(
                    label: myAsync.hasValue && myAsync.value!.isNotEmpty
                        ? 'My Skills (${myAsync.value!.length})'
                        : 'My Skills',
                    selected: _showMy,
                    onTap: () => setState(() => _showMy = true),
                  ),
                  _Tab(
                    label: 'Discover',
                    selected: !_showMy,
                    onTap: () => setState(() => _showMy = false),
                  ),
                ],
              ),
            ),
          ),
          // Category filters
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('All'),
                    selected: _catFilter == null,
                    onSelected: (_) => setState(() => _catFilter = null),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                ..._categories.map((c) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(c[0].toUpperCase() + c.substring(1)),
                        selected: _catFilter == c,
                        onSelected: (_) => setState(() =>
                            _catFilter = _catFilter == c ? null : c),
                        selectedColor: _color(c).withValues(alpha: 0.2),
                        visualDensity: VisualDensity.compact,
                      ),
                    )),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _showMy
                ? myAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => ErrorView(
                      message: e.toString(),
                      onRetry: () => ref.read(userSkillsProvider.notifier).refresh(),
                    ),
                    data: (skills) {
                      final filtered = _catFilter == null
                          ? skills
                          : skills.where((s) => s.skill.category == _catFilter).toList();
                      if (filtered.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bolt_outlined, size: 40, color: cs.onSurface.withValues(alpha: 0.3)),
                              const SizedBox(height: 12),
                              Text(
                                skills.isEmpty ? 'No skills unlocked yet' : 'No $_catFilter skills',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                skills.isEmpty
                                    ? 'Switch to "Discover" to unlock your first skill.'
                                    : 'Try a different category.',
                                style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5)),
                                textAlign: TextAlign.center,
                              ),
                              if (skills.isEmpty) ...[
                                const SizedBox(height: 16),
                                OutlinedButton(
                                  onPressed: () => setState(() => _showMy = false),
                                  child: const Text('Browse Skills'),
                                ),
                              ],
                            ],
                          ),
                        );
                      }
                      return RefreshIndicator(
                        onRefresh: () => ref.read(userSkillsProvider.notifier).refresh(),
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 340,
                            childAspectRatio: 1.0,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) => _MySkillCard(
                            us: filtered[i],
                            onPractice: () => _showPracticeSheet(filtered[i]),
                          ),
                        ),
                      );
                    },
                  )
                : catAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => ErrorView(
                      message: e.toString(),
                      onRetry: () => ref.read(skillCatalogProvider.notifier).refresh(),
                    ),
                    data: (catalog) {
                      final myIds = myAsync.hasValue
                          ? {for (final s in myAsync.value!) s.skillId}
                          : <String>{};
                      final filtered = _catFilter == null
                          ? catalog
                          : catalog.where((s) => s.category == _catFilter).toList();
                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 340,
                          childAspectRatio: 0.85,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => _CatalogCard(
                          skill: filtered[i],
                          unlocked: myIds.contains(filtered[i].id),
                          unlocking: _unlockingId == filtered[i].id,
                          onUnlock: () => _unlock(filtered[i].id),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Tab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? cs.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: selected
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: selected ? cs.primary : cs.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}
