import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';

import '../repositories/todo_repository.dart';

/// UseCase to delete a Todo by ID.
///
/// This demonstrates a [CompletableUseCase] that doesn't return a value.
/// It's used for fire-and-forget operations like delete, logout, etc.
///
/// ## Example
/// ```dart
/// final result = await deleteTodoUseCase(1);
/// result.fold(
///   (_) => print('Todo deleted successfully'),
///   (failure) => print('Error: ${failure.message}'),
/// );
/// ```
class DeleteTodoUseCase extends CompletableUseCase<int> {
  final TodoRepository _repository;

  DeleteTodoUseCase(this._repository);

  @override
  Future<void> execute(int id, CancelToken? cancelToken) async {
    // Check for cancellation before making the request
    cancelToken?.throwIfCancelled();

    await _repository.deleteTodo(id);

    // Log the deletion
    logger.info('Deleted todo with id: $id');
  }
}
