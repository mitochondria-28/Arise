import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/models/achievement.dart';
import '../../shared/widgets/error_view.dart';
import 'achievement_provider.dart';

// ── Solo Leveling palette ──────────────────────────────────────────────────────
const _kBg     = Color(0xFF0A0A0F);
const _kCard   = Color(0xFF1C1C2E);
const _kBorder = Color(0xFF2A2A3E);
const _kBlue   = Color(0xFF4FC3F7);
const _kGold   = Color(0xFFFFD700);
const _kGreen  = Color(0xFF34D399);
const _kOrange = Color(0xFFF97316);
const _kPurple = Color(0xFF9B59B6);
const _kRed    = Color(0xFFEF4444);
const _kText   = Color(0xFFE2E8F0);
const _kDim    = Color(0xFF64748B);

// ── Category helpers ───────────────────────────────────────────────────────────
Color _categoryColor(String category) {
  switch (category) {
    case 'xp':       return _kGold;
    case 'goals':    return _kGreen;
    case 'streak':   return _kOrange;
    case 'missions': return _kPurple;
    case 'level':    return _kBlue;
    case 'rank':     return _kRed;
    default:         return _kDim;
  }
}

String _categoryLabel(String category) {
  switch (category) {
    case 'xp':       return 'XP';
    case 'goals':    return 'Goals';
    case 'streak':   return 'Streak';
    case 'missions': return 'Missions';
    case 'level':    return 'Level';
    case 'rank':     return 'Rank';
    default:         return category;
  }
}

const _categories = ['all', 'xp', 'goals', 'streak', 'missions', 'level', 'rank'];

