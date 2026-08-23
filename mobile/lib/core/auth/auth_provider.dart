import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_repository.dart';
import 'auth_state.dart';
import 'auth_storage.dart';
import '../errors/app_exception.dart';

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  Future<void> initialize() async {
    state = state.copyWith(status: AuthStatus.loading);
    final storage = ref.read(authStorageProvider);
    final refreshToken = await storage.getRefreshToken();

    if (refreshToken == null) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }

    // Token is locally expired — no point trying the network.
    if (_isTokenExpired(refreshToken)) {
      await storage.clearAll();
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }

    // Restore session immediately from local storage so the user never sees
    // the login screen just because the network is slow or unavailable.
    final cachedEmail = await storage.getEmail();
    state = AuthState(status: AuthStatus.authenticated, email: cachedEmail);

    // Silently exchange the refresh token for a fresh pair in the background.
    try {
      final tokens =
          await ref.read(authRepositoryProvider).refresh(refreshToken);
      storage.cacheAccessToken(tokens.accessToken);
      await storage.saveRefreshToken(tokens.refreshToken);
      final freshEmail = _decodeEmail(tokens.accessToken);
      if (freshEmail != null) await storage.saveEmail(freshEmail);
      state = AuthState(
        status: AuthStatus.authenticated,
        email: freshEmail ?? cachedEmail,
      );
    } on UnauthorizedException catch (_) {
      // Backend explicitly rejected the token — force re-login.
      await storage.clearAll();
      state = const AuthState(status: AuthStatus.unauthenticated);
    } catch (_) {
      // Transient error (network down, server unreachable) — user stays
      // authenticated with the cached session until their access token expires,
      // at which point the auth interceptor will retry silentRefresh.
    }
  }

  Future<void> login(String email, String password) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      final tokens = await ref.read(authRepositoryProvider).login(email, password);
      final storage = ref.read(authStorageProvider);
      final resolvedEmail = _decodeEmail(tokens.accessToken) ?? email;
      storage.cacheAccessToken(tokens.accessToken);
      await storage.saveRefreshToken(tokens.refreshToken);
      await storage.saveEmail(resolvedEmail);
      state = AuthState(status: AuthStatus.authenticated, email: resolvedEmail);
    } on AppException catch (e) {
      state = AuthState(status: AuthStatus.unauthenticated, error: e.message);
    }
  }

  Future<void> register(String email, String password) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      final tokens = await ref.read(authRepositoryProvider).register(email, password);
      final storage = ref.read(authStorageProvider);
      final resolvedEmail = _decodeEmail(tokens.accessToken) ?? email;
      storage.cacheAccessToken(tokens.accessToken);
      await storage.saveRefreshToken(tokens.refreshToken);
      await storage.saveEmail(resolvedEmail);
      state = AuthState(status: AuthStatus.authenticated, email: resolvedEmail);
    } on AppException catch (e) {
      state = AuthState(status: AuthStatus.unauthenticated, error: e.message);
    }
  }

  Future<void> logout() async {
    final storage = ref.read(authStorageProvider);
    final refreshToken = await storage.getRefreshToken();
    if (refreshToken != null) {
      await ref.read(authRepositoryProvider).logout(refreshToken);
    }
    await storage.clearAll();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  // Refresh token silently — called by auth interceptor on 401
  Future<String?> silentRefresh() async {
    final storage = ref.read(authStorageProvider);
    final refreshToken = await storage.getRefreshToken();
    if (refreshToken == null) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return null;
    }
    try {
      final tokens = await ref.read(authRepositoryProvider).refresh(refreshToken);
      storage.cacheAccessToken(tokens.accessToken);
      await storage.saveRefreshToken(tokens.refreshToken);
      return tokens.accessToken;
    } catch (_) {
      await storage.clearAll();
      state = const AuthState(status: AuthStatus.unauthenticated);
      return null;
    }
  }

  Map<String, dynamic>? _decodePayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      var payload = parts[1];
      payload = payload.padRight((payload.length + 3) ~/ 4 * 4, '=');
      final decoded = utf8.decode(base64Decode(payload));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  String? _decodeEmail(String token) => _decodePayload(token)?['sub'] as String?;

  bool _isTokenExpired(String token) {
    final payload = _decodePayload(token);
    if (payload == null) return true;
    final exp = payload['exp'];
    if (exp == null) return true;
    final expiry = DateTime.fromMillisecondsSinceEpoch((exp as int) * 1000, isUtc: true);
    return DateTime.now().toUtc().isAfter(expiry);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

// Drives initialization once — watched by the router to know when auth is ready
final authInitProvider = FutureProvider<void>((ref) async {
  await ref.read(authProvider.notifier).initialize();
});
