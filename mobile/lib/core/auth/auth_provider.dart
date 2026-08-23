import 'dart:async';
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

    // Mark authenticated immediately from local storage — the user must never
    // land on the login screen just because the network is slow or the backend
    // hasn't started yet.
    final cachedEmail = await storage.getEmail();
    state = AuthState(status: AuthStatus.authenticated, email: cachedEmail);

    // Fire-and-forget: refresh tokens in the true background so authInitProvider
    // completes instantly and the router can navigate to the dashboard right away.
    // The auth interceptor handles the missing access token on the first API call.
    unawaited(_backgroundTokenRefresh(storage, refreshToken, cachedEmail));
  }

  Future<void> _backgroundTokenRefresh(
      AuthStorage storage, String refreshToken, String? cachedEmail) async {
    try {
      final tokens =
          await ref.read(authRepositoryProvider).refresh(refreshToken);
      storage.cacheAccessToken(tokens.accessToken);
      await storage.saveRefreshToken(tokens.refreshToken);
      final freshEmail = _decodeEmail(tokens.accessToken);
      if (freshEmail != null) await storage.saveEmail(freshEmail);
      if (state.isAuthenticated) {
        state = AuthState(
          status: AuthStatus.authenticated,
          email: freshEmail ?? cachedEmail,
        );
      }
    } on UnauthorizedException catch (_) {
      // Backend explicitly rejected the refresh token — force re-login.
      await storage.clearAll();
      state = const AuthState(status: AuthStatus.unauthenticated);
    } catch (_) {
      // Transient network error — keep the cached session alive.
      // The access token will be fetched on the first API call via silentRefresh.
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
    } on UnauthorizedException catch (_) {
      // Backend explicitly rejected the token — clear session and force re-login.
      await storage.clearAll();
      state = const AuthState(status: AuthStatus.unauthenticated);
      return null;
    } catch (_) {
      // Transient network error — return null so the API call fails gracefully
      // without logging the user out of a perfectly valid session.
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
