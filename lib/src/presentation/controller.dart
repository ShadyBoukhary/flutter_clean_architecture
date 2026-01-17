import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

import '../core/cancel_token.dart';
import '../core/failure.dart';
import '../core/result.dart';
import '../domain/usecase.dart';

/// A Clean Architecture Controller.
///
/// The [Controller] handles UI events, manages state, and coordinates
/// with UseCases to perform business operations. It extends [ChangeNotifier]
/// for integration with Provider.
///
/// ## Key Features
/// - Automatic cancellation of pending operations on dispose
/// - Safe context and state access (no runtime assertions)
/// - Lifecycle callbacks for Flutter widget lifecycle
/// - Route awareness via [RouteAware]
/// - Built-in logging
///
/// ## Example
/// ```dart
/// class ProductController extends Controller {
///   final GetProductUseCase _getProduct;
///   final GetAllProductsUseCase _getAllProducts;
///
///   ProductState _state = const ProductState();
///   ProductState get state => _state;
///
///   ProductController({
///     required ProductRepository repository,
///   }) : _getProduct = GetProductUseCase(repository),
///        _getAllProducts = GetAllProductsUseCase(repository);
///
///   Future<void> loadProduct(String id) async {
///     _setState(_state.copyWith(isLoading: true, clearError: true));
///
///     final result = await execute(_getProduct, id);
///
///     result.fold(
///       (product) => _setState(_state.copyWith(
///         product: product,
///         isLoading: false,
///       )),
///       (failure) => _setState(_state.copyWith(
///         error: failure,
///         isLoading: false,
///       )),
///     );
///   }
///
///   void _setState(ProductState newState) {
///     _state = newState;
///     refreshUI();
///   }
/// }
/// ```
abstract class Controller
    with WidgetsBindingObserver, RouteAware, ChangeNotifier {
  late final Logger _logger;
  late GlobalKey<State<StatefulWidget>> _globalKey;

  bool _isMounted = true;
  bool _isDisposed = false;

  final List<CancelToken> _activeTokens = [];
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  /// Create a new Controller.
  Controller() {
    _logger = Logger(runtimeType.toString());
    initListeners();
  }

  /// Logger instance for this controller
  Logger get logger => _logger;

  /// Whether this controller is still mounted and active
  bool get isMounted => _isMounted;

  /// Whether this controller has been disposed
  bool get isDisposed => _isDisposed;

  // ============================================================
  // Context and State Access
  // ============================================================

  /// Get the [BuildContext] associated with this controller.
  ///
  /// Returns null if the context is not available (before mount or after dispose).
  /// Use [hasContext] to check availability before accessing.
  BuildContext? get context => _globalKey.currentContext;

  /// Get the [State] associated with this controller.
  ///
  /// Returns null if the state is not available.
  State<StatefulWidget>? get state => _globalKey.currentState;

  /// Check if a valid context is available.
  bool get hasContext => _globalKey.currentContext != null;

  /// Check if a valid state is available.
  bool get hasState => _globalKey.currentState != null;

  /// Get the [GlobalKey] associated with this controller.
  ///
  /// Use this key in your view's build method on the root widget
  /// (usually Scaffold) to enable context and state access.
  @protected
  GlobalKey<State<StatefulWidget>> get globalKey => _globalKey;

  // ============================================================
  // UseCase Execution
  // ============================================================

  /// Create a [CancelToken] that will be automatically cancelled on dispose.
  ///
  /// Use this when you need manual control over cancellation.
  @protected
  CancelToken createCancelToken() {
    _checkNotDisposed();

    final token = CancelToken();
    _activeTokens.add(token);
    return token;
  }

  /// Execute a [UseCase] with automatic cancellation support.
  ///
  /// The operation will be cancelled if the controller is disposed
  /// before it completes.
  ///
  /// Example:
  /// ```dart
  /// Future<void> loadUser(String id) async {
  ///   final result = await execute(getUserUseCase, id);
  ///   result.fold(
  ///     (user) => _state = _state.copyWith(user: user),
  ///     (failure) => _state = _state.copyWith(error: failure),
  ///   );
  ///   refreshUI();
  /// }
  /// ```
  @protected
  Future<Result<T, AppFailure>> execute<T, P>(
    UseCase<T, P> useCase,
    P params, {
    CancelToken? cancelToken,
  }) async {
    _checkNotDisposed();

    final token = cancelToken ?? createCancelToken();
    return useCase(params, cancelToken: token);
  }

  /// Execute multiple operations in parallel.
  ///
  /// Returns a list of results in the same order as the futures.
  @protected
  Future<List<Result<dynamic, AppFailure>>> executeAll(
    List<Future<Result<dynamic, AppFailure>>> futures,
  ) async {
    _checkNotDisposed();
    return Future.wait(futures);
  }

  /// Register a [StreamSubscription] for automatic cancellation on dispose.
  @protected
  void registerSubscription(StreamSubscription<dynamic> subscription) {
    _checkNotDisposed();
    _subscriptions.add(subscription);
  }

  // ============================================================
  // UI Updates
  // ============================================================

  /// Refresh the UI by notifying listeners.
  ///
  /// This is safe to call even if the controller is not mounted —
  /// it will simply be a no-op.
  @protected
  void refreshUI() {
    if (_isMounted && !_isDisposed) {
      notifyListeners();
    }
  }

  /// Schedule a callback to run after the current frame.
  ///
  /// Useful for operations that need to happen after the widget tree
  /// has been built, such as showing dialogs or navigating.
  @protected
  void schedulePostFrame(VoidCallback callback) {
    if (_isMounted && !_isDisposed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_isMounted && !_isDisposed) {
          callback();
        }
      });
    }
  }

  // ============================================================
  // Initialization
  // ============================================================

  /// Initialize the controller with the global key from the view.
  ///
  /// This is called automatically by [CleanViewState]. Do not call manually.
  @internal
  void initController(GlobalKey<State<StatefulWidget>> key) {
    _globalKey = key;
  }

  /// Override this to set up any initial listeners or state.
  ///
  /// This is called during controller construction.
  /// Unlike the old API, you typically don't need to use this for
  /// UseCase callbacks since we now use Result directly.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// void initListeners() {
  ///   // Set up any stream listeners, etc.
  /// }
  /// ```
  @protected
  void initListeners() {}

  // ============================================================
  // Lifecycle Callbacks
  // ============================================================

  /// Called when the view's initState is called.
  ///
  /// Use this to perform one-time initialization that requires
  /// the controller to be fully set up.
  void onInitState() {}

  /// Called when the view's didChangeDependencies is called.
  ///
  /// Use this to react to changes in inherited widgets.
  void onDidChangeDependencies() {}

  /// Called when the view is deactivated (about to be removed from tree).
  ///
  /// The view may still be reinserted into the tree at this point.
  void onDeactivated() {}

  /// Called when the view is reassembled (during hot reload).
  void onReassembled() {}

  /// Called when the view is about to be disposed.
  ///
  /// Override this to perform cleanup that requires context access.
  /// The context is still available at this point.
  ///
  /// **Important**: Always call `super.onDisposed()` at the end.
  @mustCallSuper
  void onDisposed() {
    dispose();
  }

  // ============================================================
  // App Lifecycle Callbacks
  // ============================================================

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isMounted) return;

    switch (state) {
      case AppLifecycleState.inactive:
        onInActive();
        break;
      case AppLifecycleState.paused:
        onPaused();
        break;
      case AppLifecycleState.resumed:
        onResumed();
        break;
      case AppLifecycleState.detached:
        onDetached();
        break;
      case AppLifecycleState.hidden:
        onHidden();
        break;
    }
  }

  /// Called when the app is inactive (not receiving user input).
  ///
  /// On iOS: App is in foreground but not receiving events (e.g., phone call).
  /// On Android: Another activity is focused (e.g., split-screen).
  @protected
  void onInActive() {}

  /// Called when the app is paused (in background).
  @protected
  void onPaused() {}

  /// Called when the app is resumed (in foreground and active).
  @protected
  void onResumed() {}

  /// Called when the app is about to be detached.
  @protected
  void onDetached() {}

  /// Called when the app is hidden.
  ///
  /// On mobile: App is being replaced by another app.
  /// On desktop: App is minimized.
  /// On web: Tab/window is hidden.
  @protected
  void onHidden() {}

  // ============================================================
  // Disposal
  // ============================================================

  @override
  @mustCallSuper
  void dispose() {
    if (_isDisposed) return;

    _isDisposed = true;
    _isMounted = false;

    // Cancel all active tokens
    for (final token in _activeTokens) {
      token.cancel('Controller disposed');
    }
    _activeTokens.clear();

    // Cancel all subscriptions
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();

    _logger.info('$runtimeType disposed');

    super.dispose();
  }

  void _checkNotDisposed() {
    if (_isDisposed) {
      throw StateError(
        'Cannot use $runtimeType after dispose. '
        'Did you store a reference to the controller outside its lifecycle?',
      );
    }
  }
}