// ── Screen ─────────────────────────────────────────────────────────────────────
class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  String _filter = 'all';
  bool _syncing = false;

  Future<void> _sync() async {
    setState(() => _syncing = true);
    try {
      final result = await ref.read(achievementProvider.notifier).sync();
      if (!mounted) return;
      if (result.newlyUnlocked.isNotEmpty) {
        _showUnlockSheet(result.newlyUnlocked);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All caught up — no new achievements'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  void _showUnlockSheet(List<AchievementResponse> unlocked) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UnlockSheet(achievements: unlocked),
    );
  }

  @override
  Widget build(BuildContext context) {
    final achievementsAsync = ref.watch(achievementProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _kBg,
        body: achievementsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: _kBlue, strokeWidth: 2),
          ),
          error: (e, _) => ErrorView(
            message: e.toString(),
            onRetry: () => ref.read(achievementProvider.notifier).refresh(),
          ),
          data: (achievements) {
            final filtered = _filter == 'all'
                ? achievements
                : achievements.where((a) => a.category == _filter).toList();
            final unlockedCount = achievements.where((a) => a.isUnlocked).length;
            final total = achievements.length;
            final pct = total > 0 ? unlockedCount / total : 0.0;

            return RefreshIndicator(
              color: _kBlue,
              backgroundColor: _kCard,
              onRefresh: () => ref.read(achievementProvider.notifier).refresh(),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _AchievementsHeader(
                      unlockedCount: unlockedCount,
                      total: total,
                      pct: pct,
                      syncing: _syncing,
                      onSync: _sync,
                    ).animate().fadeIn(duration: 350.ms),
                  ),
                  SliverToBoxAdapter(
                    child: _CategoryFilter(
                      selected: _filter,
                      onSelected: (v) => setState(() => _filter = v),
                    ),
                  ),
                  if (filtered.isEmpty)
                    SliverFillRemaining(
                      child: _EmptyAchievements(filter: _filter),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => _AchievementCard(achievement: filtered[i])
                              .animate()
                              .fadeIn(delay: (i * 40).ms, duration: 300.ms)
                              .scale(
                                begin: const Offset(0.92, 0.92),
                                end: const Offset(1.0, 1.0),
                                duration: 300.ms,
                              ),
                          childCount: filtered.length,
                        ),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.82,
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

// ── Achievements Header ────────────────────────────────────────────────────────
class _AchievementsHeader extends StatelessWidget {
  final int unlockedCount;
  final int total;
  final double pct;
  final bool syncing;
  final VoidCallback onSync;

  const _AchievementsHeader({
    required this.unlockedCount,
    required this.total,
    required this.pct,
    required this.syncing,
    required this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(16, top + 14, 16, 20),
      decoration: const BoxDecoration(
        color: _kCard,
        border: Border(bottom: BorderSide(color: _kBorder, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(width: 5, height: 5, decoration: const BoxDecoration(color: _kGold, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        const Text('HALL OF FAME', style: TextStyle(color: _kGold, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2.5)),
                        const SizedBox(width: 6),
                        Container(width: 5, height: 5, decoration: const BoxDecoration(color: _kGold, shape: BoxShape.circle)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    const Text('Achievements', style: TextStyle(color: _kText, fontSize: 20, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: syncing ? null : onSync,
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: _kGold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _kGold.withValues(alpha: 0.3)),
                  ),
                  child: syncing
                      ? const Padding(
                          padding: EdgeInsets.all(9),
                          child: CircularProgressIndicator(color: _kGold, strokeWidth: 2),
                        )
                      : const Icon(Icons.sync_rounded, color: _kGold, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: unlockedCount.toDouble()),
                duration: const Duration(milliseconds: 800),
                builder: (_, val, __) => Text(
                  '${val.round()}',
                  style: const TextStyle(color: _kGold, fontSize: 34, fontWeight: FontWeight.w800, height: 1),
                ),
              ),
              Text(' / $total', style: const TextStyle(color: _kDim, fontSize: 20, fontWeight: FontWeight.w500)),
              const SizedBox(width: 10),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text('UNLOCKED', style: TextStyle(color: _kDim, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(color: _kBorder, borderRadius: BorderRadius.circular(3)),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: pct),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (_, val, __) => FractionallySizedBox(
                  widthFactor: val.clamp(0.0, 1.0),
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_kGold, _kOrange]),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [BoxShadow(color: _kGold.withValues(alpha: 0.5), blurRadius: 6)],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('${(pct * 100).round()}% complete', style: const TextStyle(color: _kDim, fontSize: 10)),
        ],
      ),
    );
  }
}

// ── Category Filter ────────────────────────────────────────────────────────────
class _CategoryFilter extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const _CategoryFilter({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = _categories[i];
          final isSelected = selected == cat;
          final color = cat == 'all' ? _kBlue : _categoryColor(cat);
          return GestureDetector(
            onTap: () => onSelected(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? color.withValues(alpha: 0.15) : _kCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? color.withValues(alpha: 0.5) : _kBorder,
                ),
              ),
              child: Text(
                cat == 'all' ? 'ALL' : _categoryLabel(cat).toUpperCase(),
                style: TextStyle(
                  fontSize: 9, fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: isSelected ? color : _kDim,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Achievement Card ───────────────────────────────────────────────────────────
class _AchievementCard extends StatelessWidget {
  final AchievementResponse achievement;

  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final a        = achievement;
    final color    = _categoryColor(a.category);
    final unlocked = a.isUnlocked;

    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: unlocked ? color.withValues(alpha: 0.4) : _kBorder,
        ),
        boxShadow: unlocked
            ? [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 16, spreadRadius: 0)]
            : null,
      ),
      child: Opacity(
        opacity: unlocked ? 1.0 : 0.4,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: unlocked ? color.withValues(alpha: 0.15) : _kBorder,
                      borderRadius: BorderRadius.circular(10),
                      border: unlocked ? Border.all(color: color.withValues(alpha: 0.3)) : null,
                    ),
                    child: Center(
                      child: unlocked
                          ? Text(a.icon, style: const TextStyle(fontSize: 22))
                          : const Icon(Icons.lock_outline_rounded, size: 18, color: _kDim),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: color.withValues(alpha: 0.25)),
                    ),
                    child: Text(
                      _categoryLabel(a.category).toUpperCase(),
                      style: TextStyle(
                        fontSize: 8, fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: unlocked ? color : _kDim,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                a.title,
                style: TextStyle(
                  color: unlocked ? _kText : _kDim,
                  fontSize: 13, fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  a.description,
                  style: const TextStyle(color: _kDim, fontSize: 10),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unlocked) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.check_circle, color: color, size: 10),
                    const SizedBox(width: 3),
                    Text(
                      _formatDate(a.unlockedAt!),
                      style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day}/${local.month}/${local.year}';
  }
}

// ── Empty State ────────────────────────────────────────────────────────────────
class _EmptyAchievements extends StatelessWidget {
  final String filter;

  const _EmptyAchievements({required this.filter});

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
            child: const Icon(Icons.emoji_events_outlined, color: _kGold, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            filter == 'all' ? 'NO ACHIEVEMENTS' : 'NONE IN THIS CATEGORY',
            style: const TextStyle(color: _kText, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.5),
          ),
          const SizedBox(height: 8),
          const Text('Keep training. Your achievements await.', style: TextStyle(color: _kDim, fontSize: 12)),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UNLOCK SHEET — preserved exactly
// ─────────────────────────────────────────────────────────────────────────────

class _UnlockSheet extends StatelessWidget {
  final List<AchievementResponse> achievements;

  const _UnlockSheet({required this.achievements});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      maxChildSize: 0.85,
      minChildSize: 0.35,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
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
            const SizedBox(height: 24),
            Text(
              achievements.length == 1
                  ? 'Achievement Unlocked!'
                  : '${achievements.length} Achievements Unlocked!',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ...achievements.map((a) {
              final color = _categoryColor(a.category);
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Text(a.icon, style: const TextStyle(fontSize: 32))
                        .animate()
                        .scale(
                          begin: const Offset(0.4, 0.4),
                          end: const Offset(1.0, 1.0),
                          duration: 400.ms,
                          curve: Curves.elasticOut,
                        ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.title, style: Theme.of(context).textTheme.titleMedium),
                          Text(
                            a.description,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: cs.onSurface.withValues(alpha: 0.55),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Awesome!'),
            ),
          ],
        ),
      ),
    );
  }
}
