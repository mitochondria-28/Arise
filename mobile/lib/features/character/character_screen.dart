import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/character.dart';
import '../../shared/widgets/error_view.dart';
import 'character_provider.dart';

// ── Solo Leveling "System" palette ───────────────────────────────────────────
const _kManaBlue   = Color(0xFF3B82F6);
const _kManaLight  = Color(0xFF60A5FA);
const _kManaPurple = Color(0xFF7C3AED);
const _kGold       = Color(0xFFEAB308);
const _kBg         = Color(0xFF070B14);
const _kSurface    = Color(0xFF0D1526);
const _kBorder     = Color(0xFF1A2744);
const _kText1      = Color(0xFFEEF2FF);
const _kText2      = Color(0xFF6B7FBF);

const _kRanks = ['E', 'D', 'C', 'B', 'A', 'S'];

Color _rankColor(String rank) {
  switch (rank) {
    case 'E': return const Color(0xFF6B7280);
    case 'D': return const Color(0xFF22C55E);
    case 'C': return const Color(0xFF3B82F6);
    case 'B': return const Color(0xFFA855F7);
    case 'A': return const Color(0xFFF97316);
    case 'S': return const Color(0xFFEF4444);
    default:  return const Color(0xFF6B7280);
  }
}

String _rankTitle(String rank) {
  switch (rank) {
    case 'E': return 'Novice Hunter';
    case 'D': return 'Apprentice Hunter';
    case 'C': return 'Adept Hunter';
    case 'B': return 'Expert Hunter';
    case 'A': return 'Master Hunter';
    case 'S': return 'Shadow Monarch';
    default:  return 'Hunter';
  }
}

IconData _statIcon(String stat) {
  switch (stat) {
    case 'vitality':     return Icons.favorite_rounded;
    case 'strength':     return Icons.fitness_center_rounded;
    case 'intelligence': return Icons.psychology_rounded;
    case 'wisdom':       return Icons.auto_awesome_rounded;
    case 'charisma':     return Icons.star_rounded;
    case 'discipline':   return Icons.shield_rounded;
    default:             return Icons.circle;
  }
}

Color _statColor(String stat) {
  switch (stat) {
    case 'vitality':     return const Color(0xFFEF4444);
    case 'strength':     return const Color(0xFFF97316);
    case 'intelligence': return const Color(0xFF3B82F6);
    case 'wisdom':       return const Color(0xFFA855F7);
    case 'charisma':     return const Color(0xFFEAB308);
    case 'discipline':   return const Color(0xFF22C55E);
    default:             return const Color(0xFF6B7280);
  }
}

String _statShort(String stat) {
  switch (stat) {
    case 'vitality':     return 'VIT';
    case 'strength':     return 'STR';
    case 'intelligence': return 'INT';
    case 'wisdom':       return 'WIS';
    case 'charisma':     return 'CHA';
    case 'discipline':   return 'END';
    default:             return stat.substring(0, 3).toUpperCase();
  }
}

// ── Main Screen ───────────────────────────────────────────────────────────────
class CharacterScreen extends ConsumerWidget {
  const CharacterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(characterProvider);

