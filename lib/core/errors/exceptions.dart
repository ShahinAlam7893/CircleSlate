// lib/core/exceptions/app_exception.dart
class AppException implements Exception {
  final String? message;
  final String? prefix;
  final String? url;
  AppException([this.message, this.prefix, this.url]);
  @override String toString() => '$prefix: $message\nURL: $url';
}

class FetchDataException extends AppException {
  FetchDataException([String? message, String? url]) : super(message, 'Network Error', url);
}
class BadRequestException extends AppException {
  BadRequestException([String? message, String? url]) : super(message, 'Invalid Request', url);
}
class UnauthorizedException extends AppException {
  UnauthorizedException([String? message, String? url]) : super(message, 'Unauthorized', url);
}
class NotFoundException extends AppException {
  NotFoundException([String? message, String? url]) : super(message, 'Not Found', url);
}
class ServerException extends AppException {
  ServerException([String? message, String? url]) : super(message, 'Server Error', url);
}
class TimeoutException extends AppException {
  TimeoutException([String? message, String? url]) : super(message, 'Request Timeout', url);
}