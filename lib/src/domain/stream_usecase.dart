import 'dart:async';

import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

import '../core/cancel_token.dart';
import '../core/failure.dart';
import '../core/result.dart';

/// A UseCase for streaming/reactive operations.
///
/// Use [StreamUseCase] when you need to emit multiple values over time,
/// such as real-time updates, pagination, or long-running operations
/// with progress updates.
///
/// For single-shot operations, use [UseCase] instead.
///
/// ## Key Features
/// - Emits [Result<Type, AppFailure>] for each value
/// - Built-in cancellation support via [CancelToken]
/// - Automatic error wrapping and logging
/// - Clean stream-based API
///
/// ## Example
/// ```dart
/// class WatchProductsUseCase extends StreamUseCase<List<Product>, String> {
///   final ProductRepository _repository;
///
///   WatchProductsUseCase(this._repository);
///
///   @override
///   Stream<List<Product>> execute(String category, CancelToken? cancelToken) {
///     return _repository.watchProducts(category);
///   }
/// }
///
/// // Usage
/// watchProductsUseCase('electronics').listen((result) {
///   result.fold(
///     (products) => updateList(products),
///     (failure) => showError(failure),
///   );
/// });
/// ```
///
/// ## Error Handling
/// - Errors in the stream are wrapped in [AppFailure] and emitted as [Failure]
/// - [CancelledException] is converted to [CancellationFailure]
/// - The stream completes after emitting a failure
abstract class StreamUseCase<T, Params> {
  late final Logger _logger = Logger(runtimeType.toString());
  StreamSubscription<T>? _subscription;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  /// Logger instance for this StreamUseCase
  Logger get logger => _logger;

  /// Execute the use case with the given [params].
  ///
  /// Returns a [Stream] of [Result] values. Each value is either:
  /// - [Success] containing the emitted value
  /// - [Failure] containing an [AppFailure]
  Stream<Result<T, AppFailure>> call(
    Params params, {
    CancelToken? cancelToken,
  }) async* {
    // Check for cancellation before starting
    if (cancelToken?.isCancelled ?? false) {
      _logger.info('$runtimeType cancelled before starting');
      yield Result.failure(
        CancellationFailure(
            cancelToken?.cancelReason ?? 'Operation was cancelled'),
      );
      return;
    }

    try {
      final sourceStream = execute(params, cancelToken);

      // Apply cancellation if token is provided
      final stream = cancelToken != null
          ? sourceStream.withCancellation(cancelToken)
          : sourceStream;

      await for (final value in stream) {
        // Check for cancellation between values
        if (cancelToken?.isCancelled ?? false) {
          _logger.info('$runtimeType cancelled during execution');
          yield Result.failure(
            CancellationFailure(
                cancelToken?.cancelReason ?? 'Operation was cancelled'),
          );
          return;
        }

        yield Result.success(value);
      }

      _logger.fine('$runtimeType stream completed successfully');
    } on CancelledException catch (e) {
      _logger.info('$runtimeType was cancelled: ${e.message}');
      yield Result.failure(CancellationFailure(e.message));
    } on AppFailure catch (e) {
      _logger.warning('$runtimeType failed with AppFailure: $e');
      yield Result.failure(e);
    } catch (e, stackTrace) {
      _logger.severe('$runtimeType failed unexpectedly', e, stackTrace);
      yield Result.failure(AppFailure.from(e, stackTrace));
    }
  }

  /// Override this method to implement the streaming logic.
  ///
  /// - Throw [AppFailure] subclasses for expected/recoverable errors
  /// - Any other exception will be wrapped in [UnknownFailure]
  /// - Check [cancelToken?.isCancelled] for long gaps between emissions
  ///
  /// Each emitted value will be wrapped in [Success].
  @protected
  Stream<T> execute(Params params, CancelToken? cancelToken);

  /// Listen to the use case with callback-based API.
  ///
  /// This is a convenience method that wraps [call] with callbacks.
  /// Returns a [StreamSubscription] that can be cancelled.
  ///
  /// Example:
  /// ```dart
  /// final subscription = watchProductsUseCase.listen(
  ///   'electronics',
  ///   onData: (products) => updateList(products),
  ///   onError: (failure) => showError(failure),
  ///   onDone: () => print('Stream completed'),
  /// );
  ///
  /// // Later, to cancel:
  /// subscription.cancel();
  /// ```
  StreamSubscription<Result<T, AppFailure>> listen(
    Params params, {
    required void Function(T data) onData,
    void Function(AppFailure failure)? onError,
    void Function()? onDone,
    CancelToken? cancelToken,
  }) {
    final subscription = call(params, cancelToken: cancelToken).listen(
      (result) {
        result.fold(
          (value) => onData(value),
          (failure) => onError?.call(failure),
        );
      },
      onDone: onDone,
    );

    _subscriptions.add(subscription);
    return subscription;
  }

  /// Dispose of all active subscriptions.
  ///
  /// Call this when the use case is no longer needed.
  void dispose() {
    _subscription?.cancel();
    _subscription = null;

    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();

    _logger.info('$runtimeType disposed');
  }
}

/// Extension methods for convenient StreamUseCase operations
extension StreamUseCaseExtensions<T, Params> on StreamUseCase<T, Params> {
  /// Get the first result from the stream.
  ///
  /// Useful when you only care about the first emission.
  Future<Result<T, AppFailure>> first(
    Params params, {
    CancelToken? cancelToken,
  }) async {
    return call(params, cancelToken: cancelToken).first;
  }

  /// Collect all results into a list.
  ///
  /// Only includes successful results. Stops on first failure.
  Future<Result<List<T>, AppFailure>> toList(
    Params params, {
    CancelToken? cancelToken,
  }) async {
    final results = <T>[];

    await for (final result in call(params, cancelToken: cancelToken)) {
      final failure = result.getFailureOrNull();
      if (failure != null) {
        return Result.failure(failure);
      }

      final value = result.getOrNull();
      if (value != null) {
        results.add(value);
      }
    }

    return Result.success(results);
  }
}
