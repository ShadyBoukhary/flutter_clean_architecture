import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';

import '../entities/todo.dart';
import '../repositories/todo_repository.dart';

/// UseCase to create a new Todo.
///
/// This demonstrates a single-shot [UseCase] with a string parameter.
/// Returns the newly created [Todo] with its assigned ID.
///
/// ## Example
/// ```dart
/// final result = await createTodoUseCase('Buy groceries');
/// result.fold(
///   (todo) => print('Created: ${todo.title} with id ${todo.id}'),
///   (failure) => print('Error: ${failure.message}'),
/// );
/// ```
class CreateTodoUseCase extends UseCase<Todo, String> {
  final TodoRepository _repository;

  CreateTodoUseCase(this._repository);

  @override
  Future<Todo> execute(String title, CancelToken? cancelToken) async {
    // Validate input
    if (title.trim().isEmpty) {
      throw const ValidationFailure(
        'Todo title cannot be empty',
        fieldErrors: {
          'title': ['Title is required']
        },
      );
    }

    // Check for cancellation before making the request
    cancelToken?.throwIfCancelled();

    final todo = await _repository.createTodo(title.trim());

    return todo;
  }
}
