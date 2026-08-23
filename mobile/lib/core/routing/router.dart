import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_provider.dart';
import '../auth/auth_state.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/goals/goals_screen.dart';
import '../../features/missions/missions_screen.dart';
import '../../features/character/character_screen.dart';
import '../../features/ai/ai_coach_screen.dart';
import '../../features/stats/stats_screen.dart';
import '../../features/achievements/achievements_screen.dart';
import '../../features/journal/journal_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/skills/skills_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthChangeNotifier(ref);

  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authInitState = ref.read(authInitProvider);
      final authState = ref.read(authProvider);

      final isInitializing =
          authInitState.isLoading || authState.status == AuthStatus.initial;
      if (isInitializing) {
        return state.uri.path == '/splash' ? null : '/splash';
      } 

      final loc = state.uri.path;
      final isAuthenticated = authState.isAuthenticated;
      final isAuthRoute = loc == '/login' || loc == '/register';

      if (!isAuthenticated && !isAuthRoute) return '/login';
      if (isAuthenticated && (isAuthRoute || loc == '/splash')) {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const _SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      ShellRoute(
        builder: (context, state, child) => _AppShell(child: child),
        routes: [
          GoRoute(
              path: '/dashboard', builder: (_, __) => const DashboardScreen()),
          GoRoute(path: '/goals', builder: (_, __) => const GoalsScreen()),
          GoRoute(
              path: '/missions', builder: (_, __) => const MissionsScreen()),
          GoRoute(
              path: '/character', builder: (_, __) => const CharacterScreen()),
          GoRoute(path: '/coach', builder: (_, __) => const AICoachScreen()),
          GoRoute(path: '/stats', builder: (_, __) => const StatsScreen()),
          GoRoute(
              path: '/achievements',
              builder: (_, __) => const AchievementsScreen()),
          GoRoute(path: '/journal', builder: (_, __) => const JournalScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          GoRoute(path: '/skills', builder: (_, __) => const SkillsScreen()),
        ],
      ),
    ],
  );
});

class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Ref ref) {
    ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
    ref.listen<AsyncValue<void>>(
        authInitProvider, (_, __) => notifyListeners());
  }
}

// ── Solo Leveling palette (splash) ────────────────────────────────────────────
const _kSplashBg   = Color(0xFF0A0A0F);
const _kSplashBlue = Color(0xFF4FC3F7);
const _kSplashText = Color(0xFFE2E8F0);

class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _glow = CurvedAnimation(parent: _pulse, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _kSplashBg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pulsing shield icon
              AnimatedBuilder(
                animation: _glow,
                builder: (_, child) => Container(
                  width: 88, height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kSplashBlue.withValues(
                        alpha: 0.06 + 0.06 * _glow.value),
                    border: Border.all(
                      color: _kSplashBlue.withValues(
                          alpha: 0.2 + 0.2 * _glow.value),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _kSplashBlue.withValues(
                            alpha: 0.10 + 0.18 * _glow.value),
                        blurRadius: 24 + 20 * _glow.value,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: child,
                ),
                child: const Icon(Icons.shield_outlined,
                    color: _kSplashBlue, size: 36),
              ),
              const SizedBox(height: 30),

              // ARISE wordmark with pulsing flanking lines
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _glow,
                    builder: (_, __) => Container(
                      width: 32, height: 1,
                      color: _kSplashBlue.withValues(
                          alpha: 0.25 + 0.3 * _glow.value),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'ARISE',
                    style: TextStyle(
                      color: _kSplashText, fontSize: 30,
                      fontWeight: FontWeight.w800, letterSpacing: 8,
                    ),
                  ),
                  const SizedBox(width: 14),
                  AnimatedBuilder(
                    animation: _glow,
                    builder: (_, __) => Container(
                      width: 32, height: 1,
                      color: _kSplashBlue.withValues(
                          alpha: 0.25 + 0.3 * _glow.value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              const Text(
                'SYSTEM INITIALIZING',
                style: TextStyle(
                  color: _kSplashBlue, fontSize: 9,
                  fontWeight: FontWeight.w600, letterSpacing: 3.5,
                ),
              ),
              const SizedBox(height: 60),

              // Staggered loading dots
              AnimatedBuilder(
                animation: _pulse,
                builder: (_, __) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (i) {
                      final v = ((_pulse.value - i / 3) % 1.0)
                          .clamp(0.0, 1.0);
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Container(
                          width: 5, height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _kSplashBlue.withValues(
                                alpha: 0.15 + 0.85 * v),
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
            ],
          ).animate().fadeIn(duration: 600.ms),
        ),
      ),
    );
  }
}

// ── Tab descriptor ─────────────────────────────────────────────────────────────
class _Tab {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;
  final Color color;
  const _Tab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.path,
    required this.color,
  });
}

// ── App shell with custom dark nav bar ─────────────────────────────────────────
class _AppShell extends StatelessWidget {
  final Widget child;

  const _AppShell({required this.child});

  static const _kNavBg     = Color(0xFF0D0D1A);
  static const _kNavBorder = Color(0xFF2A2A3E);
  static const _kNavDim    = Color(0xFF4A5568);

  static const _tabs = [
    _Tab(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'HOME',
      path: '/dashboard',
      color: Color(0xFF4FC3F7),
    ),
    _Tab(
      icon: Icons.task_alt_outlined,
      activeIcon: Icons.task_alt_rounded,
      label: 'MISSIONS',
      path: '/missions',
      color: Color(0xFF14B8A6),
    ),
    _Tab(
      icon: Icons.book_outlined,
      activeIcon: Icons.book_rounded,
      label: 'JOURNAL',
      path: '/journal',
      color: Color(0xFF9B59B6),
    ),
    _Tab(
      icon: Icons.emoji_events_outlined,
      activeIcon: Icons.emoji_events_rounded,
      label: 'AWARDS',
      path: '/achievements',
      color: Color(0xFFFFD700),
    ),
    _Tab(
      icon: Icons.person_outline,
      activeIcon: Icons.person_rounded,
      label: 'HUNTER',
      path: '/character',
      color: Color(0xFF34D399),
    ),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final idx = _tabs.indexWhere((t) => location.startsWith(t.path));
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final current = _currentIndex(context);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: _kNavBg,
          border: Border(top: BorderSide(color: _kNavBorder)),
        ),
        padding: EdgeInsets.only(bottom: bottomPad),
        child: SizedBox(
          height: 58,
          child: Row(
            children: List.generate(_tabs.length, (i) {
              final tab = _tabs[i];
              final isActive = i == current;

              return Expanded(
                child: GestureDetector(
                  onTap: () => context.go(tab.path),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      // Glowing top-indicator line
                      Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          height: 2,
                          width: isActive ? 22.0 : 0.0,
                          decoration: BoxDecoration(
                            color: tab.color,
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(2),
                            ),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: tab.color.withValues(alpha: 0.7),
                                      blurRadius: 8,
                                    )
                                  ]
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 9),
                      // Icon
                      Icon(
                        isActive ? tab.activeIcon : tab.icon,
                        size: 21,
                        color: isActive ? tab.color : _kNavDim,
                      ),
                      const SizedBox(height: 3),
                      // Label
                      Text(
                        tab.label,
                        style: TextStyle(
                          color: isActive ? tab.color : _kNavDim,
                          fontSize: 8,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
