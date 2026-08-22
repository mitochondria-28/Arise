import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/auth/auth_provider.dart';
import 'core/routing/router.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: AriseApp()));
}

class AriseApp extends ConsumerWidget {
  const AriseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Reading authInitProvider here ensures initialization starts on first build.
    // The router watches it via _AuthChangeNotifier and redirects accordingly.
    ref.watch(authInitProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Arise',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
