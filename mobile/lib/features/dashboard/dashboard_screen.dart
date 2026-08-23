import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/models/character.dart';
import '../../core/models/goal.dart';
import '../../core/models/mission.dart';
import '../../shared/widgets/error_view.dart';
import '../character/character_provider.dart';
import '../goals/goal_provider.dart';
import '../missions/mission_provider.dart';

// ── Solo Leveling palette (mirrors character_screen) ─────────────────────────
const _kBg         = Color(0xFF070B14);
const _kSurface    = Color(0xFF0D1526);
const _kBorder     = Color(0xFF1A2744);
const _kManaBlue   = Color(0xFF3B82F6);
const _kManaLight  = Color(0xFF60A5FA);
const _kManaPurple = Color(0xFF7C3AED);
const _kGold       = Color(0xFFEAB308);
const _kRed        = Color(0xFFEF4444);
const _kOrange     = Color(0xFFE67E22);
const _kGreen      = Color(0xFF22C55E);
const _kText1      = Color(0xFFEEF2FF);
const _kText2      = Color(0xFF6B7FBF);
const _kText3      = Color(0xFF3A4A6B);

Color _rankColor(String rank) {
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

IconData _categoryIcon(String cat) {
  switch (cat.toLowerCase()) {
    case 'health':        return Icons.favorite_rounded;
    case 'fitness':       return Icons.fitness_center_rounded;
    case 'learning':      return Icons.auto_stories_rounded;
    case 'career':        return Icons.trending_up_rounded;
    case 'relationships': return Icons.people_rounded;
    case 'mindfulness':   return Icons.self_improvement_rounded;
    case 'finance':       return Icons.savings_rounded;
    default:              return Icons.flag_rounded;
  }
}

Color _difficultyColor(String diff) {
  switch (diff) {
    case 'easy':   return _kGreen;
    case 'medium': return _kGold;
    case 'hard':   return _kOrange;
    case 'epic':   return _kManaPurple;
    default:       return _kManaBlue;
  }
}

String _greeting() {
  final h = DateTime.now().hour;
  if (h >= 5  && h < 12) return 'RISE, HUNTER';
  if (h >= 12 && h < 17) return 'STAY FOCUSED';
  if (h >= 17 && h < 21) return 'PUSH THROUGH';
  return 'REST, HUNTER';
}

String _greetingSubtitle() {
  final h = DateTime.now().hour;
  if (h >= 5  && h < 12) return 'A new day to grow stronger';
  if (h >= 12 && h < 17) return 'Your quest awaits';
  if (h >= 17 && h < 21) return 'Finish what you started';
  return 'Tomorrow\'s battles need fresh strength';
}

// ── Main Screen ───────────────────────────────────────────────────────────────
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await Future.wait([
      ref.read(characterProvider.notifier).refresh(),
      ref.read(goalListProvider.notifier).refresh(),
      ref.read(missionListProvider.notifier).refresh(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final characterAsync = ref.watch(characterProvider);
    final goalsAsync     = ref.watch(goalListProvider);
    final missionsAsync  = ref.watch(missionListProvider);

    final dueMissions = missionsAsync.valueOrNull
            ?.where((m) => m.isActive && m.canCheckinNow)
            .toList() ??
        [];
    final activeGoals =
        goalsAsync.valueOrNull?.where((g) => g.isActive).toList() ?? [];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _kBg,
        body: RefreshIndicator(
          color: _kManaBlue,
          backgroundColor: _kSurface,
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Greeting header ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: _GreetingHeader(
                  onLogout: () => ref.read(authProvider.notifier).logout(),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([

                    // ── Hunter hero card ─────────────────────────────────
                    characterAsync.when(
                      loading: () => const _HeroCardSkeleton(),
                      error:   (e, _) => ErrorView(
                        message: e.toString(),
                        onRetry: () => ref.read(characterProvider.notifier).refresh(),
                      ),
                      data: (ch) => _HunterHeroCard(
                        character: ch,
                        shimmer: _shimmerCtrl,
                      ),
                    )
                    .animate().fadeIn(delay: 80.ms).slideY(begin: 0.12, end: 0, duration: 500.ms, curve: Curves.easeOutCubic),

                    const SizedBox(height: 16),

                    // ── Quick-stat row ───────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _StatChip(
                            icon: Icons.flag_rounded,
                            label: 'ACTIVE QUESTS',
                            value: activeGoals.length,
                            color: _kManaBlue,
                            onTap: () => context.go('/goals'),
                          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.12, end: 0),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatChip(
                            icon: Icons.task_alt_rounded,
                            label: 'DUE NOW',
                            value: dueMissions.length,
                            color: dueMissions.isNotEmpty ? _kOrange : _kText2,
                            highlight: dueMissions.isNotEmpty,
                            onTap: () => context.go('/missions'),
                          ).animate().fadeIn(delay: 260.ms).slideY(begin: 0.12, end: 0),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatChip(
                            icon: Icons.local_fire_department_rounded,
                            label: 'BEST STREAK',
                            value: missionsAsync.valueOrNull
                                    ?.map((m) => m.longestStreak)
                                    .fold<int>(0, max) ??
                                0,
                            color: _kRed,
                            onTap: () => context.go('/missions'),
                          ).animate().fadeIn(delay: 320.ms).slideY(begin: 0.12, end: 0),
                        ),
                      ],
                    ),

                    // ── System alerts (due missions) ─────────────────────
                    if (dueMissions.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _SectionHeader(
                        label: 'SYSTEM ALERTS',
                        sub: '${dueMissions.length} mission${dueMissions.length > 1 ? 's' : ''} require attention',
                        color: _kOrange,
                        onTap: () => context.go('/missions'),
                        urgent: true,
                      ).animate().fadeIn(delay: 380.ms),
                      const SizedBox(height: 10),
                      ...dueMissions.asMap().entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _MissionAlertTile(mission: entry.value)
                              .animate()
                              .fadeIn(delay: (400 + entry.key * 60).ms)
                              .slideX(begin: 0.08, end: 0, duration: 400.ms, curve: Curves.easeOutCubic),
                        );
                      }),
                    ],

                    // ── Active quests (goals) ────────────────────────────
                    if (activeGoals.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _SectionHeader(
                        label: 'ACTIVE QUESTS',
                        sub: '${activeGoals.length} quest${activeGoals.length > 1 ? 's' : ''} in progress',
                        color: _kManaBlue,
                        onTap: () => context.go('/goals'),
                      ).animate().fadeIn(delay: 440.ms),
                      const SizedBox(height: 10),
                      ...activeGoals.take(4).toList().asMap().entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _QuestTile(goal: entry.value)
                              .animate()
                              .fadeIn(delay: (460 + entry.key * 60).ms)
                              .slideX(begin: 0.08, end: 0, duration: 400.ms, curve: Curves.easeOutCubic),
                        );
                      }),
                      if (activeGoals.length > 4)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: _ViewAllButton(
                            label: '+${activeGoals.length - 4} more quests',
                            onTap: () => context.go('/goals'),
                          ).animate().fadeIn(delay: 700.ms),
                        ),
                    ],

                    // ── Empty state ──────────────────────────────────────
                    if (dueMissions.isEmpty && activeGoals.isEmpty &&
                        !characterAsync.isLoading) ...[
                      const SizedBox(height: 32),
                      _EmptyState(onTap: () => context.go('/goals')),
                    ],
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

