/// Application-level error types for consistent error handling.
class AppException implements Exception {
  final String message;
  final String? details;
  final dynamic originalError;

  const AppException(this.message, {this.details, this.originalError});

  @override
  String toString() => 'AppException: $message${details != null ? ' ($details)' : ''}';
}

class AuthException extends AppException {
  const AuthException(super.message, {super.details, super.originalError});
}

class DatabaseException extends AppException {
  const DatabaseException(super.message, {super.details, super.originalError});
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.details, super.originalError});
}

class ValidationException extends AppException {
  const ValidationException(super.message, {super.details, super.originalError});
}

class BackupException extends AppException {
  const BackupException(super.message, {super.details, super.originalError});
}
