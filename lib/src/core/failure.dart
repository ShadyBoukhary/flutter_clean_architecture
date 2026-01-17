/// Failure types for Clean Architecture
///
/// A sealed class hierarchy representing different types of failures
/// that can occur in the application. Using sealed classes enables
/// exhaustive pattern matching in switch expressions.
///
/// Example:
/// ```dart
/// void handleFailure(AppFailure failure) {
///   switch (failure) {
///     case ServerFailure(:final statusCode):
///       print('Server error: $statusCode');
///     case NetworkFailure():
///       print('Check your connection');
///     case ValidationFailure(:final fieldErrors):
///       print('Invalid input: $fieldErrors');
///     case NotFoundFailure():
///       print('Resource not found');
///     case UnauthorizedFailure():
///       print('Please login');
///     case ForbiddenFailure():
///       print('Access denied');
///     case CacheFailure():
///       print('Cache error');
///     case TimeoutFailure():
///       print('Request timed out');
///     case CancellationFailure():
///       print('Operation cancelled');
///     case ConflictFailure():
///       print('Conflict detected');
///     case UnknownFailure():
///       print('Something went wrong');
///   }
/// }
/// ```
sealed class AppFailure implements Exception {
  /// Human-readable error message
  final String message;

  /// Stack trace from where the failure originated
  final StackTrace? stackTrace;

  /// The original error/exception that caused this failure
  final Object? cause;

  const AppFailure(
    this.message, {
    this.stackTrace,
    this.cause,
  });

  /// Create an [AppFailure] from any error
  ///
  /// Attempts to intelligently classify the error based on its type and message.
  factory AppFailure.from(Object error, [StackTrace? stackTrace]) {
    // Already an AppFailure, return as-is
    if (error is AppFailure) {
      return error;
    }

    final message = error.toString();
    final lowerMessage = message.toLowerCase();

    // Network-related errors
    if (_isNetworkError(lowerMessage)) {
      return NetworkFailure(message, stackTrace: stackTrace, cause: error);
    }

    // Timeout errors
    if (_isTimeoutError(lowerMessage)) {
      return TimeoutFailure(message, stackTrace: stackTrace, cause: error);
    }

    // Not found errors
    if (_isNotFoundError(lowerMessage)) {
      return NotFoundFailure(message, stackTrace: stackTrace, cause: error);
    }

    // Unauthorized errors
    if (_isUnauthorizedError(lowerMessage)) {
      return UnauthorizedFailure(message, stackTrace: stackTrace, cause: error);
    }

    // Forbidden errors
    if (_isForbiddenError(lowerMessage)) {
      return ForbiddenFailure(message, stackTrace: stackTrace, cause: error);
    }

    // Server errors
    if (_isServerError(lowerMessage)) {
      return ServerFailure(message, stackTrace: stackTrace, cause: error);
    }

    // Default to unknown
    return UnknownFailure(message, stackTrace: stackTrace, cause: error);
  }

  static bool _isNetworkError(String message) =>
      message.contains('socketexception') ||
      message.contains('connection refused') ||
      message.contains('connection reset') ||
      message.contains('connection closed') ||
      message.contains('network is unreachable') ||
      message.contains('no internet') ||
      message.contains('no address associated') ||
      message.contains('failed host lookup');

  static bool _isTimeoutError(String message) =>
      message.contains('timeout') ||
      message.contains('timed out') ||
      message.contains('deadline exceeded');

  static bool _isNotFoundError(String message) =>
      message.contains('404') ||
      message.contains('not found') ||
      message.contains('does not exist');

  static bool _isUnauthorizedError(String message) =>
      message.contains('401') ||
      message.contains('unauthorized') ||
      message.contains('unauthenticated') ||
      message.contains('invalid token') ||
      message.contains('token expired');

  static bool _isForbiddenError(String message) =>
      message.contains('403') || message.contains('forbidden');

  static bool _isServerError(String message) =>
      message.contains('500') ||
      message.contains('502') ||
      message.contains('503') ||
      message.contains('504') ||
      message.contains('internal server error') ||
      message.contains('bad gateway') ||
      message.contains('service unavailable');

  @override
  String toString() => '$runtimeType: $message';
}

/// Server-related failures (5xx HTTP errors)
///
/// Use when the server returns an error status code (500-599)
/// or when the server response indicates an internal error.
final class ServerFailure extends AppFailure {
  /// HTTP status code if available
  final int? statusCode;

  const ServerFailure(
    super.message, {
    this.statusCode,
    super.stackTrace,
    super.cause,
  });

  @override
  String toString() => statusCode != null
      ? 'ServerFailure($statusCode): $message'
      : 'ServerFailure: $message';
}

