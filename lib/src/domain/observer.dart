import 'dart:async';

import '../core/failure.dart';
import '../core/result.dart';

/// Observer for [StreamUseCase] callback-based listening.
///
/// [Observer] provides a callback-based interface for handling
/// stream emissions from a [StreamUseCase]. It's **optional** —
/// you can also use the stream directly with `.listen()` or `await for`.
///
/// ## When to Use Observer
/// - When you prefer callback-based patterns
/// - When integrating with legacy code that expects callbacks
/// - When you need named callbacks for clarity
///
/// ## When to Use Stream Directly
/// - When you want to use stream operators (map, where, etc.)
/// - When using async/await patterns
/// - When composing multiple streams
///
/// ## Example with Observer
/// ```dart
/// class ProductListObserver extends Observer<List<Product>> {
///   final void Function(List<Product>) onUpdate;
///   final void Function(AppFailure) onFailed;
///
///   ProductListObserver({
///     required this.onUpdate,
///     required this.onFailed,
///   });
///
///   @override
///   void onData(List<Product> data) => onUpdate(data);
///
///   @override
///   void onError(AppFailure failure) => onFailed(failure);
///
///   @override
///   void onDone() => print('Stream completed');
/// }
///
/// // Usage
/// final observer = ProductListObserver(
///   onUpdate: (products) => state.products = products,
///   onFailed: (failure) => state.error = failure,
/// );
///
/// watchProductsUseCase.observe('electronics', observer);
/// ```
///
/// ## Example with Stream (Preferred)
/// ```dart
/// watchProductsUseCase('electronics').listen((result) {
///   result.fold(
///     (products) => state.products = products,
///     (failure) => state.error = failure,
///   );
/// });
/// ```
abstract class Observer<T> {
  /// Called when a new value is emitted.
  void onData(T data);

  /// Called when an error occurs.
  ///
  /// Note: Unlike the old Observer which received dynamic errors,
  /// this receives typed [AppFailure] instances.
  void onError(AppFailure failure);

  /// Called when the stream completes.
  ///
  /// This is called after all values have been emitted,
  /// or after an error if the stream terminates on error.
  void onDone();
}

/// A simple [Observer] implementation using callbacks.
///
/// Use this when you don't want to create a custom Observer class.
///
/// Example:
/// ```dart
/// final observer = CallbackObserver<User>(
///   onDataCallback: (user) => print('Got user: ${user.name}'),
///   onErrorCallback: (failure) => print('Error: $failure'),
///   onDoneCallback: () => print('Done'),
/// );
/// ```
class CallbackObserver<T> extends Observer<T> {
  /// Callback for data events
  final void Function(T data) onDataCallback;

  /// Callback for error events
  final void Function(AppFailure failure)? onErrorCallback;

  /// Callback for done events
  final void Function()? onDoneCallback;

  /// Create a [CallbackObserver] with the given callbacks.
  ///
  /// [onDataCallback] is required.
  /// [onErrorCallback] and [onDoneCallback] are optional.
  CallbackObserver({
    required this.onDataCallback,
    this.onErrorCallback,
    this.onDoneCallback,
  });

  @override
  void onData(T data) => onDataCallback(data);

  @override
  void onError(AppFailure failure) => onErrorCallback?.call(failure);

  @override
  void onDone() => onDoneCallback?.call();
}

/// Extension to use [Observer] with [StreamUseCase].
///
/// Provides a convenient `observe` method for callback-based listening.
extension ObserverStreamExtension<T> on Stream<Result<T, AppFailure>> {
  /// Subscribe to this stream using an [Observer].
  ///
  /// Returns the [StreamSubscription] for cancellation.
  ///
  /// Example:
  /// ```dart
  /// final subscription = watchProductsUseCase('category')
  ///     .observe(myObserver);
  ///
  /// // Later, to cancel:
  /// subscription.cancel();
  /// ```
  StreamSubscription<Result<T, AppFailure>> observe(Observer<T> observer) {
    return listen(
      (result) {
        result.fold(
          observer.onData,
          observer.onError,
        );
      },
      onDone: observer.onDone,
    );
  }
}
