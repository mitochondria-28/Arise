import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';
import '../auth/auth_storage.dart';

class AuthInterceptor extends Interceptor {
  final Ref _ref;
  bool _isRefreshing = false;
  final List<({RequestOptions options, ErrorInterceptorHandler handler})> _queue = [];

  AuthInterceptor(this._ref);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _ref.read(authStorageProvider).accessToken;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    final requestOptions = err.requestOptions;

    // Skip refresh if this is already the refresh endpoint
    if (requestOptions.path.contains('/auth/refresh') ||
        requestOptions.path.contains('/auth/login')) {
      handler.next(err);
      return;
    }

    if (_isRefreshing) {
      // Queue this request to retry after the in-progress refresh
      _queue.add((options: requestOptions, handler: handler));
      return;
    }

    _isRefreshing = true;
    try {
      final newToken = await _ref.read(authProvider.notifier).silentRefresh();
      if (newToken == null) {
        handler.next(err);
        _flushQueue(null);
        return;
      }
      // Retry original request
      handler.resolve(await _retry(requestOptions, newToken));
      _flushQueue(newToken);
    } catch (_) {
      handler.next(err);
      _flushQueue(null);
    } finally {
      _isRefreshing = false;
    }
  }

  void _flushQueue(String? token) {
    final pending = List.of(_queue);
    _queue.clear();
    for (final item in pending) {
      if (token != null) {
        _retry(item.options, token).then(item.handler.resolve).catchError(
            (e) => item.handler.next(e as DioException));
      } else {
        item.handler.next(DioException(
          requestOptions: item.options,
          type: DioExceptionType.unknown,
          message: 'Session expired',
        ));
      }
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions options, String token) {
    final dio = Dio(BaseOptions(baseUrl: options.baseUrl));
    return dio.fetch(options..headers['Authorization'] = 'Bearer $token');
  }
}
