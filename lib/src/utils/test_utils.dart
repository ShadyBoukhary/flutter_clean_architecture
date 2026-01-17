import 'dart:async';

import '../core/failure.dart';
import '../core/result.dart';
import '../domain/observer.dart';

/// Test utilities for flutter_clean_architecture.
///
/// These utilities help write reliable, non-flaky tests by providing
/// proper synchronization instead of arbitrary delays.

// ============================================================
// Test Observers
// ============================================================

/// A test observer that collects results and provides completion futures.
///
/// Use this instead of arbitrary `Future.delayed` in tests.
///
/// ## Example
/// ```dart
/// test('GetUserUseCase returns user on success', () async {
///   final observer = TestObserver<User>();
///
///   getUserUseCase.listen('user-123', observer: observer);
///
///   // Wait for completion with timeout
///   final results = await observer.waitForCompletion();
///
///   expect(results, hasLength(1));
///   expect(results.first.name, equals('John'));
/// });
/// ```
class TestObserver<T> extends Observer<T> {
  final Completer<List<T>> _completer = Completer();
  final List<T> _values = [];
  final List<AppFailure> _failures = [];

  bool _isDone = false;

  /// All successful values received
  List<T> get values => List.unmodifiable(_values);

  /// All failures received
  List<AppFailure> get failures => List.unmodifiable(_failures);

  /// Whether the stream has completed
  bool get isDone => _isDone;

  /// Whether any failures were received
  bool get hasFailures => _failures.isNotEmpty;

  /// The first failure, if any
  AppFailure? get firstFailure => _failures.firstOrNull;

  @override
  void onData(T data) {
    _values.add(data);
  }

  @override
  void onError(AppFailure failure) {
    _failures.add(failure);
  }

  @override
  void onDone() {
    _isDone = true;
    if (!_completer.isCompleted) {
      _completer.complete(_values);
    }
  }

  /// Wait for the stream to complete.
  ///
  /// Returns all successful values received.
  /// Throws [TimeoutException] if the timeout is exceeded.
  Future<List<T>> waitForCompletion({
    Duration timeout = const Duration(seconds: 5),
  }) {
    return _completer.future.timeout(
      timeout,
      onTimeout: () {
        throw TimeoutException(
          'TestObserver timed out waiting for completion. '
          'Received ${_values.length} values, ${_failures.length} failures.',
          timeout,
        );
      },
    );
  }

  /// Wait for a specific number of values.
  ///
  /// Returns when at least [count] values have been received.
  Future<List<T>> waitForValues(
    int count, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final stopwatch = Stopwatch()..start();

    while (_values.length < count) {
      if (stopwatch.elapsed > timeout) {
        throw TimeoutException(
          'TestObserver timed out waiting for $count values. '
          'Received ${_values.length} values.',
          timeout,
        );
      }
      await Future.delayed(const Duration(milliseconds: 10));
    }

    return values;
  }

  /// Wait for any failure.
  ///
  /// Returns the first failure received.
  Future<AppFailure> waitForFailure({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final stopwatch = Stopwatch()..start();

    while (_failures.isEmpty) {
      if (stopwatch.elapsed > timeout) {
        throw TimeoutException(
          'TestObserver timed out waiting for failure. '
          'Received ${_values.length} values instead.',
          timeout,
        );
      }
      await Future.delayed(const Duration(milliseconds: 10));
    }

    return _failures.first;
  }

  /// Reset the observer for reuse.
  void reset() {
    _values.clear();
    _failures.clear();
    _isDone = false;
  }
}

// ============================================================
// Result Matchers - Abstract base for test matchers
// ============================================================

/// Check if a Result is a Success
bool isResultSuccess<S, F>(Result<S, F> result) => result.isSuccess;

/// Check if a Result is a Failure
bool isResultFailure<S, F>(Result<S, F> result) => result.isFailure;

/// Check if a Result is a Failure of a specific type
bool isResultFailureOfType<F extends AppFailure>(
    Result<dynamic, AppFailure> result) {
  return result.isFailure && result.getFailureOrNull() is F;
}

/// Check if a Result failure message contains a substring
bool resultFailureContains(
    Result<dynamic, AppFailure> result, String substring) {
  if (result.isFailure) {
    final failure = result.getFailureOrNull();
    if (failure is AppFailure) {
      return failure.message.contains(substring);
    }
  }
  return false;
}

// ============================================================
// Test Helpers
// ============================================================

/// Create a [Result.success] for testing.
Result<T, AppFailure> successResult<T>(T value) => Result.success(value);

/// Create a [Result.failure] for testing.
Result<T, AppFailure> failureResult<T>(AppFailure failure) =>
    Result.failure(failure);

/// Create a [Future] that completes with a [Result.success].
Future<Result<T, AppFailure>> successFuture<T>(T value) =>
    Future.value(Result.success(value));

/// Create a [Future] that completes with a [Result.failure].
Future<Result<T, AppFailure>> failureFuture<T>(AppFailure failure) =>
    Future.value(Result.failure(failure));

/// Create a delayed [Future] that completes with a [Result.success].
Future<Result<T, AppFailure>> delayedSuccess<T>(
  T value, {
  Duration delay = const Duration(milliseconds: 100),
}) =>
    Future.delayed(delay, () => Result.success(value));

/// Create a delayed [Future] that completes with a [Result.failure].
Future<Result<T, AppFailure>> delayedFailure<T>(
  AppFailure failure, {
  Duration delay = const Duration(milliseconds: 100),
}) =>
    Future.delayed(delay, () => Result.failure(failure));
