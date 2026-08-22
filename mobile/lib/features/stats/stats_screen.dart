import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/arise_card.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/rank_badge.dart';
import 'stats_models.dart';
import 'stats_provider.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(statsSummaryProvider);
    final historyAsync = ref.watch(xpHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined, size: 20),
            onPressed: () {
              ref.read(statsSummaryProvider.notifier).refresh();
              ref.read(xpHistoryProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(statsSummaryProvider.notifier).refresh(),
            ref.read(xpHistoryProvider.notifier).refresh(),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            summaryAsync.when(
              loading: () => const _SummarySkeleton(),
              error: (e, _) => ErrorView(
                message: e.toString(),
                onRetry: () =>
                    ref.read(statsSummaryProvider.notifier).refresh(),
              ),
              data: (s) => _SummaryCards(summary: s),
            ),
            const SizedBox(height: 20),
            _XPHistorySection(historyAsync: historyAsync, ref: ref),
            const SizedBox(height: 20),
            summaryAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (s) => Column(
                children: [
                  _GoalsBreakdown(summary: s),
                  const SizedBox(height: 16),
                  if (s.topMissions.isNotEmpty) _TopMissions(summary: s),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Summary stat cards ─────────────────────────────────────────────────────────

class _SummaryCards extends StatelessWidget {
  final StatsSummary summary;

  const _SummaryCards({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Total XP',
                value: _formatXP(summary.totalXp),
                icon: Icons.star_rounded,
                color: const Color(0xFFEAB308),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Level',
                value: '${summary.currentLevel}',
                icon: Icons.trending_up_rounded,
                color: const Color(0xFF3B82F6),
                suffix: RankBadge(rank: summary.rank, size: 22),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Goals Done',
                value: '${summary.goalsCompleted}',
                icon: Icons.flag_rounded,
                color: const Color(0xFF22C55E),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Check-ins',
                value: '${summary.totalCheckins}',
                icon: Icons.task_alt_rounded,
                color: const Color(0xFFA855F7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Best Streak',
                value: '${summary.bestStreak}',
                icon: Icons.local_fire_department_rounded,
                color: const Color(0xFFF97316),
                suffix: Text(
                  'days',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Active Now',
                value: '${summary.missionsActive}',
                icon: Icons.bolt_rounded,
                color: const Color(0xFFEF4444),
                suffix: Text(
                  'missions',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatXP(int xp) {
    if (xp >= 1000) return '${(xp / 1000).toStringAsFixed(1)}k';
    return '$xp';
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Widget? suffix;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return AriseCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: color,
                      height: 1,
                    ),
              ),
              if (suffix != null) ...[
                const SizedBox(width: 4),
                suffix!,
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ── XP History chart ───────────────────────────────────────────────────────────

class _XPHistorySection extends ConsumerStatefulWidget {
  final AsyncValue<XPHistory> historyAsync;
  final WidgetRef ref;

  const _XPHistorySection({required this.historyAsync, required this.ref});

  @override
  ConsumerState<_XPHistorySection> createState() => _XPHistorySectionState();
}

class _XPHistorySectionState extends ConsumerState<_XPHistorySection> {
  int _days = 30;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AriseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('XP History',
                  style: Theme.of(context).textTheme.titleMedium),
              _DaysPicker(
                selected: _days,
                onChanged: (d) {
                  setState(() => _days = d);
                  widget.ref.read(xpHistoryProvider.notifier).setDays(d);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          widget.historyAsync.when(
            loading: () => const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SizedBox(
              height: 80,
              child: Center(
                child: Text(
                  'Failed to load XP history',
                  style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.4), fontSize: 13),
                ),
              ),
            ),
            data: (history) {
              if (history.entries.isEmpty) {
                return SizedBox(
                  height: 80,
                  child: Center(
                    child: Text(
                      'No XP activity in this period',
                      style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.4),
                          fontSize: 13),
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  _XPBarChart(history: history),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Legend(color: const Color(0xFF3B82F6), label: 'Goals'),
                      const SizedBox(width: 16),
                      _Legend(color: const Color(0xFFA855F7), label: 'Missions'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${history.totalXpInPeriod} XP earned in ${history.days} days',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.45),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DaysPicker extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _DaysPicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const options = [7, 30, 90];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: options.map((d) {
        final isSel = selected == d;
        return GestureDetector(
          onTap: () => onChanged(d),
          child: Container(
            margin: const EdgeInsets.only(left: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isSel
                  ? cs.primary.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSel
                    ? cs.primary.withValues(alpha: 0.4)
                    : Colors.transparent,
              ),
            ),
            child: Text(
              '${d}d',
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
                color: isSel ? cs.primary : cs.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _XPBarChart extends StatelessWidget {
  final XPHistory history;

  const _XPBarChart({required this.history});

  @override
  Widget build(BuildContext context) {
    final maxXp = history.maxXp.toDouble();
    const chartHeight = 100.0;

    return SizedBox(
      height: chartHeight,
      child: CustomPaint(
        size: const Size(double.infinity, chartHeight),
        painter: _XPChartPainter(
          entries: history.entries,
          maxXp: maxXp,
          goalColor: const Color(0xFF3B82F6),
          missionColor: const Color(0xFFA855F7),
        ),
      ),
    );
  }
}

class _XPChartPainter extends CustomPainter {
  final List<XPDayEntry> entries;
  final double maxXp;
  final Color goalColor;
  final Color missionColor;

  _XPChartPainter({
    required this.entries,
    required this.maxXp,
    required this.goalColor,
    required this.missionColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;

    final n = entries.length;
    final barWidth = (size.width / n).clamp(2.0, 16.0);
    final gap = (barWidth * 0.15).clamp(1.0, 3.0);
    final effectiveBarWidth = barWidth - gap;
    final halfBar = effectiveBarWidth / 2;
    final goalPaint = Paint()..color = goalColor.withValues(alpha: 0.85);
    final missionPaint = Paint()..color = missionColor.withValues(alpha: 0.85);

    for (int i = 0; i < n; i++) {
      final e = entries[i];
      final x = (i + 0.5) * (size.width / n);
      final totalH = maxXp > 0
          ? (e.xp / maxXp) * size.height
          : 0.0;
      final goalH = maxXp > 0
          ? (e.goalXp / maxXp) * size.height
          : 0.0;
      final missionH = totalH - goalH;

      if (goalH > 0) {
        final rect = Rect.fromLTWH(
          x - halfBar, size.height - goalH,
          effectiveBarWidth, goalH,
        );
        canvas.drawRRect(
          RRect.fromRectAndCorners(rect,
              topLeft: const Radius.circular(2),
              topRight: const Radius.circular(2)),
          goalPaint,
        );
      }

      if (missionH > 0) {
        final rect = Rect.fromLTWH(
          x - halfBar,
          size.height - totalH,
          effectiveBarWidth,
          missionH,
        );
        canvas.drawRRect(
          RRect.fromRectAndCorners(rect,
              topLeft: const Radius.circular(2),
              topRight: const Radius.circular(2)),
          missionPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_XPChartPainter old) =>
      old.entries != entries || old.maxXp != maxXp;
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 5),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

// ── Goals breakdown ────────────────────────────────────────────────────────────

class _GoalsBreakdown extends StatelessWidget {
  final StatsSummary summary;

  const _GoalsBreakdown({required this.summary});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final byDiff = summary.goalsByDifficulty;
    final byCategory = summary.goalsByCategory;

    return AriseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Goals Breakdown',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          if (byDiff.isNotEmpty) ...[
            Text('By Difficulty',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 10),
            ...byDiff.entries.map((e) => _ProgressRow(
                  label: _capitalize(e.key),
                  value: e.value,
                  total: summary.goalsCompleted,
                  color: _difficultyColor(e.key),
                )),
            const SizedBox(height: 14),
          ],
          if (byCategory.isNotEmpty) ...[
            Text('By Category',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 10),
            ...byCategory.entries.map((e) => _ProgressRow(
                  label: _capitalize(e.key),
                  value: e.value,
                  total: summary.goalsCompleted,
                  color: cs.primary,
                )),
          ],
        ],
      ),
    );
  }

  Color _difficultyColor(String d) {
    switch (d) {
      case 'easy':   return const Color(0xFF22C55E);
      case 'medium': return const Color(0xFFEAB308);
      case 'hard':   return const Color(0xFFF97316);
      case 'epic':   return const Color(0xFFA855F7);
      default:       return const Color(0xFF6B7280);
    }
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  final Color color;

  const _ProgressRow({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fraction = total > 0 ? (value / total).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: LayoutBuilder(builder: (_, c) {
              return Stack(
                children: [
                  Container(
                    height: 6,
                    width: c.maxWidth,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Container(
                    height: 6,
                    width: c.maxWidth * fraction,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(width: 8),
          Text(
            '$value',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

// ── Top missions ───────────────────────────────────────────────────────────────

class _TopMissions extends StatelessWidget {
  final StatsSummary summary;

  const _TopMissions({required this.summary});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AriseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Top Missions by Streak',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ...summary.topMissions.asMap().entries.map((entry) {
            final i = entry.key;
            final m = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Text(
                    '${i + 1}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.4),
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.title,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            FrequencyChip(frequency: m.frequency),
                            const SizedBox(width: 6),
                            Text(
                              '${m.completionCount} check-ins',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: cs.onSurface
                                        .withValues(alpha: 0.4),
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_fire_department,
                              color: Color(0xFFF97316), size: 14),
                          Text(
                            '${m.currentStreak}',
                            style: const TextStyle(
                              color: Color(0xFFF97316),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'best: ${m.longestStreak}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.35),
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Skeleton ───────────────────────────────────────────────────────────────────

class _SummarySkeleton extends StatelessWidget {
  const _SummarySkeleton();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final shimmer = cs.onSurface.withValues(alpha: 0.08);
    return Column(
      children: List.generate(3, (_) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Expanded(
              child: AriseCard(
                padding: const EdgeInsets.all(16),
                child: Container(height: 56, decoration: BoxDecoration(
                  color: shimmer, borderRadius: BorderRadius.circular(8))),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AriseCard(
                padding: const EdgeInsets.all(16),
                child: Container(height: 56, decoration: BoxDecoration(
                  color: shimmer, borderRadius: BorderRadius.circular(8))),
              ),
            ),
          ],
        ),
      )),
    );
  }
}
