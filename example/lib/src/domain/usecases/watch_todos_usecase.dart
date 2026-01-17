import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';

import '../entities/todo.dart';
import '../repositories/todo_repository.dart';

/// UseCase to watch all Todos in real-time.
///
/// This demonstrates the [StreamUseCase] pattern for reactive operations.
/// It emits a new list of todos whenever the data changes.
///
/// ## Example
/// ```dart
/// // Using the stream directly
/// watchTodosUseCase(const NoParams()).listen((result) {
///   result.fold(
///     (todos) => print('Got ${todos.length} todos'),
///     (failure) => print('Error: ${failure.message}'),
///   );
/// });
///
/// // Using the listen helper with callbacks
/// final subscription = watchTodosUseCase.listen(
///   const NoParams(),
///   onData: (todos) => updateList(todos),
///   onError: (failure) => showError(failure),
///   onDone: () => print('Stream completed'),
/// );
///
/// // Cancel when done
/// subscription.cancel();
/// ```
class WatchTodosUseCase extends StreamUseCase<List<Todo>, NoParams> {
  final TodoRepository _repository;

  WatchTodosUseCase(this._repository);

  @override
  Stream<List<Todo>> execute(NoParams params, CancelToken? cancelToken) {
    // Return the stream from the repository
    // The base class handles cancellation and error wrapping
    return _repository.watchTodos();
  }
}
