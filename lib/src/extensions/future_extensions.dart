import 'dart:async';

import '../core/failure.dart';
import '../core/result.dart';

/// Extension methods for converting [Future] to [Result].
///
/// These extensions provide convenient ways to convert standard
/// async operations into Result-based operations with proper
/// error handling.
extension FutureToResultExtension<T> on Future<T> {
  /// Convert this [Future] to a [Result].
  ///
  /// If the future completes successfully, returns [Success] with the value.
  /// If the future throws, returns [Failure] with an [AppFailure].
  ///
  /// ## Example
  /// ```dart
  /// final result = await httpClient.get('/users/123').toResult();
  /// result.fold(
  ///   (user) => print('Got user: $user'),
  ///   (failure) => print('Error: ${failure.message}'),
  /// );
  /// ```
  Future<Result<T, AppFailure>> toResult() async {
    try {
      final value = await this;
      return Result.success(value);
    } catch (e, stackTrace) {
      return Result.failure(AppFailure.from(e, stackTrace));
    }
  }

  /// Convert this [Future] to a [Result] with a custom error mapper.
  ///
  /// The [onError] function is called to convert exceptions to [AppFailure].
  ///
  /// ## Example
  /// ```dart
  /// final result = await httpClient.get('/users/123').toResultWith(
  ///   onError: (e, st) => ServerFailure(e.toString(), stackTrace: st),
  /// );
  /// ```
  Future<Result<T, AppFailure>> toResultWith({
    required AppFailure Function(Object error, StackTrace stackTrace) onError,
  }) async {
    try {
      final value = await this;
      return Result.success(value);
    } catch (e, stackTrace) {
      return Result.failure(onError(e, stackTrace));
    }
  }

  /// Convert this [Future] to a [Result], catching only specific exception types.
  ///
  /// Exceptions of type [E] are converted to [AppFailure] using [onError].
  /// Other exceptions are rethrown.
  ///
  /// ## Example
  /// ```dart
  /// final result = await httpClient.get('/users/123').toResultCatching<HttpException>(
  ///   onError: (e, st) => ServerFailure(e.message, statusCode: e.statusCode),
  /// );
  /// ```
  Future<Result<T, AppFailure>> toResultCatching<E extends Object>({
    required AppFailure Function(E error, StackTrace stackTrace) onError,
  }) async {
    try {
      final value = await this;
      return Result.success(value);
    } on E catch (e, stackTrace) {
      return Result.failure(onError(e, stackTrace));
    }
  }
}

/// Extension methods for [Future<Result>].
extension FutureResultExtension<S, F> on Future<Result<S, F>> {
  /// Map the success value asynchronously.
  ///
  /// ## Example
  /// ```dart
  /// final result = await getUserUseCase('123')
  ///     .mapSuccess((user) => user.name);
  /// ```
  Future<Result<T, F>> mapSuccess<T>(T Function(S value) transform) async {
    return (await this).map(transform);
  }

  /// Map the failure value asynchronously.
  ///
  /// ## Example
  /// ```dart
  /// final result = await getUserUseCase('123')
  ///     .mapFailure((failure) => CustomFailure(failure));
  /// ```
  Future<Result<S, T>> mapFailure<T>(T Function(F error) transform) async {
    return (await this).mapFailure(transform);
  }

  /// FlatMap the success value asynchronously.
  ///
  /// ## Example
  /// ```dart
  /// final result = await getUserUseCase('123')
  ///     .flatMapSuccess((user) => getProfileUseCase(user.id));
  /// ```
  Future<Result<T, F>> flatMapSuccess<T>(
    Future<Result<T, F>> Function(S value) transform,
  ) async {
    final result = await this;
    return result.fold(
      (value) => transform(value),
      (error) async => Failure(error),
    );
  }

  /// Execute a side effect on success.
  ///
  /// ## Example
  /// ```dart
  /// final result = await getUserUseCase('123')
  ///     .onSuccess((user) => print('Got user: ${user.name}'));
  /// ```
  Future<Result<S, F>> onSuccess(void Function(S value) action) async {
    return (await this).onSuccess(action);
  }

