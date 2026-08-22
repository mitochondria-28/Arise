import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../errors/app_exception.dart';
import '../models/auth.dart';
import '../network/raw_dio.dart';

class AuthRepository {
  final Dio _dio; // expects rawDioProvider — no auth interceptor

  const AuthRepository(this._dio);

  Future<TokenResponse> login(String email, String password) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      return TokenResponse.fromJson(res.data!);
    } on DioException catch (e) {
      throw fromDioError(e);
    }
  }

  Future<TokenResponse> register(String email, String password) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/register',
        data: {'email': email, 'password': password},
      );
      return TokenResponse.fromJson(res.data!);
    } on DioException catch (e) {
      throw fromDioError(e);
    }
  }

  Future<TokenResponse> refresh(String refreshToken) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      return TokenResponse.fromJson(res.data!);
    } on DioException catch (e) {
      throw fromDioError(e);
    }
  }

  Future<void> logout(String refreshToken) async {
    try {
      await _dio.post<void>(
        '/auth/logout',
        data: {'refresh_token': refreshToken},
      );
    } on DioException {
      // Best-effort; proceed with local cleanup regardless
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  // rawDioProvider has no auth interceptor — avoids circular import with dioProvider
  return AuthRepository(ref.watch(rawDioProvider));
});
