import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Keep in sync with _baseUrl in api_client.dart
// Override at build time: --dart-define=API_BASE_URL=<url>
const rawBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://192.168.1.67:8000/api/v1',
);

// No auth interceptor — safe for auth_repository to import without cycle:
//   auth_repository → raw_dio  (no further auth imports)
//   api_client → auth_interceptor → auth_provider → auth_repository → raw_dio ✓
final rawDioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: rawBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ),
  );
  assert(() {
    dio.interceptors
        .add(LogInterceptor(requestBody: true, responseBody: true, error: true));
    return true;
  }());
  return dio;
});
