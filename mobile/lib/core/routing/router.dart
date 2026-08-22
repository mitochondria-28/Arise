import 'package:flutter/material.dart';
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
          GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
          GoRoute(path: '/goals',     builder: (_, __) => const GoalsScreen()),
          GoRoute(path: '/missions',  builder: (_, __) => const MissionsScreen()),
          GoRoute(path: '/character', builder: (_, __) => const CharacterScreen()),
          GoRoute(path: '/coach',     builder: (_, __) => const AICoachScreen()),
          GoRoute(path: '/stats',        builder: (_, __) => const StatsScreen()),
          GoRoute(path: '/achievements', builder: (_, __) => const AchievementsScreen()),
          GoRoute(path: '/journal',      builder: (_, __) => const JournalScreen()),
          GoRoute(path: '/profile',      builder: (_, __) => const ProfileScreen()),
          GoRoute(path: '/skills',       builder: (_, __) => const SkillsScreen()),
        ],
      ),
    ],
  );
});

class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Ref ref) {
    ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
    ref.listen<AsyncValue<void>>(authInitProvider, (_, __) => notifyListeners());
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ARISE',
              style: TextStyle(
                color: cs.primary,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  cs.onSurface.withValues(alpha: 0.3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppShell extends StatelessWidget {
  final Widget child;

  const _AppShell({required this.child});

  static const _tabs = [
    (icon: Icons.home_outlined,           label: 'Home',      path: '/dashboard'),
    (icon: Icons.task_alt_outlined,       label: 'Missions',  path: '/missions'),
    (icon: Icons.book_outlined,           label: 'Journal',   path: '/journal'),
    (icon: Icons.emoji_events_outlined,   label: 'Awards',    path: '/achievements'),
    (icon: Icons.person_outline,          label: 'Hunter',    path: '/character'),
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
            .map((t) => NavigationDestination(icon: Icon(t.icon), label: t.label))
            .toList(),
      ),
    );
  }
}
