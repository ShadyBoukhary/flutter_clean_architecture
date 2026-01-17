import 'dart:async';

import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

import '../core/cancel_token.dart';
import '../core/failure.dart';
import '../core/result.dart';

/// Base UseCase class for Clean Architecture.
///
/// A UseCase represents a single business operation. It encapsulates
/// the application's business logic and returns a [Result] indicating
/// success or failure.
///
/// This is the **default** UseCase type for single-shot operations.
/// For streaming/reactive operations, use [StreamUseCase].
/// For operations that don't return a value, use [CompletableUseCase].
///
/// ## Key Features
/// - Returns [Result<Type, AppFailure>] for type-safe error handling
/// - Built-in cancellation support via [CancelToken]
/// - Automatic error wrapping and logging
/// - Callable syntax for clean API
///
/// ## Example
/// ```dart
/// class GetUserUseCase extends UseCase<User, String> {
///   final UserRepository _repository;
///
///   GetUserUseCase(this._repository);
///
///   @override
///   Future<User> execute(String userId, CancelToken? cancelToken) async {
///     return _repository.getUser(userId);
///   }
/// }
///
/// // Usage
/// final result = await getUserUseCase('user-123');
/// result.fold(
///   (user) => print('Got user: ${user.name}'),
///   (failure) => print('Error: ${failure.message}'),
/// );
/// ```
///
/// ## Error Handling
/// - Throw [AppFailure] subclasses for expected errors
/// - Any other exception is automatically wrapped in [UnknownFailure]
/// - [CancelledException] is converted to [CancellationFailure]
abstract class UseCase<T, Params> {
  late final Logger _logger = Logger(runtimeType.toString());

  /// Logger instance for this UseCase
  Logger get logger => _logger;

  /// Execute the use case with the given [params].
  ///
  /// Prefer using the call syntax: `await useCase(params)`
  /// instead of: `await useCase.call(params)`
  ///
  /// Returns a [Result] that is either:
  /// - [Success] containing the result value
  /// - [Failure] containing an [AppFailure]
  Future<Result<T, AppFailure>> call(
    Params params, {
    CancelToken? cancelToken,
  }) async {
    try {
      // Check for cancellation before starting
      cancelToken?.throwIfCancelled();

      final value = await execute(params, cancelToken);

      _logger.fine('$runtimeType completed successfully');
      return Result.success(value);
    } on CancelledException catch (e) {
      _logger.info('$runtimeType was cancelled: ${e.message}');
      return Result.failure(CancellationFailure(e.message));
    } on AppFailure catch (e) {
      _logger.warning('$runtimeType failed with AppFailure: $e');
      return Result.failure(e);
    } catch (e, stackTrace) {
      _logger.severe('$runtimeType failed unexpectedly', e, stackTrace);
      return Result.failure(AppFailure.from(e, stackTrace));
    }
  }

  /// Override this method to implement the use case logic.
  ///
  /// - Throw [AppFailure] subclasses for expected/recoverable errors
  /// - Any other exception will be wrapped in [UnknownFailure]
  /// - Periodically check [cancelToken?.throwIfCancelled()] for long operations
  ///
  /// The returned value will be wrapped in [Success].
  @protected
  Future<T> execute(Params params, CancelToken? cancelToken);
}

/// A UseCase that doesn't return a value.
///
/// Use this for operations like delete, logout, or fire-and-forget actions.
///
/// ## Example
/// ```dart
/// class LogoutUseCase extends CompletableUseCase<NoParams> {
///   final AuthRepository _repository;
///
///   LogoutUseCase(this._repository);
///
///   @override
///   Future<void> execute(NoParams params, CancelToken? cancelToken) async {
///     await _repository.logout();
///   }
/// }
///
/// // Usage
/// final result = await logoutUseCase(const NoParams());
/// result.fold(
///   (_) => print('Logged out successfully'),
///   (failure) => print('Logout failed: ${failure.message}'),
/// );
/// ```
abstract class CompletableUseCase<Params> extends UseCase<void, Params> {
  @override
  @protected
  Future<void> execute(Params params, CancelToken? cancelToken);
}
