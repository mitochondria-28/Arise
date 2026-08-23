import 'package:flutter/material.dart';

// Canonical stat order and colors — kept in sync with web/src/shared/lib/constants.ts
const Map<String, String> _statLabels = {
  'vitality':     'Vitality',
  'strength':     'Strength',
  'intelligence': 'Intelligence',
  'wisdom':       'Wisdom',
  'charisma':     'Charisma',
  'discipline':   'Discipline',
};

Color statColor(String category) {
  switch (category) {
    case 'vitality':      return const Color(0xFFEF4444);
    case 'strength':      return const Color(0xFFE67E22);
    case 'intelligence':  return const Color(0xFF3B82F6);
    case 'wisdom':        return const Color(0xFFA855F7);
    case 'charisma':      return const Color(0xFFEAB308);
    case 'discipline':    return const Color(0xFF22C55E);
    default:              return const Color(0xFF6B7280);
  }
}

String statLabel(String category) => _statLabels[category] ?? category;

class RankBadge extends StatelessWidget {
  final String rank;
  final double size;

  const RankBadge({super.key, required this.rank, this.size = 36});

  Color _color() {
    switch (rank) {
      case 'E': return const Color(0xFF6B7280);
      case 'D': return const Color(0xFF22C55E);
      case 'C': return const Color(0xFF3B82F6);
      case 'B': return const Color(0xFFA855F7);
      case 'A': return const Color(0xFFE67E22);
      case 'S': return const Color(0xFFEF4444);
      default:  return const Color(0xFF6B7280);
    }
  }

  bool get _glows => rank == 'A' || rank == 'S';

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: color, width: 1.5),
        boxShadow: _glows
            ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 10)]
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        rank,
        style: TextStyle(
          color: color,
          fontSize: size * 0.45,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class StatChip extends StatelessWidget {
  final String category;
  final int value;

  const StatChip({super.key, required this.category, required this.value});

  @override
  Widget build(BuildContext context) {
    final color = statColor(category);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          '${statLabel(category)} $value',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
        ),
      ],
    );
  }
}

class DifficultyChip extends StatelessWidget {
  final String difficulty;

  const DifficultyChip({super.key, required this.difficulty});

  Color _color() {
    switch (difficulty) {
      case 'easy':   return const Color(0xFF22C55E);
      case 'medium': return const Color(0xFFEAB308);
      case 'hard':   return const Color(0xFFE67E22);
      case 'epic':   return const Color(0xFFA855F7);
      default:       return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        difficulty.toUpperCase(),
        style: TextStyle(
          color: color, fontSize: 10,
          fontWeight: FontWeight.w700, letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class FrequencyChip extends StatelessWidget {
  final String frequency;

  const FrequencyChip({super.key, required this.frequency});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: cs.primary.withValues(alpha: 0.25)),
      ),
      child: Text(
        frequency.toUpperCase(),
        style: TextStyle(
          color: cs.primary, fontSize: 10,
          fontWeight: FontWeight.w700, letterSpacing: 0.6,
        ),
      ),
    );
  }
}
