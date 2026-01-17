import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';

import '../entities/todo.dart';
import '../repositories/todo_repository.dart';

/// UseCase to get a single Todo by ID.
///
/// This demonstrates the standard single-shot [UseCase] pattern.
/// It returns a [Result<Todo, AppFailure>] - either the todo or a failure.
///
/// ## Example
/// ```dart
/// final result = await getTodoUseCase(1);
/// result.fold(
///   (todo) => print('Got: ${todo.title}'),
///   (failure) => print('Error: ${failure.message}'),
/// );
/// ```
class GetTodoUseCase extends UseCase<Todo, int> {
  final TodoRepository _repository;

  GetTodoUseCase(this._repository);

  @override
  Future<Todo> execute(int id, CancelToken? cancelToken) async {
    // Check for cancellation before making the request
    cancelToken?.throwIfCancelled();

    final todo = await _repository.getTodo(id);

    // Check for cancellation after the request
    cancelToken?.throwIfCancelled();

    return todo;
  }
}