    return Scaffold(
      backgroundColor: _kBg,
      body: async.when(
        loading: () => const _LoadingView(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.read(characterProvider.notifier).refresh(),
        ),
        data: (character) => RefreshIndicator(
          color: _kManaBlue,
          backgroundColor: _kSurface,
          onRefresh: () => ref.read(characterProvider.notifier).refresh(),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _HunterHeader(character: character)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 20),
                    if (character.stats != null) ...[
                      _RadarCard(stats: character.stats!)
                          .animate().fadeIn(delay: 200.ms).slideY(begin: 0.15, end: 0),
                      const SizedBox(height: 14),
                      _AttributesCard(stats: character.stats!)
                          .animate().fadeIn(delay: 350.ms).slideY(begin: 0.15, end: 0),
                      const SizedBox(height: 14),
                      _PowerCard(stats: character.stats!)
                          .animate().fadeIn(delay: 500.ms).slideY(begin: 0.15, end: 0),
                      const SizedBox(height: 14),
                    ],
                    _RankCard(currentRank: character.rank)
                        .animate().fadeIn(delay: 650.ms).slideY(begin: 0.15, end: 0),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Loading ───────────────────────────────────────────────────────────────────
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: _kManaBlue, strokeWidth: 1.5),
          SizedBox(height: 16),
          Text(
            'LOADING SYSTEM...',
            style: TextStyle(
              color: _kText2, fontSize: 11,
              letterSpacing: 2, fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hunter Header (Hero Section) ──────────────────────────────────────────────
class _HunterHeader extends StatefulWidget {
  final CharacterResponse character;
  const _HunterHeader({required this.character});

  @override
  State<_HunterHeader> createState() => _HunterHeaderState();
}

class _HunterHeaderState extends State<_HunterHeader>
    with TickerProviderStateMixin {
  late final AnimationController _auraCtrl;
  late final AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _auraCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat();
  }

  @override
  void dispose() {
    _auraCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ch = widget.character;
    final rColor = _rankColor(ch.rank);
    final isElite = ch.rank == 'S' || ch.rank == 'A';
    final screenH = MediaQuery.of(context).size.height;

    return SizedBox(
      height: screenH * 0.52,
      child: Stack(
        children: [
          // ── Background gradient ──────────────────────────────────────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    rColor.withValues(alpha: 0.22),
                    _kBg.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),

          // ── Grid lines (system UI) ───────────────────────────────────────
          Positioned.fill(
            child: CustomPaint(painter: _GridPainter()),
          ),

          // ── Floating particles ───────────────────────────────────────────
          _FloatingParticles(color: rColor),

          // ── Content ─────────────────────────────────────────────────────
          Positioned.fill(
            child: Column(
              children: [
                // Safe area + small system alert tag
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: const _SystemTag('HUNTER PROFILE')
                        .animate().fadeIn(duration: 600.ms),
                  ),
                ),

                const Spacer(),

                // ── Rank Badge with aura ─────────────────────────────────
                AnimatedBuilder(
                  animation: _auraCtrl,
                  builder: (_, __) => CustomPaint(
                    painter: _AuraPainter(pulse: _auraCtrl.value, color: rColor),
                    child: SizedBox(
                      width: 140,
                      height: 140,
                      child: Center(
                        child: _BigRankBadge(rank: ch.rank, rColor: rColor),
                      ),
                    ),
                  ),
                ).animate().scale(begin: const Offset(0.7, 0.7), duration: 700.ms, curve: Curves.easeOutBack),

                const SizedBox(height: 16),

                // ── Rank class label ─────────────────────────────────────
                Text(
                  _rankTitle(ch.rank),
                  style: const TextStyle(
                    color: _kText2, fontSize: 11,
                    fontWeight: FontWeight.w600, letterSpacing: 3,
                  ),
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 6),

                // ── Character title ──────────────────────────────────────
                Text(
                  ch.title,
                  style: const TextStyle(
                    color: _kText1, fontSize: 22,
                    fontWeight: FontWeight.w800, letterSpacing: 0.5,
                  ),
                ).animate().fadeIn(delay: 400.ms),

                const SizedBox(height: 4),

                // ── Level ────────────────────────────────────────────────
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: rColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: rColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        'LV. ${ch.level}',
                        style: TextStyle(
                          color: rColor, fontSize: 12,
                          fontWeight: FontWeight.w800, letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    if (isElite) ...[
                      const SizedBox(width: 8),
                      _PulsingDot(color: rColor),
                    ],
                  ],
                ).animate().fadeIn(delay: 450.ms),

                const SizedBox(height: 20),

                // ── EXP Bar ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: _ManaBar(
                    progress: ch.xpProgress,
                    current: ch.currentLevelXp,
                    total: ch.xpToNextLevel,
                    shimmer: _shimmerCtrl,
                  ),
                ).animate().fadeIn(delay: 550.ms),

                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Big rank badge (hero size) ────────────────────────────────────────────────
class _BigRankBadge extends StatelessWidget {
  final String rank;
  final Color rColor;
  const _BigRankBadge({required this.rank, required this.rColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: rColor.withValues(alpha: 0.18),
        border: Border.all(color: rColor, width: 2),
        boxShadow: [
          BoxShadow(color: rColor.withValues(alpha: 0.6), blurRadius: 20, spreadRadius: 2),
          BoxShadow(color: rColor.withValues(alpha: 0.25), blurRadius: 40, spreadRadius: 8),
        ],
      ),
      child: Center(
        child: Text(
          rank,
          style: TextStyle(
            color: rColor, fontSize: 38,
            fontWeight: FontWeight.w900, letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}

// ── Aura rings painter ────────────────────────────────────────────────────────
class _AuraPainter extends CustomPainter {
  final double pulse;
  final Color color;
  const _AuraPainter({required this.pulse, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (int i = 0; i < 3; i++) {
      final t = (pulse + i / 3.0) % 1.0;
      final radius = size.width * 0.42 * (0.6 + t * 0.4);
      final alpha = (1.0 - t) * 0.45;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = color.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5 - t * 1.2,
      );
    }
  }

  @override
  bool shouldRepaint(_AuraPainter old) => old.pulse != pulse;
}

// ── Background grid painter ───────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _kManaBlue.withValues(alpha: 0.04)
      ..strokeWidth = 0.5;
    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter _) => false;
}

// ── Floating mana particles ───────────────────────────────────────────────────
class _FloatingParticles extends StatelessWidget {
  final Color color;
  const _FloatingParticles({required this.color});

  @override
  Widget build(BuildContext context) {
    final rng = Random(7);
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: List.generate(14, (i) {
            final x = rng.nextDouble() * constraints.maxWidth;
            final y = rng.nextDouble() * constraints.maxHeight;
            final sz = 1.0 + rng.nextDouble() * 2.5;
            final delay = (rng.nextInt(3000)).ms;
            final dur = (2000 + rng.nextInt(2000)).ms;
            return Positioned(
              left: x,
              top: y,
              child: Container(
                width: sz,
                height: sz,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.55 + rng.nextDouble() * 0.4),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 3),
                  ],
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true), delay: delay)
              .moveY(begin: 0, end: -(10 + rng.nextDouble() * 15), duration: dur)
              .fadeIn(duration: 400.ms)
              .then(delay: dur ~/ 2)
              .fadeOut(duration: 600.ms),
            );
          }),
        );
      },
    );
  }
}

