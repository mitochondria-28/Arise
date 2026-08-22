import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_interceptor.dart';
import 'raw_dio.dart';

export 'raw_dio.dart' show rawDioProvider;

// Used by all feature APIs — injects Bearer token and handles silent refresh on 401.
// auth_repository uses rawDioProvider (from raw_dio.dart) to avoid circular imports.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: rawBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ),
  );
  dio.interceptors.add(AuthInterceptor(ref));
  assert(() {
    dio.interceptors
        .add(LogInterceptor(requestBody: true, responseBody: true, error: true));
    return true;
  }());
  return dio;
});
