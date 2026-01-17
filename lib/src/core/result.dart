/// Result type for Clean Architecture
///
/// A sealed class representing either a success or failure outcome.
/// Inspired by functional programming's Either type.
///
/// Use [Result.success] to wrap successful values.
/// Use [Result.failure] to wrap failure cases.
///
/// Example:
/// ```dart
/// Future<Result<User, AppFailure>> getUser(String id) async {
///   try {
///     final user = await repository.get(id);
///     return Result.success(user);
///   } catch (e, stackTrace) {
///     return Result.failure(AppFailure.from(e, stackTrace));
///   }
/// }
///
/// // Usage
/// final result = await getUser('123');
/// result.fold(
///   (user) => print('Got user: ${user.name}'),
///   (failure) => print('Error: ${failure.message}'),
/// );
/// ```
sealed class Result<S, F> {
  const Result();

  /// Create a success result
  const factory Result.success(S value) = Success<S, F>;

  /// Create a failure result
  const factory Result.failure(F error) = Failure<S, F>;

  /// Check if this is a success
  bool get isSuccess => this is Success<S, F>;

  /// Check if this is a failure
  bool get isFailure => this is Failure<S, F>;

  /// Fold the result into a single value
  ///
  /// Calls [onSuccess] if this is a [Success], [onFailure] if this is a [Failure].
  T fold<T>(
    T Function(S value) onSuccess,
    T Function(F error) onFailure,
  );

  /// Async version of [fold]
  Future<T> foldAsync<T>(
    Future<T> Function(S value) onSuccess,
    Future<T> Function(F error) onFailure,
  ) async {
    return fold(
      (value) => onSuccess(value),
      (error) => onFailure(error),
    );
  }

  /// Map the success value to a new type
  ///
  /// If this is a [Success], applies [transform] to the value.
  /// If this is a [Failure], returns the failure unchanged.
  Result<T, F> map<T>(T Function(S value) transform);

  /// Map the failure value to a new type
  ///
  /// If this is a [Failure], applies [transform] to the error.
  /// If this is a [Success], returns the success unchanged.
  Result<S, T> mapFailure<T>(T Function(F error) transform);

  /// FlatMap for chaining Result-returning operations
  ///
  /// If this is a [Success], applies [transform] which returns a new Result.
  /// If this is a [Failure], returns the failure unchanged.
  Result<T, F> flatMap<T>(Result<T, F> Function(S value) transform);

  /// Get the success value or return a default
  ///
  /// If this is a [Success], returns the value.
  /// If this is a [Failure], returns the result of [defaultValue].
  S getOrElse(S Function() defaultValue);

  /// Get the success value or null
  ///
  /// If this is a [Success], returns the value.
  /// If this is a [Failure], returns null.
  S? getOrNull();

  /// Get the success value or throw the failure
  ///
  /// If this is a [Success], returns the value.
  /// If this is a [Failure], throws the error (wrapped in Exception if needed).
  S getOrThrow();

  /// Get the failure value or null
  ///
  /// If this is a [Failure], returns the error.
  /// If this is a [Success], returns null.
  F? getFailureOrNull();

  /// Execute a side effect if this is a success
  Result<S, F> onSuccess(void Function(S value) action);

  /// Execute a side effect if this is a failure
  Result<S, F> onFailure(void Function(F error) action);

  /// Convert to a Future that completes with success or throws on failure
  Future<S> toFuture() async => getOrThrow();
}

/// Success case of [Result]
///
/// Wraps a successful value.
final class Success<S, F> extends Result<S, F> {
  /// The success value
  final S value;

  /// Create a success result with [value]
  const Success(this.value);

  @override
  T fold<T>(
    T Function(S value) onSuccess,
    T Function(F error) onFailure,
  ) =>
      onSuccess(value);

  @override
  Result<T, F> map<T>(T Function(S value) transform) =>
      Success(transform(value));

  @override
  Result<S, T> mapFailure<T>(T Function(F error) transform) => Success(value);

  @override
  Result<T, F> flatMap<T>(Result<T, F> Function(S value) transform) =>
      transform(value);

  @override
  S getOrElse(S Function() defaultValue) => value;

  @override
  S? getOrNull() => value;

  @override
  S getOrThrow() => value;

  @override
  F? getFailureOrNull() => null;

  @override
  Result<S, F> onSuccess(void Function(S value) action) {
    action(value);
    return this;
  }

  @override
  Result<S, F> onFailure(void Function(F error) action) => this;

  @override
  String toString() => 'Success($value)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Success<S, F> &&
          runtimeType == other.runtimeType &&
          value == other.value);

  @override
  int get hashCode => value.hashCode;
}

/// Failure case of [Result]
///
/// Wraps an error value.
final class Failure<S, F> extends Result<S, F> {
  /// The failure error
  final F error;

  /// Create a failure result with [error]
  const Failure(this.error);

  @override
  T fold<T>(
    T Function(S value) onSuccess,
    T Function(F error) onFailure,
  ) =>
      onFailure(error);

  @override
  Result<T, F> map<T>(T Function(S value) transform) => Failure(error);

  @override
  Result<S, T> mapFailure<T>(T Function(F error) transform) =>
      Failure(transform(error));

  @override
  Result<T, F> flatMap<T>(Result<T, F> Function(S value) transform) =>
      Failure(error);

  @override
  S getOrElse(S Function() defaultValue) => defaultValue();

  @override
  S? getOrNull() => null;

  @override
  S getOrThrow() {
    if (error is Exception) {
      throw error as Exception;
    } else if (error is Error) {
      throw error as Error;
    } else {
      throw Exception(error.toString());
    }
  }

  @override
  F? getFailureOrNull() => error;

  @override
  Result<S, F> onSuccess(void Function(S value) action) => this;

  @override
  Result<S, F> onFailure(void Function(F error) action) {
    action(error);
    return this;
  }

  @override
  String toString() => 'Failure($error)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Failure<S, F> &&
          runtimeType == other.runtimeType &&
          error == other.error);

  @override
  int get hashCode => error.hashCode;
}

/// Extension methods for [Result] with async operations
extension ResultAsyncExtensions<S, F> on Result<S, F> {
  /// Map the success value with an async function
  Future<Result<T, F>> mapAsync<T>(
      Future<T> Function(S value) transform) async {
    return fold(
      (value) async => Success(await transform(value)),
      (error) async => Failure(error),
    );
  }

  /// FlatMap with an async function
  Future<Result<T, F>> flatMapAsync<T>(
    Future<Result<T, F>> Function(S value) transform,
  ) async {
    return fold(
      (value) => transform(value),
      (error) async => Failure(error),
    );
  }
}

/// Extension methods for [Future<Result>]
extension FutureResultExtensions<S, F> on Future<Result<S, F>> {
  /// Map the success value
  Future<Result<T, F>> map<T>(T Function(S value) transform) async {
    return (await this).map(transform);
  }

  /// FlatMap for chaining
  Future<Result<T, F>> flatMap<T>(
    Future<Result<T, F>> Function(S value) transform,
  ) async {
    return (await this).fold(
      (value) => transform(value),
      (error) async => Failure(error),
    );
  }

  /// Get value or else
  Future<S> getOrElse(S Function() defaultValue) async {
    return (await this).getOrElse(defaultValue);
  }

  /// Get value or null
  Future<S?> getOrNull() async {
    return (await this).getOrNull();
  }

  /// Fold the result
  Future<T> fold<T>(
    T Function(S value) onSuccess,
    T Function(F error) onFailure,
  ) async {
    return (await this).fold(onSuccess, onFailure);
  }
}
