import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';

import '../../domain/entities/prime_result.dart';
import '../../domain/entities/todo.dart';

/// Immutable state for the Todo page.
///
/// This class holds all the state needed by the TodoController and TodoPage.
/// Using an immutable state class makes state management predictable and
/// enables easy debugging.
class TodoState {
  /// The list of todos
  final List<Todo> todos;

  /// Whether the todos are currently loading
  final bool isLoading;

  /// The current error, if any
  final AppFailure? error;

  /// Whether a todo is being created
  final bool isCreating;

  /// The result of the last prime calculation, if any
  final PrimeResult? primeResult;

  /// Whether a prime calculation is in progress
  final bool isCalculatingPrime;

  /// Progress message for long-running operations
  final String? progressMessage;

  const TodoState({
    this.todos = const [],
    this.isLoading = false,
    this.error,
    this.isCreating = false,
    this.primeResult,
    this.isCalculatingPrime = false,
    this.progressMessage,
  });

  /// Create a copy of this state with the given fields replaced.
  TodoState copyWith({
    List<Todo>? todos,
    bool? isLoading,
    AppFailure? error,
    bool clearError = false,
    bool? isCreating,
    PrimeResult? primeResult,
    bool clearPrimeResult = false,
    bool? isCalculatingPrime,
    String? progressMessage,
    bool clearProgressMessage = false,
  }) {
    return TodoState(
      todos: todos ?? this.todos,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isCreating: isCreating ?? this.isCreating,
      primeResult: clearPrimeResult ? null : (primeResult ?? this.primeResult),
      isCalculatingPrime: isCalculatingPrime ?? this.isCalculatingPrime,
      progressMessage: clearProgressMessage
          ? null
          : (progressMessage ?? this.progressMessage),
    );
  }

  /// Get the count of completed todos
  int get completedCount => todos.where((t) => t.isCompleted).length;

  /// Get the count of active (not completed) todos
  int get activeCount => todos.where((t) => !t.isCompleted).length;

  /// Whether there are any todos
  bool get hasTodos => todos.isNotEmpty;

  /// Whether there is an error to display
  bool get hasError => error != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TodoState &&
          runtimeType == other.runtimeType &&
          todos == other.todos &&
          isLoading == other.isLoading &&
          error == other.error &&
          isCreating == other.isCreating &&
          primeResult == other.primeResult &&
          isCalculatingPrime == other.isCalculatingPrime &&
          progressMessage == other.progressMessage);

  @override
  int get hashCode =>
      todos.hashCode ^
      isLoading.hashCode ^
      error.hashCode ^
      isCreating.hashCode ^
      primeResult.hashCode ^
      isCalculatingPrime.hashCode ^
      progressMessage.hashCode;

  @override
  String toString() =>
      'TodoState(todos: ${todos.length}, isLoading: $isLoading, error: $error)';
}
