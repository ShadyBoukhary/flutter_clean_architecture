/// Flutter Clean Architecture
///
/// A comprehensive Clean Architecture framework for Flutter applications
/// with Result-based error handling, dependency injection, and minimal boilerplate.
///
/// ## Overview
///
/// This package provides the building blocks for implementing Clean Architecture
/// in Flutter applications:
///
/// - **UseCase**: Single-shot business operations returning `Result<T, AppFailure>`
/// - **StreamUseCase**: Reactive operations that emit multiple values over time
/// - **BackgroundUseCase**: CPU-intensive operations that run on a separate isolate
/// - **Controller**: Manages UI state and coordinates with UseCases
/// - **Presenter**: Optional orchestration layer for complex business flows
/// - **Result**: Type-safe success/failure handling
/// - **AppFailure**: Sealed failure hierarchy for exhaustive error handling
///
/// ## Quick Start
///
/// ```dart
/// // 1. Create a UseCase
/// class GetUserUseCase extends UseCase<User, String> {
///   final UserRepository _repository;
///   GetUserUseCase(this._repository);
///
///   @override
///   Future<User> execute(String userId, CancelToken? cancelToken) async {
///     return _repository.getUser(userId);
///   }
/// }
///
/// // 2. Use it in a Controller
/// class UserController extends Controller {
///   final GetUserUseCase _getUser;
///
///   UserState _state = const UserState();
///   UserState get state => _state;
///
///   UserController(UserRepository repo) : _getUser = GetUserUseCase(repo);
///
///   Future<void> loadUser(String id) async {
///     _setState(_state.copyWith(isLoading: true));
///     (await _getUser(id)).fold(
///       (user) => _setState(_state.copyWith(user: user, isLoading: false)),
///       (failure) => _setState(_state.copyWith(error: failure, isLoading: false)),
///     );
///   }
///
///   void _setState(UserState newState) {
///     _state = newState;
///     refreshUI();
///   }
/// }
///
/// // 3. Create a View
/// class UserPage extends CleanView {
///   @override
///   State<UserPage> createState() => _UserPageState();
/// }
///
/// class _UserPageState extends CleanViewState<UserPage, UserController> {
///   _UserPageState() : super(UserController(getIt<UserRepository>()));
///
///   @override
///   Widget get view {
///     return Scaffold(
///       key: globalKey,
///       body: ControlledWidgetBuilder<UserController>(
///         builder: (context, controller) {
///           if (controller.state.isLoading) {
///             return const CircularProgressIndicator();
///           }
///           return Text(controller.state.user?.name ?? 'No user');
///         },
///       ),
///     );
///   }
/// }
/// ```
///
/// ## Error Handling
///
/// All operations return `Result<T, AppFailure>` for type-safe error handling:
///
/// ```dart
/// final result = await getUserUseCase('user-123');
///
/// // Pattern matching with fold
/// result.fold(
///   (user) => showUser(user),
///   (failure) => showError(failure),
/// );
///
/// // Or use switch expression
/// switch (failure) {
///   case NotFoundFailure():
///     showNotFound();
///   case NetworkFailure():
///     showOfflineMessage();
///   case UnauthorizedFailure():
///     navigateToLogin();
///   default:
///     showGenericError();
/// }
/// ```
library flutter_clean_architecture;

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import 'src/presentation/controller.dart';

// ============================================================
// Core - Error Handling & Utilities
// ============================================================

/// Result type for type-safe success/failure handling
export 'src/core/result.dart';

/// Failure types for error classification
export 'src/core/failure.dart';

/// Cancellation token for cooperative cancellation
export 'src/core/cancel_token.dart';

/// NoParams sentinel for parameterless UseCases
export 'src/core/no_params.dart';

// ============================================================
// Domain - Business Logic
// ============================================================

/// UseCase base class for single-shot operations
export 'src/domain/usecase.dart';

/// StreamUseCase for reactive/streaming operations
export 'src/domain/stream_usecase.dart';

/// BackgroundUseCase for isolate-based operations
export 'src/domain/background_usecase.dart';

/// Observer for callback-based stream listening (optional)
export 'src/domain/observer.dart';

// ============================================================
// Presentation - UI Layer
// ============================================================

/// Controller for state management
export 'src/presentation/controller.dart';

/// Presenter for complex orchestration (optional)
export 'src/presentation/presenter.dart';

/// CleanView and CleanViewState base classes
export 'src/presentation/view.dart';

/// ResponsiveViewState for responsive layouts
export 'src/presentation/responsive_view.dart';

/// ControlledWidgetBuilder and variants
export 'src/presentation/controlled_widget.dart';

// ============================================================
// Extensions
// ============================================================

/// Future extensions for Result conversion
export 'src/extensions/future_extensions.dart';

// ============================================================
// Utilities
// ============================================================

/// Test utilities (matchers, observers)
export 'src/utils/test_utils.dart';

// ============================================================
// Framework Configuration
// ============================================================

/// Global configuration and utilities for Flutter Clean Architecture.
class FlutterCleanArchitecture {
  FlutterCleanArchitecture._();

  /// Retrieve a [Controller] from the widget tree.
  ///
  /// Use this to access a Controller from widgets that are children
  /// of a [CleanViewState].
  ///
  /// Set [listen] to `false` if you don't need to rebuild when the
  /// Controller changes (e.g., for event handlers).
  ///
  /// ## Example
  /// ```dart
  /// // In a child widget
  /// final controller = FlutterCleanArchitecture.getController<MyController>(context);
  /// controller.doSomething();
  ///
  /// // Without listening (for callbacks)
  /// onPressed: () {
  ///   final controller = FlutterCleanArchitecture.getController<MyController>(
  ///     context,
  ///     listen: false,
  ///   );
  ///   controller.handleButtonPress();
  /// }
  /// ```
  static Con getController<Con extends Controller>(
    BuildContext context, {
    bool listen = true,
  }) {
    return Provider.of<Con>(context, listen: listen);
  }

  /// Enable debug logging for the framework.
  ///
  /// Call this in your `main()` function to see detailed logs from
  /// Controllers, UseCases, and other components.
  ///
  /// ## Example
  /// ```dart
  /// void main() {
  ///   FlutterCleanArchitecture.enableLogging();
  ///   runApp(MyApp());
  /// }
  /// ```
  static void enableLogging({
    Level level = Level.ALL,
    void Function(LogRecord record)? onRecord,
  }) {
    Logger.root.level = level;
    Logger.root.onRecord.listen(onRecord ?? _defaultLogHandler);
    Logger.root.info('Flutter Clean Architecture logging enabled');
  }

  /// Disable logging.
  static void disableLogging() {
    Logger.root.level = Level.OFF;
  }

  static void _defaultLogHandler(LogRecord record) {
    final emoji = _levelEmoji(record.level);
    final message = '$emoji ${record.loggerName}: ${record.message}';

    // ignore: avoid_print
    print(message);

    if (record.error != null) {
      // ignore: avoid_print
      print('  Error: ${record.error}');
    }

    if (record.stackTrace != null) {
      // ignore: avoid_print
      print('  Stack: ${record.stackTrace}');
    }
  }

  static String _levelEmoji(Level level) {
    if (level >= Level.SEVERE) return '🔴';
    if (level >= Level.WARNING) return '🟠';
    if (level >= Level.INFO) return '🔵';
    if (level >= Level.FINE) return '⚪';
    return '⚫';
  }
}
