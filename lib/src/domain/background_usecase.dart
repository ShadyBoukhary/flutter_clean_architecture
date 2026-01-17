import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import '../core/cancel_token.dart';
import '../core/failure.dart';
import '../core/result.dart';

/// State of a [BackgroundUseCase] execution.
enum BackgroundUseCaseState {
  /// The use case is not running
  idle,

  /// The isolate is being spawned
  loading,

  /// The isolate is running and processing
  calculating,
}

/// Function signature for the task executed in the isolate.
///
/// This must be a static or top-level function (not a closure or instance method).
typedef BackgroundTask<Params> = FutureOr<void> Function(
    BackgroundTaskContext<Params> context);

/// Context passed to the background task.
///
/// Contains the parameters and a [SendPort] for sending results back
/// to the main isolate.
class BackgroundTaskContext<Params> {
  /// The parameters passed to the use case
  final Params params;

  /// Port for sending messages back to the main isolate
  final SendPort sendPort;

  const BackgroundTaskContext(this.params, this.sendPort);

  /// Send a data value back to the main isolate
  void sendData<T>(T data) {
    sendPort.send(_BackgroundMessage.data(data));
  }

  /// Send an error back to the main isolate
  void sendError(Object error, [StackTrace? stackTrace]) {
    sendPort.send(_BackgroundMessage.error(error, stackTrace));
  }

  /// Signal that the task is complete
  void sendDone() {
    sendPort.send(_BackgroundMessage<dynamic>.done());
  }
}

/// Internal message type for isolate communication.
class _BackgroundMessage<T> {
  final T? data;
  final Object? error;
  final StackTrace? stackTrace;
  final bool isDone;

  const _BackgroundMessage._({
    this.data,
    this.error,
    this.stackTrace,
    this.isDone = false,
  });

  factory _BackgroundMessage.data(T data) => _BackgroundMessage._(data: data);

  factory _BackgroundMessage.error(Object error, [StackTrace? stackTrace]) =>
      _BackgroundMessage._(error: error, stackTrace: stackTrace);

  factory _BackgroundMessage.done() => const _BackgroundMessage._(isDone: true);
}

/// A UseCase that executes expensive operations on a separate isolate.
///
/// Use [BackgroundUseCase] for CPU-intensive operations that would
/// block the main UI thread, such as:
/// - Image processing
/// - Large data parsing
/// - Complex calculations
/// - Encryption/decryption
///
/// ## Key Features
/// - Runs on a separate isolate to avoid UI jank
/// - Streams results back via [Result<Type, AppFailure>]
/// - Proper resource cleanup
/// - Built-in cancellation support
///
/// ## Important Constraints
/// - The [buildTask] must return a static or top-level function
/// - Parameters must be serializable (primitives, Lists, Maps)
/// - Not supported on web (will throw assertion error)
///
/// ## Example
/// ```dart
/// class MatrixMultiplyUseCase extends BackgroundUseCase<Matrix, MatrixParams> {
///   @override
///   BackgroundTask<MatrixParams> buildTask() => _multiply;
///
///   // MUST be static or top-level
///   static void _multiply(BackgroundTaskContext<MatrixParams> context) {
///     final params = context.params;
///     final result = params.matrixA * params.matrixB;
///     context.sendData(result);
///     context.sendDone();
///   }
/// }
///
/// // Usage
/// matrixMultiplyUseCase(params).listen((result) {
///   result.fold(
///     (matrix) => print('Result: $matrix'),
///     (failure) => print('Error: ${failure.message}'),
///   );
/// });
/// ```
abstract class BackgroundUseCase<T, Params> {
  late final Logger _logger = Logger(runtimeType.toString());

  BackgroundUseCaseState _state = BackgroundUseCaseState.idle;
  Isolate? _isolate;
  ReceivePort? _receivePort;
  StreamController<Result<T, AppFailure>>? _controller;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  /// Logger instance for this BackgroundUseCase
  Logger get logger => _logger;

  /// Current execution state
  BackgroundUseCaseState get state => _state;

  /// Whether the use case is currently running
  bool get isRunning => _state != BackgroundUseCaseState.idle;

  /// Create a new BackgroundUseCase.
  ///
  /// Throws an assertion error on web platforms.
  BackgroundUseCase() {
    assert(
      !kIsWeb,
      'BackgroundUseCase is not supported on web. '
      'Use UseCase with compute() for simple cases, or consider web workers.',
    );
  }

  /// Execute the use case with the given [params].
  ///
  /// Returns a [Stream] of [Result] values. Each value is either:
  /// - [Success] containing the computed result
  /// - [Failure] containing an [AppFailure]
  ///
  /// The stream completes when:
  /// - The task calls [BackgroundTaskContext.sendDone]
  /// - An error occurs
  /// - The use case is disposed or cancelled
  Stream<Result<T, AppFailure>> call(
    Params params, {
    CancelToken? cancelToken,
  }) {
    // Check for cancellation before starting
    if (cancelToken?.isCancelled ?? false) {
      _logger.info('$runtimeType cancelled before starting');
      return Stream.value(Result.failure(
        CancellationFailure(
            cancelToken?.cancelReason ?? 'Operation was cancelled'),
      ));
    }

    // If already running, return the existing stream
    if (isRunning && _controller != null) {
      _logger.warning(
          '$runtimeType is already running, returning existing stream');
      return _controller!.stream;
    }

    // Create new stream controller
    _controller = StreamController<Result<T, AppFailure>>.broadcast(
      onCancel: () {
        // Only stop if no more listeners
        if (!(_controller?.hasListener ?? false)) {
          _stop();
        }
      },
    );

    // Listen for cancellation
    if (cancelToken != null) {
      final subscription = cancelToken.onCancel.listen((_) {
        _controller?.add(Result.failure(
          CancellationFailure(
              cancelToken.cancelReason ?? 'Operation was cancelled'),
        ));
        _stop();
      });
      _subscriptions.add(subscription);
    }

    // Start the isolate
    _startIsolate(params);

    return _controller!.stream;
  }

