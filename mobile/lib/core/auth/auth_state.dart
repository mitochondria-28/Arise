enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final String? email;
  final String? error;

  const AuthState({
    this.status = AuthStatus.initial,
    this.email,
    this.error,
  });

  bool get isAuthenticated  => status == AuthStatus.authenticated;
  bool get isLoading        => status == AuthStatus.loading || status == AuthStatus.initial;
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;

  AuthState copyWith({
    AuthStatus? status,
    String? email,
    String? error,
  }) =>
      AuthState(
        status: status ?? this.status,
        email: email ?? this.email,
        error: error ?? this.error,
      );

  AuthState clearError() => AuthState(status: status, email: email);
}
