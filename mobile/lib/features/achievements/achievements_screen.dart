import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/models/achievement.dart';
import '../../shared/widgets/arise_card.dart';
import '../../shared/widgets/error_view.dart';
import 'achievement_provider.dart';

// ── Category helpers ───────────────────────────────────────────────────────────

Color _categoryColor(String category) {
  switch (category) {
    case 'xp':       return const Color(0xFFEAB308);
    case 'goals':    return const Color(0xFF22C55E);
    case 'streak':   return const Color(0xFFF97316);
    case 'missions': return const Color(0xFFA855F7);
    case 'level':    return const Color(0xFF3B82F6);
    case 'rank':     return const Color(0xFFEF4444);
    default:         return const Color(0xFF6B7280);
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
  ConsumerState<AchievementsScreen> createState() =>
      _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  String _filter = 'all';
  bool _syncing = false;

  Future<void> _sync() async {
    setState(() => _syncing = true);
    try {
      final result =
          await ref.read(achievementProvider.notifier).sync();
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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        actions: [
          _syncing
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.sync_rounded),
                  onPressed: _sync,
                  tooltip: 'Sync achievements',
                ),
        ],
      ),
      body: achievementsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
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
            onRefresh: () => ref.read(achievementProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Progress summary
                AriseCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$unlockedCount / $total',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: cs.primary,
                                ),
                          ),
                          Text(
                            '${(pct * 100).round()}%',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: cs.onSurface.withValues(alpha: 0.5),
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 6,
                          backgroundColor:
                              cs.onSurface.withValues(alpha: 0.08),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(cs.primary),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'achievements unlocked',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.4),
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Category filter chips
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final cat = _categories[i];
                      final isSelected = _filter == cat;
                      final color = cat == 'all'
                          ? cs.primary
                          : _categoryColor(cat);
                      return GestureDetector(
                        onTap: () => setState(() => _filter = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? color.withValues(alpha: 0.5)
                                  : cs.onSurface.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Text(
                            cat == 'all'
                                ? 'All'
                                : _categoryLabel(cat),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected
                                  ? color
                                  : cs.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Achievement grid
                if (filtered.isEmpty)
                  EmptyState(
                    icon: Icons.emoji_events_outlined,
                    title: 'No achievements here',
                    subtitle: 'Keep going — you\'ll unlock some soon!',
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _AchievementCard(
                      achievement: filtered[i],
                    )
                        .animate()
                        .fadeIn(delay: (i * 40).ms, duration: 250.ms),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Achievement card ───────────────────────────────────────────────────────────

class _AchievementCard extends StatelessWidget {
  final AchievementResponse achievement;

  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final a = achievement;
    final color = _categoryColor(a.category);
    final unlocked = a.isUnlocked;

    return AriseCard(
      padding: const EdgeInsets.all(14),
      child: Opacity(
        opacity: unlocked ? 1.0 : 0.45,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: unlocked
                        ? color.withValues(alpha: 0.15)
                        : cs.onSurface.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: unlocked
                        ? Text(a.icon, style: const TextStyle(fontSize: 22))
                        : Icon(
                            Icons.lock_outline_rounded,
                            size: 18,
                            color: cs.onSurface.withValues(alpha: 0.3),
                          ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: unlocked
                        ? color.withValues(alpha: 0.12)
                        : cs.onSurface.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _categoryLabel(a.category),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: unlocked
                          ? color
                          : cs.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              a.title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: unlocked
                        ? cs.onSurface
                        : cs.onSurface.withValues(alpha: 0.5),
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Expanded(
              child: Text(
                a.description,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.4),
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (unlocked) ...[
              const SizedBox(height: 6),
              Text(
                '✓ ${_formatDate(a.unlockedAt!)}',
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day}/${local.month}/${local.year}';
  }
}

// ── Unlock sheet ───────────────────────────────────────────────────────────────

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
                width: 36,
                height: 4,
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
                          Text(
                            a.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            a.description,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color:
                                          cs.onSurface.withValues(alpha: 0.55),
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
