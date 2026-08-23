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
    try {
      final tokens = await ref.read(authRepositoryProvider).refresh(refreshToken);
      storage.cacheAccessToken(tokens.accessToken);
      await storage.saveRefreshToken(tokens.refreshToken);
      state = AuthState(
        status: AuthStatus.authenticated,
        email: _decodeEmail(tokens.accessToken),
      );
    } on UnauthorizedException catch (_) {
      // Token is genuinely invalid or expired — must log in again.
      await storage.clearAll();
      state = state.copyWith(status: AuthStatus.unauthenticated);
    } catch (_) {
      // Transient error (network down, server unreachable) — keep the token
      // so the next app launch can retry rather than forcing re-login.
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      final tokens = await ref.read(authRepositoryProvider).login(email, password);
      final storage = ref.read(authStorageProvider);
      storage.cacheAccessToken(tokens.accessToken);
      await storage.saveRefreshToken(tokens.refreshToken);
      state = AuthState(
        status: AuthStatus.authenticated,
        email: _decodeEmail(tokens.accessToken) ?? email,
      );
    } on AppException catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: e.message,
      );
    }
  }

  Future<void> register(String email, String password) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      final tokens = await ref.read(authRepositoryProvider).register(email, password);
      final storage = ref.read(authStorageProvider);
      storage.cacheAccessToken(tokens.accessToken);
      await storage.saveRefreshToken(tokens.refreshToken);
      state = AuthState(
        status: AuthStatus.authenticated,
        email: _decodeEmail(tokens.accessToken) ?? email,
      );
    } on AppException catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: e.message,
      );
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

  String? _decodeEmail(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      var payload = parts[1];
      // Pad to multiple of 4
      payload = payload.padRight((payload.length + 3) ~/ 4 * 4, '=');
      final decoded = utf8.decode(base64Decode(payload));
      final map = jsonDecode(decoded) as Map<String, dynamic>;
      return map['sub'] as String?;
    } catch (_) {
      return null;
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

// Drives initialization once — watched by the router to know when auth is ready
final authInitProvider = FutureProvider<void>((ref) async {
  await ref.read(authProvider.notifier).initialize();
});
