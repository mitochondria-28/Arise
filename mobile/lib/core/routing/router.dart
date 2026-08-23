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

class _AppShell extends StatelessWidget {
  final Widget child;

  const _AppShell({required this.child});

  static const _tabs = [
    (icon: Icons.home_outlined, label: 'Home', path: '/dashboard'),
    (icon: Icons.task_alt_outlined, label: 'Missions', path: '/missions'),
    (icon: Icons.book_outlined, label: 'Journal', path: '/journal'),
    (icon: Icons.emoji_events_outlined, label: 'Awards', path: '/achievements'),
    (icon: Icons.person_outline, label: 'Hunter', path: '/character'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final idx = _tabs.indexWhere((t) => location.startsWith(t.path));
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex(context),
        onDestinationSelected: (i) => context.go(_tabs[i].path),
        destinations: _tabs
            .map((t) =>
                NavigationDestination(icon: Icon(t.icon), label: t.label))
            .toList(),
      ),
    );
  }
}
