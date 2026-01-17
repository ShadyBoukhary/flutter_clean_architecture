import 'dart:async';

import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

import '../core/cancel_token.dart';
import '../core/failure.dart';
import '../core/result.dart';
import '../domain/usecase.dart';
import '../domain/stream_usecase.dart';

/// An optional orchestration layer for complex business flows.
///
/// [Presenter] is **optional** in the v7 architecture. For simple CRUD
/// operations, you can call UseCases directly from the Controller.
///
/// Use [Presenter] when you need:
/// - Complex multi-step business flows (e.g., checkout process)
/// - Coordination between multiple UseCases
/// - Shared business logic across multiple Controllers
/// - Caching or memoization at the orchestration level
///
/// ## When to Use Presenter
/// ```dart
/// // Complex checkout flow with multiple steps
/// class CheckoutPresenter extends Presenter {
///   Future<Result<Order, AppFailure>> checkout(Cart cart) async {
///     // Step 1: Validate cart
///     final validation = await execute(validateCartUseCase, cart);
///     if (validation.isFailure) return validation.mapFailure((f) => f);
///
///     // Step 2: Process payment
///     final payment = await execute(processPaymentUseCase, cart.total);
///     if (payment.isFailure) return payment.mapFailure((f) => f);
///
///     // Step 3: Create order
///     return execute(createOrderUseCase, CreateOrderParams(
///       cart: cart,
///       paymentId: payment.getOrThrow().id,
///     ));
///   }
/// }
/// ```
///
/// ## When NOT to Use Presenter
/// ```dart
/// // Simple CRUD - just call UseCase from Controller
/// class ProductController extends Controller {
///   Future<void> loadProduct(String id) async {
///     final result = await getProductUseCase(id);
///     result.fold(
///       (product) => _state = _state.copyWith(product: product),
///       (failure) => _state = _state.copyWith(error: failure),
///     );
///     refreshUI();
///   }
/// }
/// ```
abstract class Presenter {
  late final Logger _logger = Logger(runtimeType.toString());

  final List<dynamic> _useCases = [];
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  final List<CancelToken> _activeTokens = [];

  bool _isDisposed = false;

  /// Logger instance for this presenter
  Logger get logger => _logger;

  /// Whether this presenter has been disposed
  bool get isDisposed => _isDisposed;

  // ============================================================
  // UseCase Registration
  // ============================================================

  /// Register a [UseCase] for automatic disposal tracking.
  ///
  /// Returns the same UseCase for convenient inline use.
  ///
  /// Example:
  /// ```dart
  /// late final GetUserUseCase _getUser;
  ///
  /// MyPresenter(UserRepository repo) {
  ///   _getUser = registerUseCase(GetUserUseCase(repo));
  /// }
  /// ```
  @protected
  T registerUseCase<T>(T useCase) {
    _checkNotDisposed();
    _useCases.add(useCase);
    return useCase;
  }

  /// Register a [StreamSubscription] for automatic cancellation.
  @protected
  void registerSubscription(StreamSubscription<dynamic> subscription) {
    _checkNotDisposed();
    _subscriptions.add(subscription);
  }

  // ============================================================
  // Execution Helpers
  // ============================================================

  /// Create a [CancelToken] that will be cancelled on dispose.
  @protected
  CancelToken createCancelToken() {
    _checkNotDisposed();

    final token = CancelToken();
    _activeTokens.add(token);
    return token;
  }

  /// Execute a [UseCase] with automatic cancellation support.
  ///
  /// Example:
  /// ```dart
  /// Future<Result<User, AppFailure>> getUser(String id) async {
  ///   return execute(getUserUseCase, id);
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

  /// Execute a [StreamUseCase] and return the stream.
  ///
  /// Example:
  /// ```dart
  /// Stream<Result<List<Product>, AppFailure>> watchProducts(String category) {
  ///   return executeStream(watchProductsUseCase, category);
  /// }
  /// ```
  @protected
  Stream<Result<T, AppFailure>> executeStream<T, P>(
    StreamUseCase<T, P> useCase,
    P params, {
    CancelToken? cancelToken,
  }) {
    _checkNotDisposed();

    final token = cancelToken ?? createCancelToken();
    return useCase(params, cancelToken: token);
  }

  /// Execute multiple UseCases in parallel.
  ///
  /// Returns a list of results in the same order as the inputs.
  @protected
  Future<List<Result<dynamic, AppFailure>>> executeAll(
    List<Future<Result<dynamic, AppFailure>>> futures,
  ) async {
    _checkNotDisposed();
    return Future.wait(futures);
  }

  /// Execute UseCases sequentially, stopping on first failure.
  ///
  /// Returns the first failure encountered, or the last success.
  @protected
  Future<Result<T, AppFailure>> executeSequential<T>(
    List<Future<Result<T, AppFailure>> Function()> operations,
  ) async {
    _checkNotDisposed();

    Result<T, AppFailure>? lastResult;

    for (final operation in operations) {
      lastResult = await operation();
      if (lastResult.isFailure) {
        return lastResult;
      }
    }

    return lastResult!;
  }

  // ============================================================
  // Disposal
  // ============================================================

  /// Dispose of all registered UseCases and subscriptions.
  ///
  /// Always call this when the Presenter is no longer needed,
  /// typically from the Controller's `onDisposed` method.
  @mustCallSuper
  void dispose() {
    if (_isDisposed) return;

    _isDisposed = true;

    // Cancel all active tokens
    for (final token in _activeTokens) {
      token.cancel('Presenter disposed');
    }
    _activeTokens.clear();

    // Cancel all subscriptions
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();

    // Dispose StreamUseCases
    for (final useCase in _useCases) {
      if (useCase is StreamUseCase) {
        useCase.dispose();
      }
    }
    _useCases.clear();

    _logger.info('$runtimeType disposed');
  }

  void _checkNotDisposed() {
    if (_isDisposed) {
      throw StateError(
        'Cannot use $runtimeType after dispose. '
        'Did you store a reference to the presenter outside its lifecycle?',
      );
    }
  }
}