/// Network-related failures
///
/// Use when there are connection issues, DNS failures,
/// or the device is offline.
final class NetworkFailure extends AppFailure {
  const NetworkFailure(
    super.message, {
    super.stackTrace,
    super.cause,
  });
}

/// Cache-related failures
///
/// Use when there are issues reading from or writing to local storage,
/// or when cached data is corrupted or expired.
final class CacheFailure extends AppFailure {
  const CacheFailure(
    super.message, {
    super.stackTrace,
    super.cause,
  });
}

/// Validation failures
///
/// Use when input data fails validation rules.
/// Optionally includes field-specific error messages.
final class ValidationFailure extends AppFailure {
  /// Map of field names to their error messages
  final Map<String, List<String>>? fieldErrors;

  const ValidationFailure(
    super.message, {
    this.fieldErrors,
    super.stackTrace,
    super.cause,
  });

  /// Check if a specific field has errors
  bool hasErrorFor(String field) => fieldErrors?.containsKey(field) ?? false;

  /// Get errors for a specific field
  List<String> errorsFor(String field) => fieldErrors?[field] ?? const [];

  /// Get the first error for a field, or null
  String? firstErrorFor(String field) => errorsFor(field).firstOrNull;

  @override
  String toString() {
    if (fieldErrors != null && fieldErrors!.isNotEmpty) {
      return 'ValidationFailure: $message - $fieldErrors';
    }
    return 'ValidationFailure: $message';
  }
}

/// Not found failures (404 HTTP errors)
///
/// Use when a requested resource does not exist.
final class NotFoundFailure extends AppFailure {
  /// The identifier of the resource that was not found
  final String? resourceId;

  /// The type of resource that was not found
  final String? resourceType;

  const NotFoundFailure(
    super.message, {
    this.resourceId,
    this.resourceType,
    super.stackTrace,
    super.cause,
  });

  @override
  String toString() {
    if (resourceType != null && resourceId != null) {
      return 'NotFoundFailure: $resourceType with id $resourceId not found';
    }
    return 'NotFoundFailure: $message';
  }
}

/// Unauthorized failures (401 HTTP errors)
///
/// Use when authentication is required but missing or invalid.
/// The user needs to login or refresh their credentials.
final class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure(
    super.message, {
    super.stackTrace,
    super.cause,
  });
}

/// Forbidden failures (403 HTTP errors)
///
/// Use when the user is authenticated but lacks permission
/// to access the requested resource.
final class ForbiddenFailure extends AppFailure {
  /// The permission that was required but not granted
  final String? requiredPermission;

  const ForbiddenFailure(
    super.message, {
    this.requiredPermission,
    super.stackTrace,
    super.cause,
  });
}

/// Conflict failures (409 HTTP errors)
///
/// Use when the request conflicts with the current state of the resource,
/// such as duplicate entries or version conflicts.
final class ConflictFailure extends AppFailure {
  /// The type of conflict
  final String? conflictType;

  const ConflictFailure(
    super.message, {
    this.conflictType,
    super.stackTrace,
    super.cause,
  });
}

/// Timeout failures
///
/// Use when an operation takes too long to complete.
final class TimeoutFailure extends AppFailure {
  /// The duration that was exceeded
  final Duration? timeout;

  const TimeoutFailure(
    super.message, {
    this.timeout,
    super.stackTrace,
    super.cause,
  });

  @override
  String toString() {
    if (timeout != null) {
      return 'TimeoutFailure: $message (timeout: ${timeout!.inSeconds}s)';
    }
    return 'TimeoutFailure: $message';
  }
}

/// Cancellation failures
///
/// Use when an operation is explicitly cancelled by the user or system.
/// This is typically not shown as an error to the user.
final class CancellationFailure extends AppFailure {
  const CancellationFailure([
    super.message = 'Operation was cancelled',
  ]) : super(
          stackTrace: null,
          cause: null,
        );
}

/// Unknown/generic failures
///
/// Use as a fallback when the error type cannot be determined.
/// Prefer using more specific failure types when possible.
final class UnknownFailure extends AppFailure {
  const UnknownFailure(
    super.message, {
    super.stackTrace,
    super.cause,
  });
}

/// Extension to convert exceptions to failures
extension ExceptionToFailure on Exception {
  /// Convert this exception to an [AppFailure]
  AppFailure toFailure([StackTrace? stackTrace]) {
    return AppFailure.from(this, stackTrace);
  }
}

/// Extension to convert errors to failures
extension ErrorToFailure on Error {
  /// Convert this error to an [AppFailure]
  AppFailure toFailure([StackTrace? stackTrace]) {
    return AppFailure.from(this, stackTrace ?? this.stackTrace);
  }
}