  /// Execute a side effect on failure.
  ///
  /// ## Example
  /// ```dart
  /// final result = await getUserUseCase('123')
  ///     .onFailure((failure) => logger.warning('Failed: $failure'));
  /// ```
  Future<Result<S, F>> onFailure(void Function(F error) action) async {
    return (await this).onFailure(action);
  }

  /// Recover from a failure by providing an alternative value.
  ///
  /// ## Example
  /// ```dart
  /// final result = await getUserUseCase('123')
  ///     .recover((failure) => defaultUser);
  /// ```
  Future<Result<S, F>> recover(S Function(F error) recovery) async {
    final result = await this;
    return result.fold(
      (value) => Success(value),
      (error) => Success(recovery(error)),
    );
  }

  /// Recover from a failure by providing an alternative Result.
  ///
  /// ## Example
  /// ```dart
  /// final result = await getUserUseCase('123')
  ///     .recoverWith((failure) => getCachedUserUseCase('123'));
  /// ```
  Future<Result<S, F>> recoverWith(
    Future<Result<S, F>> Function(F error) recovery,
  ) async {
    final result = await this;
    return result.fold(
      (value) async => Success(value),
      (error) => recovery(error),
    );
  }
}

/// Extension for handling nullable futures.
extension FutureNullableExtension<T> on Future<T?> {
  /// Convert this nullable [Future] to a [Result].
  ///
  /// If the value is null, returns a [Failure] with [NotFoundFailure].
  ///
  /// ## Example
  /// ```dart
  /// final result = await repository.findUser('123').toResultOrNotFound();
  /// ```
  Future<Result<T, AppFailure>> toResultOrNotFound([String? message]) async {
    try {
      final value = await this;
      if (value == null) {
        return Result.failure(
          NotFoundFailure(message ?? 'Value not found'),
        );
      }
      return Result.success(value);
    } catch (e, stackTrace) {
      return Result.failure(AppFailure.from(e, stackTrace));
    }
  }

  /// Convert this nullable [Future] to a [Result].
  ///
  /// If the value is null, returns a [Failure] with the provided failure.
  ///
  /// ## Example
  /// ```dart
  /// final result = await repository.findUser('123')
  ///     .toResultOrFailure(ValidationFailure('User ID is required'));
  /// ```
  Future<Result<T, AppFailure>> toResultOrFailure(
    AppFailure failureIfNull,
  ) async {
    try {
      final value = await this;
      if (value == null) {
        return Result.failure(failureIfNull);
      }
      return Result.success(value);
    } catch (e, stackTrace) {
      return Result.failure(AppFailure.from(e, stackTrace));
    }
  }
}

/// Extension for combining multiple Result futures.
extension FutureResultListExtension<S, F> on Iterable<Future<Result<S, F>>> {
  /// Wait for all futures and collect successful results.
  ///
  /// If any future fails, returns the first failure.
  /// If all succeed, returns a list of all values.
  ///
  /// ## Example
  /// ```dart
  /// final results = await [
  ///   getUserUseCase('1'),
  ///   getUserUseCase('2'),
  ///   getUserUseCase('3'),
  /// ].collectResults();
  ///
  /// results.fold(
  ///   (users) => print('Got ${users.length} users'),
  ///   (failure) => print('Failed: $failure'),
  /// );
  /// ```
  Future<Result<List<S>, F>> collectResults() async {
    final results = await Future.wait(this);
    final values = <S>[];

    for (final result in results) {
      final failure = result.getFailureOrNull();
      if (failure != null) {
        return Failure(failure);
      }
      values.add(result.getOrNull() as S);
    }

    return Success(values);
  }

  /// Wait for all futures and collect all results (successes and failures).
  ///
  /// Always returns a list of all results, regardless of success or failure.
  ///
  /// ## Example
  /// ```dart
  /// final results = await [
  ///   getUserUseCase('1'),
  ///   getUserUseCase('invalid'),
  ///   getUserUseCase('3'),
  /// ].collectAll();
  ///
  /// final successes = results.where((r) => r.isSuccess).length;
  /// final failures = results.where((r) => r.isFailure).length;
  /// ```
  Future<List<Result<S, F>>> collectAll() => Future.wait(this);
}
