import 'dart:async';

import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';

import '../../domain/domain.dart';
import 'todo_state.dart';

/// Controller for the Todo page.
///
/// This controller demonstrates:
/// - Single-shot [UseCase] execution (create, toggle, delete)
/// - [StreamUseCase] for real-time updates (watch todos)
/// - [BackgroundUseCase] for CPU-intensive work (calculate primes)
/// - Proper cancellation with [CancelToken]
/// - Immutable state management with [TodoState]
class TodoController extends Controller {
  // Use cases
  final CreateTodoUseCase _createTodo;
  final ToggleTodoUseCase _toggleTodo;
  final DeleteTodoUseCase _deleteTodo;
  final WatchTodosUseCase _watchTodos;
  final CalculatePrimesUseCase _calculatePrimes;

  // View State (named viewState to avoid conflict with Controller.state)
  TodoState _viewState = const TodoState();
  TodoState get viewState => _viewState;

  // Stream subscription for watching todos
  StreamSubscription<Result<List<Todo>, AppFailure>>? _todosSubscription;

  // Cancel token for the current prime calculation
  CancelToken? _primeCalculationToken;

  /// Create a TodoController with the given repository.
  ///
  /// The controller creates its own use case instances.
  /// In a real app, you might inject these via a DI container.
  TodoController({
    required TodoRepository repository,
  })  : _createTodo = CreateTodoUseCase(repository),
        _toggleTodo = ToggleTodoUseCase(repository),
        _deleteTodo = DeleteTodoUseCase(repository),
        _watchTodos = WatchTodosUseCase(repository),
        _calculatePrimes = CalculatePrimesUseCase();

  @override
  void onInitState() {
    super.onInitState();
    // Start watching todos when the page loads
    _startWatchingTodos();
  }

  // ============================================================
  // State Management
  // ============================================================

  void _setState(TodoState newState) {
    _viewState = newState;
    refreshUI();
  }

  /// Clear the current error
  void clearError() {
    _setState(_viewState.copyWith(clearError: true));
  }

  // ============================================================
  // Todo Operations (Single-shot UseCases)
  // ============================================================

  /// Create a new todo with the given title.
  Future<void> createTodo(String title) async {
    if (title.trim().isEmpty) {
      _setState(_viewState.copyWith(
        error: const ValidationFailure('Please enter a todo title'),
      ));
      return;
    }

    _setState(_viewState.copyWith(isCreating: true, clearError: true));

    final result = await execute(_createTodo, title);

    result.fold(
      (todo) {
        logger.info('Created todo: ${todo.title}');
        _setState(_viewState.copyWith(isCreating: false));
      },
      (failure) {
        logger.warning('Failed to create todo: $failure');
        _setState(_viewState.copyWith(isCreating: false, error: failure));
      },
    );
  }

  /// Toggle the completion status of a todo.
  Future<void> toggleTodo(int id) async {
    final result = await execute(_toggleTodo, id);

    result.fold(
      (todo) {
        logger.info('Toggled todo ${todo.id}: ${todo.isCompleted}');
        // The stream will update the UI automatically
      },
      (failure) {
        logger.warning('Failed to toggle todo: $failure');
        _setState(_viewState.copyWith(error: failure));
      },
    );
  }

  /// Delete a todo by ID.
  Future<void> deleteTodo(int id) async {
    final result = await execute(_deleteTodo, id);

    result.fold(
      (_) {
        logger.info('Deleted todo: $id');
        // The stream will update the UI automatically
      },
      (failure) {
        logger.warning('Failed to delete todo: $failure');
        _setState(_viewState.copyWith(error: failure));
      },
    );
  }

  // ============================================================
  // Watch Todos (StreamUseCase)
  // ============================================================

  /// Start watching todos for real-time updates.
  void _startWatchingTodos() {
    _setState(_viewState.copyWith(isLoading: true));

    // Create a cancel token for the subscription
    final cancelToken = createCancelToken();

    _todosSubscription = _watchTodos(
      const NoParams(),
      cancelToken: cancelToken,
    ).listen(
      (result) {
        result.fold(
          (todos) {
            logger.fine('Received ${todos.length} todos');
            _setState(_viewState.copyWith(
              todos: todos,
              isLoading: false,
              clearError: true,
            ));
          },
          (failure) {
            logger.warning('Watch todos failed: $failure');
            _setState(_viewState.copyWith(
              isLoading: false,
              error: failure,
            ));
          },
        );
      },
      onDone: () {
        logger.info('Todos stream completed');
      },
    );

    // Register the subscription for automatic cleanup
    registerSubscription(_todosSubscription!);
  }

  // ============================================================
  // Calculate Primes (BackgroundUseCase)
  // ============================================================

  /// Calculate the nth prime number on a background isolate.
  ///
  /// This demonstrates running CPU-intensive work without blocking the UI.
  Future<void> calculatePrime(int n) async {
    // Cancel any existing calculation
    cancelPrimeCalculation();

    _setState(_viewState.copyWith(
      isCalculatingPrime: true,
      clearPrimeResult: true,
      progressMessage: 'Calculating the ${_ordinal(n)} prime...',
    ));

    // Create a new cancel token for this calculation
    _primeCalculationToken = createCancelToken();

    final subscription = _calculatePrimes(
      PrimeParams(n),
      cancelToken: _primeCalculationToken,
    ).listen(
      (result) {
        result.fold(
          (primeResult) {
            logger.info('Prime calculation complete: $primeResult');
            _setState(_viewState.copyWith(
              primeResult: primeResult,
              isCalculatingPrime: false,
              clearProgressMessage: true,
            ));
          },
          (failure) {
            logger.warning('Prime calculation failed: $failure');

            // Don't show error for cancellation
            if (failure is CancellationFailure) {
              _setState(_viewState.copyWith(
                isCalculatingPrime: false,
                clearProgressMessage: true,
              ));
            } else {
              _setState(_viewState.copyWith(
                isCalculatingPrime: false,
                clearProgressMessage: true,
                error: failure,
              ));
            }
          },
        );
      },
    );

    // Register for cleanup
    registerSubscription(subscription);
  }

  /// Cancel the current prime calculation if one is running.
  void cancelPrimeCalculation() {
    if (_primeCalculationToken != null &&
        !_primeCalculationToken!.isCancelled) {
      _primeCalculationToken!.cancel('User cancelled calculation');
      _primeCalculationToken = null;
      _setState(_viewState.copyWith(
        isCalculatingPrime: false,
        clearProgressMessage: true,
      ));
    }
  }

  /// Clear the prime result
  void clearPrimeResult() {
    _setState(_viewState.copyWith(clearPrimeResult: true));
  }

  // ============================================================
  // Helpers
  // ============================================================

  /// Convert a number to its ordinal form (1st, 2nd, 3rd, etc.)
  String _ordinal(int n) {
    if (n >= 11 && n <= 13) {
      return '${n}th';
    }
    switch (n % 10) {
      case 1:
        return '${n}st';
      case 2:
        return '${n}nd';
      case 3:
        return '${n}rd';
      default:
        return '${n}th';
    }
  }

  @override
  void onDisposed() {
    // Cancel prime calculation
    cancelPrimeCalculation();

    // Dispose the background use case
    _calculatePrimes.dispose();

    // Dispose the stream use case
    _watchTodos.dispose();

    super.onDisposed();
  }
}
