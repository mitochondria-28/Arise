import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/character.dart';
import '../../shared/widgets/arise_card.dart';
import '../../shared/widgets/rank_badge.dart';
import '../../shared/widgets/xp_bar.dart';
import '../../shared/widgets/error_view.dart';
import 'character_provider.dart';

const _ranks = ['E', 'D', 'C', 'B', 'A', 'S'];

class CharacterScreen extends ConsumerWidget {
  const CharacterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(characterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Character'),
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/skills'),
            icon: const Icon(Icons.bolt_outlined, size: 18),
            label: const Text('Skills'),
          ),
          TextButton.icon(
            onPressed: () => context.push('/stats'),
            icon: const Icon(Icons.bar_chart_outlined, size: 18),
            label: const Text('Progress'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Profile & Settings',
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.read(characterProvider.notifier).refresh(),
        ),
        data: (character) => RefreshIndicator(
          onRefresh: () => ref.read(characterProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _CharacterHero(character: character),
              const SizedBox(height: 16),
              if (character.stats != null)
                _StatsCard(stats: character.stats!),
              const SizedBox(height: 16),
              _RankLadder(currentRank: character.rank),
            ],
          ),
        ),
      ),
    );
  }
}

class _CharacterHero extends StatelessWidget {
  final CharacterResponse character;

  const _CharacterHero({required this.character});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AriseCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          RankBadge(rank: character.rank, size: 64),
          const SizedBox(height: 12),
          Text(character.title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            'Level ${character.level}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: cs.primary,
                ),
          ),
          const SizedBox(height: 20),
          XpBar(
            progress: character.xpProgress,
            currentXp: character.currentLevelXp,
            xpToNextLevel: character.xpToNextLevel,
          ),
          const SizedBox(height: 8),
          Text(
            '${character.totalXp} total XP earned',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.4),
                ),
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final CharacterStats stats;

  const _StatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return AriseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Stats', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          ...stats.toOrderedList().map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _StatBar(category: entry.key, value: entry.value),
              )),
        ],
      ),
    );
  }
}

class _StatBar extends StatelessWidget {
  final String category;
  final int value;

  const _StatBar({required this.category, required this.value});

  @override
  Widget build(BuildContext context) {
    final color = statColor(category);
    final progress = (value / 100.0).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              statLabel(category),
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            Text(
              '$value',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (ctx, constraints) => Stack(
            children: [
              Container(
                height: 6,
                width: constraints.maxWidth,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Container(
                height: 6,
                width: constraints.maxWidth * progress,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RankLadder extends StatelessWidget {
  final String currentRank;

  const _RankLadder({required this.currentRank});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AriseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rank Progression', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _ranks.map((rank) {
              final isCurrent = rank == currentRank;
              return Column(
                children: [
                  RankBadge(rank: rank, size: isCurrent ? 44 : 34),
                  const SizedBox(height: 4),
                  if (isCurrent)
                    Text(
                      'YOU',
                      style: TextStyle(
                        color: cs.primary, fontSize: 8,
                        fontWeight: FontWeight.w800, letterSpacing: 1,
                      ),
                    ),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          ...ListTile.divideTiles(
            context: context,
            tiles: _ranks.map((rank) {
              final unlocked =
                  _ranks.indexOf(rank) <= _ranks.indexOf(currentRank);
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: RankBadge(rank: rank, size: 28),
                title: Text(
                  _rankName(rank),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: unlocked
                            ? null
                            : cs.onSurface.withValues(alpha: 0.35),
                      ),
                ),
                trailing: unlocked
                    ? const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF22C55E), size: 18)
                    : Icon(Icons.lock_outline_rounded,
                        color: cs.onSurface.withValues(alpha: 0.25), size: 18),
              );
            }),
          ),
        ],
      ),
    );
  }

  String _rankName(String rank) {
    switch (rank) {
      case 'E': return 'E — Novice';
      case 'D': return 'D — Apprentice';
      case 'C': return 'C — Adept';
      case 'B': return 'B — Expert';
      case 'A': return 'A — Master';
      case 'S': return 'S — Shadow Monarch';
      default: return rank;
    }
  }
}
