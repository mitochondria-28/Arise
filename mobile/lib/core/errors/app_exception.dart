import 'package:dio/dio.dart';

sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'No internet connection.']);
}

class ServerException extends AppException {
  const ServerException(super.message, {this.code});
  final String? code;
}

class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'Session expired. Please log in again.']);
}

class NotFoundException extends AppException {
  const NotFoundException(super.message);
}

class ValidationException extends AppException {
  const ValidationException(super.message);
}

AppException fromDioError(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.sendTimeout:
      return const NetworkException('Request timed out.');
    case DioExceptionType.connectionError:
      return const NetworkException();
    case DioExceptionType.badResponse:
      final status = e.response?.statusCode;
      final body = e.response?.data;
      final error   = body is Map ? body['error'] as Map? : null;
      final message = error?['message'] as String? ?? 'Unknown error';
      final code    = error?['code'] as String?;
      if (status == 401) return const UnauthorizedException();
      if (status == 404) return NotFoundException(message);
      if (status == 422) return ValidationException(message);
      return ServerException(message, code: code);
    default:
      return ServerException(e.message ?? 'Unexpected error.');
  }
}
