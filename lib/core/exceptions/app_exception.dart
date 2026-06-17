class AppException implements Exception {
  const AppException(this.message, {this.code, this.cause});

  final String message;
  final String? code;
  final Object? cause;

  @override
  String toString() => 'AppException($code): $message';
}

class CacheException extends AppException {
  const CacheException(super.message, {super.cause})
    : super(code: 'cache_error');
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.cause})
    : super(code: 'network_error');
}
