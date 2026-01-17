import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';

import '../entities/todo.dart';
import '../repositories/todo_repository.dart';

/// UseCase to toggle the completion status of a Todo.
///
/// This demonstrates a single-shot [UseCase] that modifies existing data.
/// Returns the updated [Todo] with the toggled completion status.
///
/// ## Example
/// ```dart
/// final result = await toggleTodoUseCase(1);
/// result.fold(
///   (todo) => print('Todo ${todo.id} is now ${todo.isCompleted ? "completed" : "active"}'),
///   (failure) => print('Error: ${failure.message}'),
/// );
/// ```
class ToggleTodoUseCase extends UseCase<Todo, int> {
  final TodoRepository _repository;

  ToggleTodoUseCase(this._repository);

  @override
  Future<Todo> execute(int id, CancelToken? cancelToken) async {
    // Check for cancellation before making the request
    cancelToken?.throwIfCancelled();

    final updatedTodo = await _repository.toggleTodo(id);

    // Check for cancellation after the request
    cancelToken?.throwIfCancelled();

    return updatedTodo;
  }
}