// ── Greeting Header ───────────────────────────────────────────────────────────
class _GreetingHeader extends StatelessWidget {
  final VoidCallback onLogout;
  const _GreetingHeader({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr =
        '${_weekday(now.weekday)}, ${now.day} ${_month(now.month)} ${now.year}';

    return Container(
      color: _kBg,
      child: Stack(
        children: [
          // Grid background
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),

          // Subtle top glow
          Positioned(
            top: -40,
            left: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _kManaPurple.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // System logo
                        Row(
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
                            .fadeIn(begin: 0.3, duration: 900.ms),
                            const SizedBox(width: 7),
                            const Text(
                              'ARISE SYSTEM',
                              style: TextStyle(
                                color: _kManaBlue,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 3,
                              ),
                            ),
                          ],
                        )
                        .animate().fadeIn(duration: 500.ms),

                        const SizedBox(height: 10),

                        // Main greeting
                        Text(
                          _greeting(),
                          style: const TextStyle(
                            color: _kText1,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            height: 1.1,
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 100.ms, duration: 600.ms)
                        .slideX(begin: -0.05, end: 0, duration: 500.ms),

                        const SizedBox(height: 4),

                        Text(
                          _greetingSubtitle(),
                          style: const TextStyle(
                            color: _kText2,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        )
                        .animate().fadeIn(delay: 200.ms),

                        const SizedBox(height: 8),

                        // Date chip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _kManaBlue.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _kManaBlue.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            dateStr,
                            style: const TextStyle(
                              color: _kManaLight,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        )
                        .animate().fadeIn(delay: 300.ms),
                      ],
                    ),
                  ),

                  // Profile + Logout buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => context.push('/profile'),
                        child: Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                            color: _kManaBlue.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: _kManaBlue.withValues(alpha: 0.3)),
                          ),
                          child: const Icon(Icons.person_outline_rounded,
                              color: _kManaBlue, size: 20),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        onPressed: onLogout,
                        icon: const Icon(Icons.logout_rounded,
                            size: 20, color: _kText2),
                        tooltip: 'Sign out',
                      ),
                    ],
                  )
                  .animate().fadeIn(delay: 200.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _weekday(int d) => const ['', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'][d];
  String _month(int m) => const [
    '', 'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
  ][m];
}

// ── Hunter Hero Card ──────────────────────────────────────────────────────────
class _HunterHeroCard extends StatelessWidget {
  final CharacterResponse character;
  final AnimationController shimmer;
  const _HunterHeroCard({required this.character, required this.shimmer});

  @override
  Widget build(BuildContext context) {
    final rColor = _rankColor(character.rank);
    final progress = character.xpProgress.clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () => context.go('/character'),
      child: Container(
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: rColor.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(color: rColor.withValues(alpha: 0.12), blurRadius: 24, spreadRadius: 2),
          ],
        ),
        child: Stack(
          children: [
            // Gradient wash
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      rColor.withValues(alpha: 0.12),
                      Colors.transparent,
                      _kManaPurple.withValues(alpha: 0.05),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: badge + info + level
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Rank badge
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: rColor.withValues(alpha: 0.15),
                          border: Border.all(color: rColor, width: 1.5),
                          boxShadow: [
                            BoxShadow(color: rColor.withValues(alpha: 0.5), blurRadius: 12),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            character.rank,
                            style: TextStyle(
                              color: rColor,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Title + rank label
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              character.title,
                              style: const TextStyle(
                                color: _kText1,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: rColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: rColor.withValues(alpha: 0.35)),
                                  ),
                                  child: Text(
                                    'RANK ${character.rank}',
                                    style: TextStyle(
                                      color: rColor,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Hunter',
                                  style: TextStyle(color: _kText2, fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Level display
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'LEVEL',
                            style: TextStyle(
                              color: _kText2, fontSize: 8,
                              fontWeight: FontWeight.w700, letterSpacing: 2,
                            ),
                          ),
                          TweenAnimationBuilder<int>(
                            tween: IntTween(begin: 0, end: character.level),
                            duration: 1000.ms,
                            curve: Curves.easeOutCubic,
                            builder: (_, v, __) => Text(
                              '$v',
                              style: TextStyle(
                                color: rColor,
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // EXP bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'EXPERIENCE',
                            style: TextStyle(
                              color: _kText2, fontSize: 8,
                              fontWeight: FontWeight.w700, letterSpacing: 2,
                            ),
                          ),
                          Text(
                            '${character.currentLevelXp} / ${character.xpToNextLevel} XP',
                            style: const TextStyle(
                              color: _kManaLight, fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LayoutBuilder(
                        builder: (_, c) {
                          return Stack(
                            children: [
                              // Track
                              Container(
                                height: 7,
                                width: c.maxWidth,
                                decoration: BoxDecoration(
                                  color: _kManaBlue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: _kManaBlue.withValues(alpha: 0.15)),
                                ),
                              ),
                              // Fill
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: progress),
                                duration: 1200.ms,
                                curve: Curves.easeOutCubic,
                                builder: (_, v, __) => Container(
                                  height: 7,
                                  width: c.maxWidth * v,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        rColor.withValues(alpha: 0.7),
                                        _kManaLight,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _kManaBlue.withValues(alpha: 0.55),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Shimmer pass
                              AnimatedBuilder(
                                animation: shimmer,
                                builder: (_, __) {
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: SizedBox(
                                      width: c.maxWidth * progress,
                                      height: 7,
                                      child: Stack(
                                        children: [
                                          Positioned(
                                            left: (c.maxWidth * progress + 24) * shimmer.value - 24,
                                            top: -4,
                                            child: Transform.rotate(
                                              angle: pi / 6,
                                              child: Container(
                                                width: 14,
                                                height: 20,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Colors.white.withValues(alpha: 0),
                                                      Colors.white.withValues(alpha: 0.3),
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
                      const SizedBox(height: 5),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${(progress * 100).toStringAsFixed(1)}% to next level',
                          style: const TextStyle(
                            color: _kText2, fontSize: 9, fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Stat chips
                  if (character.stats != null) ...[
                    const SizedBox(height: 14),
                    const _Divider(),
                    const SizedBox(height: 12),
                    _StatChipsRow(stats: character.stats!),
                  ],

                  // Tap hint
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'VIEW FULL PROFILE',
                        style: TextStyle(
                          color: _kManaBlue.withValues(alpha: 0.7),
                          fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded,
                          size: 12, color: _kManaBlue.withValues(alpha: 0.7)),
                    ],
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

class _StatChipsRow extends StatelessWidget {
  final CharacterStats stats;
  const _StatChipsRow({required this.stats});

  static const _statColors = {
    'vitality':     Color(0xFFEF4444),
    'strength':     Color(0xFFE67E22),
    'intelligence': Color(0xFF3B82F6),
    'wisdom':       Color(0xFFA855F7),
    'charisma':     Color(0xFFEAB308),
    'discipline':   Color(0xFF22C55E),
  };

  static const _short = {
    'vitality': 'VIT', 'strength': 'STR', 'intelligence': 'INT',
    'wisdom': 'WIS', 'charisma': 'CHA', 'discipline': 'END',
  };

  @override
  Widget build(BuildContext context) {
    final ordered = stats.toOrderedList();
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: ordered.map((e) {
        final color = _statColors[e.key] ?? _kText2;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 3)],
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '${_short[e.key] ?? e.key.substring(0, 3).toUpperCase()} ${e.value}',
                style: TextStyle(
                  color: color.withValues(alpha: 0.9),
                  fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Stat Chip ─────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;
  final bool highlight;
  final VoidCallback? onTap;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.highlight = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: highlight ? color.withValues(alpha: 0.5) : _kBorder,
          ),
          boxShadow: highlight
              ? [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 12)]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                if (highlight) ...[
                  const SizedBox(width: 4),
                  _UrgentDot(color: color),
                ],
              ],
            ),
            const SizedBox(height: 8),
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: value),
              duration: 900.ms,
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => Text(
                '$v',
                style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                color: _kText2, fontSize: 8,
                fontWeight: FontWeight.w700, letterSpacing: 1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _UrgentDot extends StatelessWidget {
  final Color color;
  const _UrgentDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.8), blurRadius: 4)],
      ),
    )
    .animate(onPlay: (c) => c.repeat(reverse: true))
    .scaleXY(begin: 0.6, end: 1.4, duration: 700.ms, curve: Curves.easeInOut);
  }
}

// ── Section header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  final String sub;
  final Color color;
  final VoidCallback onTap;
  final bool urgent;

  const _SectionHeader({
    required this.label,
    required this.sub,
    required this.color,
    required this.onTap,
    this.urgent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.7), blurRadius: 6)],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: color, fontSize: 9,
                      fontWeight: FontWeight.w800, letterSpacing: 2,
                    ),
                  ),
                  if (urgent) ...[
                    const SizedBox(width: 6),
                    _UrgentDot(color: color),
                  ],
                ],
              ),
              Text(
                sub,
                style: const TextStyle(
                  color: _kText2, fontSize: 10, fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'VIEW ALL',
                style: TextStyle(
                  color: color.withValues(alpha: 0.7),
                  fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1,
                ),
              ),
              const SizedBox(width: 3),
              Icon(Icons.arrow_forward_rounded, size: 11, color: color.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Mission Alert Tile ────────────────────────────────────────────────────────
class _MissionAlertTile extends StatelessWidget {
  final MissionResponse mission;
  const _MissionAlertTile({required this.mission});

  @override
  Widget build(BuildContext context) {
    final accent = _difficultyColor(mission.difficulty);
    final hasStreak = mission.currentStreak > 0;

    return GestureDetector(
      onTap: () => context.go('/missions'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kOrange.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(color: _kOrange.withValues(alpha: 0.06), blurRadius: 12),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accent.withValues(alpha: 0.3)),
              ),
              child: Icon(_categoryIcon(mission.category), color: accent, size: 18),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mission.title,
                    style: const TextStyle(
                      color: _kText1, fontSize: 13, fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      _FreqTag(mission.frequency),
                      const SizedBox(width: 6),
                      _DiffTag(mission.difficulty),
                    ],
                  ),
                ],
              ),
            ),

            // Streak
            if (hasStreak) ...[
              const SizedBox(width: 8),
              Column(
                children: [
                  const Icon(Icons.local_fire_department_rounded,
                      color: _kOrange, size: 16),
                  Text(
                    '${mission.currentStreak}',
                    style: const TextStyle(
                      color: _kOrange, fontSize: 11, fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _kOrange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _kOrange.withValues(alpha: 0.35)),
              ),
              child: const Text(
                'DO IT',
                style: TextStyle(
                  color: _kOrange, fontSize: 9,
                  fontWeight: FontWeight.w800, letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quest Tile (goal) ─────────────────────────────────────────────────────────
class _QuestTile extends StatelessWidget {
  final GoalResponse goal;
  const _QuestTile({required this.goal});

  @override
  Widget build(BuildContext context) {
    final accent = _difficultyColor(goal.difficulty);
    final icon = _categoryIcon(goal.category);
    final hasDue = goal.targetDate != null;
    final daysLeft = hasDue
        ? goal.targetDate!.difference(DateTime.now()).inDays
        : null;

    return GestureDetector(
      onTap: () => context.go('/goals'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kBorder),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accent.withValues(alpha: 0.25)),
              ),
              child: Icon(icon, color: accent, size: 18),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.title,
                    style: const TextStyle(
                      color: _kText1, fontSize: 13, fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _DiffTag(goal.difficulty),
                      if (hasDue && daysLeft != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (daysLeft <= 3 ? _kRed : _kText3).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            daysLeft <= 0
                                ? 'OVERDUE'
                                : daysLeft == 1
                                    ? 'TOMORROW'
                                    : '$daysLeft DAYS',
                            style: TextStyle(
                              color: daysLeft <= 3 ? _kRed : _kText2,
                              fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const Icon(Icons.chevron_right_rounded, color: _kText3, size: 18),
          ],
        ),
      ),
    );
  }
}

// ── Tag widgets ───────────────────────────────────────────────────────────────
class _FreqTag extends StatelessWidget {
  final String frequency;
  const _FreqTag(this.frequency);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _kManaBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: _kManaBlue.withValues(alpha: 0.2)),
      ),
      child: Text(
        frequency.toUpperCase(),
        style: const TextStyle(
          color: _kManaLight, fontSize: 8,
          fontWeight: FontWeight.w700, letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _DiffTag extends StatelessWidget {
  final String difficulty;
  const _DiffTag(this.difficulty);

  @override
  Widget build(BuildContext context) {
    final color = _difficultyColor(difficulty);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        difficulty.toUpperCase(),
        style: TextStyle(
          color: color, fontSize: 8,
          fontWeight: FontWeight.w700, letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── View-all button ───────────────────────────────────────────────────────────
class _ViewAllButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ViewAllButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: _kManaBlue.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kManaBlue.withValues(alpha: 0.2)),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: _kManaLight, fontSize: 11,
              fontWeight: FontWeight.w700, letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyState({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: _kManaBlue.withValues(alpha: 0.08),
            shape: BoxShape.circle,
            border: Border.all(color: _kManaBlue.withValues(alpha: 0.2)),
          ),
          child: const Icon(Icons.explore_outlined, color: _kManaLight, size: 28),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(begin: 0.95, end: 1.05, duration: 1800.ms, curve: Curves.easeInOut),
        const SizedBox(height: 16),
        const Text(
          'NO ACTIVE QUESTS',
          style: TextStyle(
            color: _kText2, fontSize: 11,
            fontWeight: FontWeight.w700, letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Begin your journey and set your first goal',
          style: TextStyle(color: _kText3, fontSize: 12),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: _kManaBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kManaBlue.withValues(alpha: 0.4)),
            ),
            child: const Text(
              'CREATE YOUR FIRST QUEST',
              style: TextStyle(
                color: _kManaLight, fontSize: 11,
                fontWeight: FontWeight.w800, letterSpacing: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Hero card skeleton ────────────────────────────────────────────────────────
class _HeroCardSkeleton extends StatelessWidget {
  const _HeroCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBorder),
      ),
      child: const Padding(
        padding: EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Shimmer(width: 54, height: 54, radius: 27),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Shimmer(width: 140, height: 16, radius: 4),
                      SizedBox(height: 8),
                      _Shimmer(width: 80, height: 10, radius: 4),
                    ],
                  ),
                ),
                _Shimmer(width: 40, height: 44, radius: 4),
              ],
            ),
            Spacer(),
            _Shimmer(width: double.infinity, height: 7, radius: 4),
          ],
        ),
      ),
    )
    .animate(onPlay: (c) => c.repeat(reverse: true))
    .fadeIn(begin: 0.5, duration: 800.ms);
  }
}

class _Shimmer extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  const _Shimmer({required this.width, required this.height, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width == double.infinity ? null : width,
      height: height,
      decoration: BoxDecoration(
        color: _kText3.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ── Shared utilities ──────────────────────────────────────────────────────────
class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: _kBorder);
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _kManaBlue.withValues(alpha: 0.035)
      ..strokeWidth = 0.5;
    const sp = 36.0;
    for (double x = 0; x < size.width; x += sp) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += sp) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter _) => false;
}