// ── Pulsing status dot ────────────────────────────────────────────────────────
class _PulsingDot extends StatelessWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.7), blurRadius: 6)],
      ),
    )
    .animate(onPlay: (c) => c.repeat(reverse: true))
    .scaleXY(begin: 0.7, end: 1.3, duration: 900.ms, curve: Curves.easeInOut)
    .fadeIn(begin: 0.4);
  }
}

// ── System tag widget ─────────────────────────────────────────────────────────
class _SystemTag extends StatelessWidget {
  final String label;
  const _SystemTag(this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            color: _kManaBlue,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: _kManaBlue, blurRadius: 6)],
          ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fadeIn(begin: 0.3, duration: 800.ms),
        const SizedBox(width: 8),
        Text(
          '[ $label ]',
          style: const TextStyle(
            color: _kManaBlue, fontSize: 9,
            fontWeight: FontWeight.w700, letterSpacing: 3,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            color: _kManaBlue,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: _kManaBlue, blurRadius: 6)],
          ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fadeIn(begin: 0.3, duration: 800.ms),
      ],
    );
  }
}

// ── Mana (EXP) Bar ────────────────────────────────────────────────────────────
class _ManaBar extends StatelessWidget {
  final double progress;
  final int current;
  final int total;
  final AnimationController shimmer;

