class ServerException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  ServerException({
    required this.message,
    this.statusCode,
    this.errors,
  });

  @override
  String toString() => 'ServerException: $message ($statusCode)';
}

class UnauthorizedException extends ServerException {
  UnauthorizedException({super.message = 'Unauthorized'})
      : super(statusCode: 401);
}

class NotFoundException extends ServerException {
  NotFoundException({super.message = 'Not found'})
      : super(statusCode: 404);
}

class ValidationException extends ServerException {
  ValidationException({super.message = 'Validation error', super.errors})
      : super(statusCode: 422);
}

class CacheException implements Exception {
  final String message;
  CacheException({required this.message});
}

class NetworkException implements Exception {
  final String message;
  NetworkException({required this.message});
}