  /// Start the isolate with the given parameters.
  Future<void> _startIsolate(Params params) async {
    _state = BackgroundUseCaseState.loading;

    // Create receive port
    _receivePort = ReceivePort();

    // Listen for messages from the isolate
    final subscription = _receivePort!.listen(_handleMessage);
    _subscriptions.add(subscription);

    try {
      // Get the task function
      final task = buildTask();

      // Spawn the isolate
      _isolate = await Isolate.spawn<_IsolateEntry<Params>>(
        _isolateEntryPoint<Params>,
        _IsolateEntry<Params>(
          task: task,
          context:
              BackgroundTaskContext<Params>(params, _receivePort!.sendPort),
        ),
        errorsAreFatal: true,
        onError: _receivePort!.sendPort,
        onExit: _receivePort!.sendPort,
      );

      // Check if we were cancelled/disposed while spawning
      if (!isRunning) {
        _logger
            .info('$runtimeType was cancelled during spawn, killing isolate');
        _isolate?.kill(priority: Isolate.immediate);
        _isolate = null;
        return;
      }

      _state = BackgroundUseCaseState.calculating;
      _logger.fine('$runtimeType isolate spawned successfully');
    } catch (e, stackTrace) {
      _logger.severe('$runtimeType failed to spawn isolate', e, stackTrace);
      _controller?.add(Result.failure(AppFailure.from(e, stackTrace)));
      _stop();
    }
  }

  /// Handle messages received from the isolate.
  void _handleMessage(dynamic message) {
    // Handle isolate errors (sent as List [error, stackTrace])
    if (message is List && message.length == 2) {
      final error = message[0];
      final stackTraceString = message[1] as String?;
      final stackTrace = stackTraceString != null
          ? StackTrace.fromString(stackTraceString)
          : null;

      _logger.warning('$runtimeType isolate error', error, stackTrace);
      _controller?.add(Result.failure(AppFailure.from(error, stackTrace)));
      _stop();
      return;
    }

    // Handle null (isolate exit signal)
    if (message == null) {
      _logger.fine('$runtimeType isolate exited');
      _stop();
      return;
    }

    // Handle our message type
    if (message is _BackgroundMessage) {
      if (message.isDone) {
        _logger.fine('$runtimeType task completed');
        _stop();
        return;
      }

      if (message.error != null) {
        _logger.warning(
            '$runtimeType task error', message.error, message.stackTrace);
        _controller?.add(Result.failure(
          AppFailure.from(message.error!, message.stackTrace),
        ));
        _stop();
        return;
      }

      if (message.data != null) {
        // Verify type at runtime
        if (message.data is T) {
          _controller?.add(Result.success(message.data as T));
        } else {
          _logger.severe(
            '$runtimeType received data of wrong type: '
            'expected $Type, got ${message.data.runtimeType}',
          );
          _controller?.add(Result.failure(
            UnknownFailure(
                'Received data of unexpected type: ${message.data.runtimeType}'),
          ));
        }
      }
    }
  }

  /// Stop the isolate and clean up resources.
  void _stop() {
    if (_state == BackgroundUseCaseState.idle) return;

    _state = BackgroundUseCaseState.idle;

    // Kill the isolate
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;

    // Close the receive port
    _receivePort?.close();
    _receivePort = null;

    // Close the stream controller
    if (!(_controller?.isClosed ?? true)) {
      _controller?.close();
    }

    _logger.fine('$runtimeType stopped');
  }

  /// Override this method to provide the background task.
  ///
  /// **IMPORTANT**: This must return a static or top-level function,
  /// not a closure or instance method.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// BackgroundTask<MyParams> buildTask() => _processData;
  ///
  /// static void _processData(BackgroundTaskContext<MyParams> context) {
  ///   // Process data here
  ///   context.sendData(result);
  ///   context.sendDone();
  /// }
  /// ```
  @protected
  BackgroundTask<Params> buildTask();

  /// Dispose of all resources.
  ///
  /// Call this when the use case is no longer needed.
  void dispose() {
    _stop();

    // Cancel all subscriptions
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();

    _controller = null;

    _logger.info('$runtimeType disposed');
  }
}

/// Entry point wrapper for the isolate.
class _IsolateEntry<Params> {
  final BackgroundTask<Params> task;
  final BackgroundTaskContext<Params> context;

  const _IsolateEntry({
    required this.task,
    required this.context,
  });
}

/// Isolate entry point function.
///
/// This is the actual function that runs in the isolate.
void _isolateEntryPoint<Params>(_IsolateEntry<Params> entry) async {
  try {
    await entry.task(entry.context);
  } catch (e, stackTrace) {
    entry.context.sendError(e, stackTrace);
  }
}
