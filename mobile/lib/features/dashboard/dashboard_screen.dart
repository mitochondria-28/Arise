import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/models/character.dart';
import '../../core/models/mission.dart';
import '../../shared/widgets/arise_card.dart';
import '../../shared/widgets/xp_bar.dart';
import '../../shared/widgets/rank_badge.dart';
import '../../shared/widgets/error_view.dart';
import '../character/character_provider.dart';
import '../goals/goal_provider.dart';
import '../missions/mission_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final characterAsync = ref.watch(characterProvider);
    final goalsAsync = ref.watch(goalListProvider);
    final missionsAsync = ref.watch(missionListProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ARISE',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: cs.primary, letterSpacing: 4, fontSize: 12,
              ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined, size: 20),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
            },
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(characterProvider.notifier).refresh(),
            ref.read(goalListProvider.notifier).refresh(),
            ref.read(missionListProvider.notifier).refresh(),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Character hero card
            characterAsync.when(
              loading: () => const _HeroCardSkeleton(),
              error: (e, _) => ErrorView(
                message: e.toString(),
                onRetry: () => ref.read(characterProvider.notifier).refresh(),
              ),
              data: (character) => _HeroCard(character: character),
            ),
            const SizedBox(height: 16),

            // Quick stats row
            Row(
              children: [
                Expanded(
                  child: goalsAsync.when(
                    loading: () =>
                        const _QuickStat(icon: Icons.flag_outlined, label: 'Active Goals', value: '—'),
                    error: (_, __) =>
                        const _QuickStat(icon: Icons.flag_outlined, label: 'Active Goals', value: '!'),
                    data: (goals) => _QuickStat(
                      icon: Icons.flag_outlined,
                      label: 'Active Goals',
                      value: goals.where((g) => g.isActive).length.toString(),
                      onTap: () => context.go('/goals'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: missionsAsync.when(
                    loading: () =>
                        const _QuickStat(icon: Icons.task_alt_outlined, label: 'Due Now', value: '—'),
                    error: (_, __) =>
                        const _QuickStat(icon: Icons.task_alt_outlined, label: 'Due Now', value: '!'),
                    data: (missions) {
                      final dueCount = missions
                          .where((m) => m.isActive && m.canCheckinNow)
                          .length;
                      return _QuickStat(
                        icon: Icons.task_alt_outlined,
                        label: 'Due Now',
                        value: dueCount.toString(),
                        highlight: dueCount > 0,
                        onTap: () => context.go('/missions'),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Due missions section
            missionsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (missions) {
                final due = missions
                    .where((m) => m.isActive && m.canCheckinNow)
                    .toList();
                if (due.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Due Now', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    ...due.map((m) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _DueMissionTile(mission: m),
                        )),
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),

            // Active goals section
            goalsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (goals) {
                final active = goals.where((g) => g.isActive).toList();
                if (active.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Active Goals',
                            style: Theme.of(context).textTheme.titleMedium),
                        TextButton(
                          onPressed: () => context.go('/goals'),
                          child: const Text('View all'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...active.take(3).map((g) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: AriseCard(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            onTap: () => context.go('/goals'),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    g.title,
                                    style:
                                        Theme.of(context).textTheme.titleSmall,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                DifficultyChip(difficulty: g.difficulty),
                              ],
                            ),
                          ),
                        )),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DueMissionTile extends StatelessWidget {
  final MissionResponse mission;

  const _DueMissionTile({required this.mission});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AriseCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: () => context.go('/missions'),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.task_alt_outlined, color: cs.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission.title,
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                FrequencyChip(frequency: mission.frequency),
              ],
            ),
          ),
          if (mission.currentStreak > 0)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_fire_department,
                    color: Color(0xFFF97316), size: 14),
                Text(
                  '${mission.currentStreak}',
                  style: const TextStyle(
                    color: Color(0xFFF97316),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final CharacterResponse character;

  const _HeroCard({required this.character});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.primary.withValues(alpha: 0.06),
              cs.surface,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RankBadge(rank: character.rank, size: 48),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        character.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        'Rank ${character.rank} Hunter',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.primary,
                            ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Level',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(letterSpacing: 1),
                    ),
                    Text(
                      '${character.level}',
                      style:
                          Theme.of(context).textTheme.displaySmall?.copyWith(
                                color: cs.primary,
                                height: 1,
                              ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            XpBar(
              progress: character.xpProgress,
              currentXp: character.currentLevelXp,
              xpToNextLevel: character.xpToNextLevel,
            ),
            if (character.stats != null) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: character.stats!.toOrderedList().map<Widget>((e) {
                  return StatChip(category: e.key, value: e.value);
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeroCardSkeleton extends StatelessWidget {
  const _HeroCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 18, width: 120,
                        decoration: BoxDecoration(
                          color: cs.onSurface.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 12, width: 80,
                        decoration: BoxDecoration(
                          color: cs.onSurface.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;
  final VoidCallback? onTap;

  const _QuickStat({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = highlight ? const Color(0xFFF97316) : cs.primary;
    return AriseCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: color, height: 1.1,
                      ),
                ),
                Text(label, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
