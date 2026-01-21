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

    // Try each failure type's factory in order of specificity
    return NetworkFailure.from(error, stackTrace) ??
        TimeoutFailure.from(error, stackTrace) ??
        NotFoundFailure.from(error, stackTrace) ??
        UnauthorizedFailure.from(error, stackTrace) ??
        ForbiddenFailure.from(error, stackTrace) ??
        ValidationFailure.from(error, stackTrace) ??
        ConflictFailure.from(error, stackTrace) ??
        ServerFailure.from(error, stackTrace) ??
        CacheFailure.from(error, stackTrace) ??
        UnknownFailure.from(error, stackTrace);
  }

  /// Create a server error failure
  const factory AppFailure.server(
    String message, {
    int? statusCode,
    StackTrace? stackTrace,
    Object? cause,
  }) = ServerFailure;

  /// Create a network failure
  const factory AppFailure.network(
    String message, {
    StackTrace? stackTrace,
    Object? cause,
  }) = NetworkFailure;

  /// Create a cache failure
  const factory AppFailure.cache(
    String message, {
    StackTrace? stackTrace,
    Object? cause,
  }) = CacheFailure;

  /// Create a validation failure
  const factory AppFailure.validation(
    String message, {
    Map<String, List<String>>? fieldErrors,
    StackTrace? stackTrace,
    Object? cause,
  }) = ValidationFailure;

  /// Create a not found failure
  const factory AppFailure.notFound(
    String message, {
    String? resourceId,
    String? resourceType,
    StackTrace? stackTrace,
    Object? cause,
  }) = NotFoundFailure;

  /// Create an unauthorized failure
  const factory AppFailure.unauthorized(
    String message, {
    StackTrace? stackTrace,
    Object? cause,
  }) = UnauthorizedFailure;

  /// Create a forbidden failure
  const factory AppFailure.forbidden(
    String message, {
    String? requiredPermission,
    StackTrace? stackTrace,
    Object? cause,
  }) = ForbiddenFailure;

  /// Create a conflict failure
  const factory AppFailure.conflict(
    String message, {
    String? conflictType,
    StackTrace? stackTrace,
    Object? cause,
  }) = ConflictFailure;

  /// Create a timeout failure
  const factory AppFailure.timeout(
    String message, {
    Duration? timeout,
    StackTrace? stackTrace,
    Object? cause,
  }) = TimeoutFailure;

  /// Create a cancellation failure
  const factory AppFailure.cancellation([
    String message,
  ]) = CancellationFailure;

  /// Create an unknown failure
  const factory AppFailure.unknown(
    String message, {
    StackTrace? stackTrace,
    Object? cause,
  }) = UnknownFailure;

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

  /// Factory that creates a ServerFailure if the error matches,
  /// otherwise returns null
  static ServerFailure? from(Object error, StackTrace? stackTrace) {
    final message = error.toString().toLowerCase();

    // Check for HTTP status codes (must be followed by space, end of line, or common HTTP patterns)
    final hasStatusCode =
        RegExp(r'(^|\s)(500|502|503|504)(\s|:|$)').hasMatch(message);

    if (hasStatusCode ||
        message.contains('internal server error') ||
        message.contains('bad gateway') ||
        message.contains('service unavailable')) {
      return ServerFailure(
        error.toString(),
        stackTrace: stackTrace,
        cause: error,
      );
    }
    return null;
  }

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

  /// Factory that creates a NetworkFailure if the error matches,
  /// otherwise returns null
  static NetworkFailure? from(Object error, StackTrace? stackTrace) {
    final message = error.toString().toLowerCase();

    if (message.contains('socketexception') ||
        message.contains('connection refused') ||
        message.contains('connection reset') ||
        message.contains('connection closed') ||
        message.contains('network is unreachable') ||
        message.contains('no internet') ||
        message.contains('no address associated') ||
        message.contains('failed host lookup')) {
      return NetworkFailure(
        error.toString(),
        stackTrace: stackTrace,
        cause: error,
      );
    }
    return null;
  }
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

  /// Factory that creates a CacheFailure if the error matches,
  /// otherwise returns null
  static CacheFailure? from(Object error, StackTrace? stackTrace) {
    final message = error.toString().toLowerCase();

    if (message.contains('cache') ||
        message.contains('storage') ||
        message.contains('database') ||
        message.contains('hiveerror') ||
        message.contains('shared preferences')) {
      return CacheFailure(
        error.toString(),
        stackTrace: stackTrace,
        cause: error,
      );
    }
    return null;
  }
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

  /// Factory that creates a ValidationFailure if the error matches,
  /// otherwise returns null
  static ValidationFailure? from(Object error, StackTrace? stackTrace) {
    final message = error.toString().toLowerCase();

    if (message.contains('invalid') ||
        message.contains('validation') ||
        message.contains('format exception') ||
        message.contains('argument error') ||
        message.contains('required field')) {
      return ValidationFailure(
        error.toString(),
        stackTrace: stackTrace,
        cause: error,
      );
    }
    return null;
  }

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

  /// Factory that creates a NotFoundFailure if the error matches,
  /// otherwise returns null
  static NotFoundFailure? from(Object error, StackTrace? stackTrace) {
    final message = error.toString().toLowerCase();

    // Check for HTTP status code 404 (must be a standalone number)
    final hasStatusCode = RegExp(r'(^|\s)404(\s|:|$)').hasMatch(message);

    if (hasStatusCode ||
        message.contains('not found') ||
        message.contains('does not exist')) {
      return NotFoundFailure(
        error.toString(),
        stackTrace: stackTrace,
        cause: error,
      );
    }
    return null;
  }

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

  /// Factory that creates an UnauthorizedFailure if the error matches,
  /// otherwise returns null
  static UnauthorizedFailure? from(Object error, StackTrace? stackTrace) {
    final message = error.toString().toLowerCase();

    // Check for HTTP status code 401 (must be a standalone number)
    final hasStatusCode = RegExp(r'(^|\s)401(\s|:|$)').hasMatch(message);

    if (hasStatusCode ||
        message.contains('unauthorized') ||
        message.contains('unauthenticated') ||
        message.contains('invalid token') ||
        message.contains('token expired')) {
      return UnauthorizedFailure(
        error.toString(),
        stackTrace: stackTrace,
        cause: error,
      );
    }
    return null;
  }
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

  /// Factory that creates a ForbiddenFailure if the error matches,
  /// otherwise returns null
  static ForbiddenFailure? from(Object error, StackTrace? stackTrace) {
    final message = error.toString().toLowerCase();

    // Check for HTTP status code 403 (must be a standalone number)
    final hasStatusCode = RegExp(r'(^|\s)403(\s|:|$)').hasMatch(message);

    if (hasStatusCode || message.contains('forbidden')) {
      return ForbiddenFailure(
        error.toString(),
        stackTrace: stackTrace,
        cause: error,
      );
    }
    return null;
  }
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

  /// Factory that creates a ConflictFailure if the error matches,
  /// otherwise returns null
  static ConflictFailure? from(Object error, StackTrace? stackTrace) {
    final message = error.toString().toLowerCase();

    // Check for HTTP status code 409 (must be a standalone number)
    final hasStatusCode = RegExp(r'(^|\s)409(\s|:|$)').hasMatch(message);

    if (hasStatusCode ||
        message.contains('conflict') ||
        message.contains('duplicate') ||
        message.contains('already exists')) {
      return ConflictFailure(
        error.toString(),
        stackTrace: stackTrace,
        cause: error,
      );
    }
    return null;
  }
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

  /// Factory that creates a TimeoutFailure if the error matches,
  /// otherwise returns null
  static TimeoutFailure? from(Object error, StackTrace? stackTrace) {
    final message = error.toString().toLowerCase();

    if (message.contains('timeout') ||
        message.contains('timed out') ||
        message.contains('deadline exceeded')) {
      return TimeoutFailure(
        error.toString(),
        stackTrace: stackTrace,
        cause: error,
      );
    }
    return null;
  }

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

  /// Factory that always creates an UnknownFailure
  /// This is the fallback when no other failure type matches
  static UnknownFailure from(Object error, StackTrace? stackTrace) {
    return UnknownFailure(
      error.toString(),
      stackTrace: stackTrace,
      cause: error,
    );
  }
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
