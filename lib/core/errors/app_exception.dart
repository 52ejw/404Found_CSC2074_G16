sealed class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

class AuthException extends AppException {
  const AuthException(super.message);
}

class NotFoundException extends AppException {
  const NotFoundException(super.message);
}

class PermissionDeniedException extends AppException {
  const PermissionDeniedException(super.message);
}

class StorageException extends AppException {
  const StorageException(super.message);
}

/// Catch-all for unexpected Firestore/network failures.
class RepositoryException extends AppException {
  const RepositoryException(super.message);
}