  const _ManaBar({
    required this.progress,
    required this.current,
    required this.total,
    required this.shimmer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'EXP',
              style: TextStyle(
                color: _kManaLight, fontSize: 9,
                fontWeight: FontWeight.w700, letterSpacing: 2,
              ),
            ),
            Text(
              '$current / $total',
              style: const TextStyle(
                color: _kText2, fontSize: 9,
                fontWeight: FontWeight.w500, letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (ctx, c) {
            final barW = c.maxWidth;
            return Stack(
              children: [
                // Track
                Container(
                  height: 8,
                  width: barW,
                  decoration: BoxDecoration(
                    color: _kManaBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _kManaBlue.withValues(alpha: 0.2)),
                  ),
                ),
                // Filled
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
                  duration: 1200.ms,
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => Container(
                    height: 8,
                    width: barW * v,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1D4ED8), Color(0xFF60A5FA)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _kManaBlue.withValues(alpha: 0.6),
                          blurRadius: 8, spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
                // Shimmer
                AnimatedBuilder(
                  animation: shimmer,
                  builder: (_, __) {
                    final p = progress.clamp(0.0, 1.0);
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SizedBox(
                        width: barW * p,
                        height: 8,
                        child: Stack(
                          children: [
                            Positioned(
                              left: (barW * p + 30) * shimmer.value - 30,
                              top: -4,
                              child: Transform.rotate(
                                angle: pi / 6,
                                child: Container(
                                  width: 16,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withValues(alpha: 0),
                                        Colors.white.withValues(alpha: 0.35),
                                        Colors.white.withValues(alpha: 0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${(progress * 100).toStringAsFixed(1)}% to next level',
            style: const TextStyle(
              color: _kText2, fontSize: 9,
              fontWeight: FontWeight.w500, letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Section card wrapper ───────────────────────────────────────────────────────
class _SystemCard extends StatelessWidget {
  final String label;
  final Widget child;
  final Color? accentColor;

  const _SystemCard({
    required this.label,
    required this.child,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? _kManaBlue;
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.06),
            blurRadius: 20, spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: _kBorder.withValues(alpha: 0.8)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 14,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.7), blurRadius: 6)],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: accent, fontSize: 9,
                    fontWeight: FontWeight.w700, letterSpacing: 2,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 16,
                  height: 1,
                  color: accent.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ── Hex Radar Chart Card ──────────────────────────────────────────────────────
class _RadarCard extends StatelessWidget {
  final CharacterStats stats;
  const _RadarCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final ordered = stats.toOrderedList();
    final values = ordered.map((e) => e.value / 100.0).toList();

    return _SystemCard(
      label: 'HUNTER STATUS',
      accentColor: _kManaPurple,
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: 1400.ms,
            curve: Curves.easeOutCubic,
            builder: (_, anim, __) => CustomPaint(
              size: const Size(double.infinity, 220),
              painter: _HexRadarPainter(
                values: values,
                labels: ordered.map((e) => _statShort(e.key)).toList(),
                colors: ordered.map((e) => _statColor(e.key)).toList(),
                animValue: anim,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Legend row
          Wrap(
            spacing: 12,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: ordered.map((e) {
              final color = _statColor(e.key);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: color.withValues(alpha: 0.8), blurRadius: 4)],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_statShort(e.key)} ${e.value}',
                    style: const TextStyle(
                      color: _kText2, fontSize: 10,
                      fontWeight: FontWeight.w600, letterSpacing: 0.5,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _HexRadarPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final List<Color> colors;
  final double animValue;

  const _HexRadarPainter({
    required this.values,
    required this.labels,
    required this.colors,
    required this.animValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = min(size.width, size.height) / 2 - 30;
    const n = 6;
    const startAngle = -pi / 2;

    Offset pt(int i, double r) {
      final a = startAngle + i * 2 * pi / n;
      return Offset(center.dx + r * cos(a), center.dy + r * sin(a));
    }

    // ── Grid hexagons ──────────────────────────────────────────────────────
    final gridPaint = Paint()
      ..color = _kManaBlue.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (final frac in [0.25, 0.5, 0.75, 1.0]) {
      final path = Path();
      for (int i = 0; i < n; i++) {
        final p = pt(i, maxR * frac);
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // ── Axis lines ─────────────────────────────────────────────────────────
    final axisPaint = Paint()
      ..color = _kManaBlue.withValues(alpha: 0.1)
      ..strokeWidth = 0.6;
    for (int i = 0; i < n; i++) {
      canvas.drawLine(center, pt(i, maxR), axisPaint);
    }

    // ── Filled stat polygon ────────────────────────────────────────────────
    final statPath = Path();
    for (int i = 0; i < n; i++) {
      final p = pt(i, maxR * values[i] * animValue);
      i == 0 ? statPath.moveTo(p.dx, p.dy) : statPath.lineTo(p.dx, p.dy);
    }
    statPath.close();

    // Gradient fill
    final fillPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          _kManaPurple.withValues(alpha: 0.45),
          _kManaBlue.withValues(alpha: 0.2),
          _kManaBlue.withValues(alpha: 0.05),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: maxR))
      ..style = PaintingStyle.fill;
    canvas.drawPath(statPath, fillPaint);

    // Stroke
    final strokePaint = Paint()
      ..color = _kManaPurple.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(statPath, strokePaint);

    // ── Stat dots ──────────────────────────────────────────────────────────
    for (int i = 0; i < n; i++) {
      final p = pt(i, maxR * values[i] * animValue);
      canvas.drawCircle(
        p,
        3.5,
        Paint()..color = colors[i]
               ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        p,
        5,
        Paint()
          ..color = colors[i].withValues(alpha: 0.3)
          ..style = PaintingStyle.fill,
      );
    }

    // ── Labels ─────────────────────────────────────────────────────────────
    for (int i = 0; i < n; i++) {
      final p = pt(i, maxR + 20);
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: colors[i],
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_HexRadarPainter old) =>
      old.animValue != animValue || old.values != values;
}

// ── Attributes Card ───────────────────────────────────────────────────────────
class _AttributesCard extends StatelessWidget {
  final CharacterStats stats;
  const _AttributesCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final ordered = stats.toOrderedList();

    return _SystemCard(
      label: 'ATTRIBUTES',
      child: Column(
        children: ordered.asMap().entries.map((entry) {
          final i = entry.key;
          final e = entry.value;
          return Padding(
            padding: EdgeInsets.only(bottom: i < ordered.length - 1 ? 14 : 0),
            child: _AnimatedStatBar(
              category: e.key,
              value: e.value,
              delay: (i * 80).ms,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _AnimatedStatBar extends StatelessWidget {
  final String category;
  final int value;
  final Duration delay;

  const _AnimatedStatBar({
    required this.category,
    required this.value,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final color = _statColor(category);
    final icon = _statIcon(category);
    final progress = (value / 100.0).clamp(0.0, 1.0);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: (900 + delay.inMilliseconds).ms,
      curve: Curves.easeOutCubic,
      builder: (_, anim, __) {
        return Row(
          children: [
            // Icon
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _statShort(category),
                        style: TextStyle(
                          color: color, fontSize: 10,
                          fontWeight: FontWeight.w700, letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        '$value',
                        style: const TextStyle(
                          color: _kText1, fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LayoutBuilder(
                    builder: (_, c) => Stack(
                      children: [
                        Container(
                          height: 4,
                          width: c.maxWidth,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Container(
                          height: 4,
                          width: c.maxWidth * progress * anim,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [color.withValues(alpha: 0.6), color],
                            ),
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.5),
                                blurRadius: 6, spreadRadius: 0,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Power Rating Card ─────────────────────────────────────────────────────────
class _PowerCard extends StatelessWidget {
  final CharacterStats stats;
  const _PowerCard({required this.stats});

  int get _power {
    final s = stats;
    return s.vitality + s.strength + s.intelligence + s.wisdom + s.charisma + s.discipline;
  }

  String _tier() {
    final p = _power;
    if (p >= 480) return 'MONARCH';
    if (p >= 380) return 'NATIONAL';
    if (p >= 280) return 'HIGH-RANK';
    if (p >= 180) return 'MID-RANK';
    if (p >= 80)  return 'LOW-RANK';
    return 'UNRANKED';
  }

  @override
  Widget build(BuildContext context) {
    final power = _power;
    final tier = _tier();
    const max = 600;
    final pct = (power / max).clamp(0.0, 1.0);
    const accentColor = _kGold;

    return _SystemCard(
      label: 'COMBAT POWER',
      accentColor: accentColor,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: power),
                duration: 1500.ms,
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => Text(
                  '$v',
                  style: const TextStyle(
                    color: _kGold, fontSize: 52,
                    fontWeight: FontWeight.w900, letterSpacing: -2,
                    height: 1,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 8, left: 6),
                child: Text(
                  '/ 600',
                  style: TextStyle(color: _kText2, fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accentColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  tier,
                  style: const TextStyle(
                    color: _kGold, fontSize: 10,
                    fontWeight: FontWeight.w800, letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: pct),
            duration: 1400.ms,
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => LayoutBuilder(
              builder: (_, c) => Stack(
                children: [
                  Container(
                    height: 10,
                    width: c.maxWidth,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: accentColor.withValues(alpha: 0.15)),
                    ),
                  ),
                  Container(
                    height: 10,
                    width: c.maxWidth * v,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFB45309), Color(0xFFEAB308), Color(0xFFFDE68A)],
                      ),
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: [
                        BoxShadow(color: _kGold.withValues(alpha: 0.5), blurRadius: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Rank Ladder Card ──────────────────────────────────────────────────────────
class _RankCard extends StatelessWidget {
  final String currentRank;
  const _RankCard({required this.currentRank});

  @override
  Widget build(BuildContext context) {
    final currentIdx = _kRanks.indexOf(currentRank);

    return _SystemCard(
      label: 'RANK CLASSIFICATION',
      child: Column(
        children: _kRanks.reversed.toList().asMap().entries.map((entry) {
          final rank = entry.value;
          final rankIdx = _kRanks.indexOf(rank);
          final unlocked = rankIdx <= currentIdx;
          final isCurrent = rank == currentRank;
          final color = _rankColor(rank);

          return Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: _RankRow(
              rank: rank,
              unlocked: unlocked,
              isCurrent: isCurrent,
              color: color,
              delay: ((5 - _kRanks.reversed.toList().indexOf(rank)) * 60).ms,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  final String rank;
  final bool unlocked;
  final bool isCurrent;
  final Color color;
  final Duration delay;

  const _RankRow({
    required this.rank,
    required this.unlocked,
    required this.isCurrent,
    required this.color,
    required this.delay,
  });

  String get _fullTitle {
    switch (rank) {
      case 'E': return 'E — Novice';
      case 'D': return 'D — Apprentice';
      case 'C': return 'C — Adept';
      case 'B': return 'B — Expert';
      case 'A': return 'A — Master';
      case 'S': return 'S — Shadow Monarch';
      default:  return rank;
    }
  }

  String get _description {
    switch (rank) {
      case 'E': return 'Just beginning the journey';
      case 'D': return 'Basic hunter abilities unlocked';
      case 'C': return 'Mid-tier dungeon capable';
      case 'B': return 'High-level threat neutralized';
      case 'A': return 'Elite hunter — national level';
      case 'S': return 'Peak — ruler of shadows';
      default:  return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: 300.ms,
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isCurrent
            ? color.withValues(alpha: 0.1)
            : unlocked
                ? _kSurface.withValues(alpha: 0.5)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCurrent
              ? color.withValues(alpha: 0.5)
              : unlocked
                  ? _kBorder.withValues(alpha: 0.5)
                  : _kBorder.withValues(alpha: 0.2),
        ),
        boxShadow: isCurrent
            ? [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 12)]
            : null,
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: unlocked ? color.withValues(alpha: 0.15) : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: unlocked ? color : _kBorder.withValues(alpha: 0.3),
                width: isCurrent ? 1.5 : 1,
              ),
              boxShadow: isCurrent
                  ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 10)]
                  : null,
            ),
            child: Center(
              child: Text(
                rank,
                style: TextStyle(
                  color: unlocked ? color : _kText2.withValues(alpha: 0.3),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fullTitle,
                  style: TextStyle(
                    color: unlocked ? _kText1 : _kText2.withValues(alpha: 0.35),
                    fontSize: 13,
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                Text(
                  _description,
                  style: TextStyle(
                    color: _kText2.withValues(alpha: unlocked ? 0.65 : 0.25),
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          // Status icon
          if (isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Text(
                'CURRENT',
                style: TextStyle(
                  color: color, fontSize: 8,
                  fontWeight: FontWeight.w800, letterSpacing: 1,
                ),
              ),
            )
          else if (unlocked)
            Icon(Icons.check_circle_rounded, color: color.withValues(alpha: 0.7), size: 18)
          else
            Icon(Icons.lock_rounded, color: _kText2.withValues(alpha: 0.25), size: 16),
        ],
      ),
    )
    .animate(delay: delay)
    .fadeIn(duration: 400.ms)
    .slideX(begin: 0.08, end: 0, duration: 400.ms, curve: Curves.easeOutCubic);
  }
}
