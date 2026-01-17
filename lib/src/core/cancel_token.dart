import 'dart:async';

/// A token for cooperative cancellation of asynchronous operations.
///
/// Use [CancelToken] to cancel long-running operations such as network
/// requests, file operations, or computations. The operation must
/// periodically check [isCancelled] or call [throwIfCancelled] to
/// respect cancellation.
///
/// Example:
/// ```dart
/// class DownloadFileUseCase extends UseCase<File, DownloadParams> {
///   @override
///   Future<File> execute(DownloadParams params, CancelToken? cancelToken) async {
///     final chunks = <Uint8List>[];
///
///     await for (final chunk in httpClient.downloadStream(params.url)) {
///       // Check for cancellation between chunks
///       cancelToken?.throwIfCancelled();
///       chunks.add(chunk);
///     }
///
///     return File.fromChunks(chunks);
///   }
/// }
///
/// // Usage
/// final cancelToken = CancelToken();
/// final future = downloadFileUseCase(params, cancelToken: cancelToken);
///
/// // Later, to cancel:
/// cancelToken.cancel();
/// ```
class CancelToken {
  bool _isCancelled = false;
  final _controller = StreamController<void>.broadcast();
  String? _cancelReason;
  final List<CancelToken> _children = [];
  CancelToken? _parent;

  /// Whether this token has been cancelled
  bool get isCancelled => _isCancelled || (_parent?.isCancelled ?? false);

  /// The reason for cancellation, if one was provided
  String? get cancelReason => _cancelReason ?? _parent?.cancelReason;

  /// A stream that emits when this token is cancelled
  ///
  /// Useful for listening to cancellation in streams or other async contexts.
  Stream<void> get onCancel => _controller.stream;

  /// Cancel this token and all linked child tokens
  ///
  /// Optionally provide a [reason] for cancellation.
  void cancel([String? reason]) {
    if (_isCancelled) return;

    _isCancelled = true;
    _cancelReason = reason;

    // Notify listeners
    if (!_controller.isClosed) {
      _controller.add(null);
      _controller.close();
    }

    // Cancel all children
    for (final child in _children) {
      child.cancel(reason);
    }
    _children.clear();
  }

  /// Throws a [CancelledException] if this token has been cancelled
  ///
  /// Use this at cancellation points in your async code.
  void throwIfCancelled() {
    if (isCancelled) {
      throw CancelledException(cancelReason ?? 'Operation was cancelled');
    }
  }

  /// Link this token to a parent token
  ///
  /// When the parent is cancelled, this token will also be cancelled.
  void linkTo(CancelToken parent) {
    if (_parent != null) {
      throw StateError('CancelToken is already linked to a parent');
    }

    _parent = parent;
    parent._children.add(this);

    // If parent is already cancelled, cancel this immediately
    if (parent.isCancelled) {
      cancel(parent.cancelReason);
    }
  }

  /// Create a child token linked to this token
  ///
  /// The child will be cancelled when this token is cancelled.
  CancelToken createChild() {
    final child = CancelToken();
    child.linkTo(this);
    return child;
  }

  /// Dispose of resources
  ///
  /// Note: This does not cancel the token, just cleans up the stream.
  void dispose() {
    if (!_controller.isClosed) {
      _controller.close();
    }
    _children.clear();
  }

  /// Create a token that automatically cancels after a timeout
  static CancelToken timeout(Duration duration) {
    final token = CancelToken();
    Timer(duration, () {
      if (!token.isCancelled) {
        token.cancel('Timeout after ${duration.inMilliseconds}ms');
      }
    });
    return token;
  }

  /// Create a token from a Future
  ///
  /// The token will be cancelled when the future completes.
  static CancelToken fromFuture(Future<void> future, [String? reason]) {
    final token = CancelToken();
    future.then((_) {
      if (!token.isCancelled) {
        token.cancel(reason);
      }
    });
    return token;
  }
}

/// Exception thrown when an operation is cancelled
///
/// Catch this exception to handle cancellation gracefully.
class CancelledException implements Exception {
  /// The reason for cancellation
  final String message;

  const CancelledException([this.message = 'Operation was cancelled']);

  @override
  String toString() => 'CancelledException: $message';
}

/// Extension methods for using [CancelToken] with [Future]
extension CancelTokenFutureExtension<T> on Future<T> {
  /// Wraps this future to respect a [CancelToken]
  ///
  /// If the token is cancelled before the future completes,
  /// the returned future will complete with a [CancelledException].
  ///
  /// Note: This does not actually cancel the underlying operation,
  /// it just makes the future complete early with an error.
  Future<T> withCancellation(CancelToken? token) {
    if (token == null) return this;

    final completer = Completer<T>();

    // Listen for cancellation
    late StreamSubscription<void> subscription;
    subscription = token.onCancel.listen((_) {
      if (!completer.isCompleted) {
        completer.completeError(
          CancelledException(token.cancelReason ?? 'Operation was cancelled'),
        );
      }
    });

    // Wait for the original future
    then((value) {
      subscription.cancel();
      if (!completer.isCompleted) {
        completer.complete(value);
      }
    }).catchError((Object error, StackTrace stackTrace) {
      subscription.cancel();
      if (!completer.isCompleted) {
        completer.completeError(error, stackTrace);
      }
    });

    // Check if already cancelled
    if (token.isCancelled && !completer.isCompleted) {
      subscription.cancel();
      completer.completeError(
        CancelledException(token.cancelReason ?? 'Operation was cancelled'),
      );
    }

    return completer.future;
  }
}

/// Extension methods for using [CancelToken] with [Stream]
extension CancelTokenStreamExtension<T> on Stream<T> {
  /// Wraps this stream to respect a [CancelToken]
  ///
  /// When the token is cancelled, the stream will close with an error.
  Stream<T> withCancellation(CancelToken? token) {
    if (token == null) return this;

    final controller = StreamController<T>();

    late StreamSubscription<T> subscription;

    void handleCancel() {
      subscription.cancel();
      if (!controller.isClosed) {
        controller.addError(
          CancelledException(token.cancelReason ?? 'Operation was cancelled'),
        );
        controller.close();
      }
    }

    // Listen for cancellation
    late StreamSubscription<void> cancelSubscription;
    cancelSubscription = token.onCancel.listen((_) => handleCancel());

    // Forward stream events
    subscription = listen(
      (data) {
        if (!token.isCancelled && !controller.isClosed) {
          controller.add(data);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!controller.isClosed) {
          controller.addError(error, stackTrace);
        }
      },
      onDone: () {
        cancelSubscription.cancel();
        if (!controller.isClosed) {
          controller.close();
        }
      },
      cancelOnError: false,
    );

    // Handle controller cancel
    controller.onCancel = () {
      cancelSubscription.cancel();
      subscription.cancel();
    };

    // Check if already cancelled
    if (token.isCancelled) {
      handleCancel();
    }

    return controller.stream;
  }
}
