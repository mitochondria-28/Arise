import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class XpBar extends StatelessWidget {
  final double progress; // 0.0 – 1.0
  final int currentXp;
  final int xpToNextLevel;
  final Color? color;

  const XpBar({
    super.key,
    required this.progress,
    required this.currentXp,
    required this.xpToNextLevel,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final barColor = color ?? const Color(0xFF34D399);
    final pct = (progress * 100).toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$currentXp XP',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: barColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Text(
              '$pct% to next level',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: cs.onSurface.withValues(alpha: 0.45)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Container(
                  height: 6,
                  width: constraints.maxWidth,
                  decoration: BoxDecoration(
                    color: barColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Container(
                  height: 6,
                  width: constraints.maxWidth * progress.clamp(0.0, 1.0),
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: barColor.withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .custom(
                      duration: 900.ms,
                      curve: Curves.easeOutCubic,
                      builder: (_, value, child) => SizedBox(
                        width: constraints.maxWidth * progress.clamp(0.0, 1.0) * value,
                        child: child,
                      ),
                    ),
              ],
            );
          },
        ),
      ],
    );
  }
}
