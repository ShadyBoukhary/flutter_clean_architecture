# Flutter Clean Architecture v7 Example

This example demonstrates the new v7 API of the Flutter Clean Architecture package.

## Features Demonstrated

### 1. UseCase (Single-shot Operations)

The default `UseCase` class is for single-shot operations that return `Result<T, AppFailure>`:

```dart
class GetTodoUseCase extends UseCase<Todo, int> {
  final TodoRepository _repository;

  GetTodoUseCase(this._repository);

  @override
  Future<Todo> execute(int id, CancelToken? cancelToken) async {
    cancelToken?.throwIfCancelled();
    return _repository.getTodo(id);
  }
}

// Usage
final result = await getTodoUseCase(1);
result.fold(
  (todo) => print('Got: ${todo.title}'),
  (failure) => print('Error: ${failure.message}'),
);
```

### 2. StreamUseCase (Real-time Updates)

Use `StreamUseCase` for reactive operations that emit multiple values:

```dart
class WatchTodosUseCase extends StreamUseCase<List<Todo>, NoParams> {
  final TodoRepository _repository;

  WatchTodosUseCase(this._repository);

  @override
  Stream<List<Todo>> execute(NoParams params, CancelToken? cancelToken) {
    return _repository.watchTodos();
  }
}

// Usage
watchTodosUseCase(const NoParams()).listen((result) {
  result.fold(
    (todos) => updateList(todos),
    (failure) => showError(failure),
  );
});
```

### 3. BackgroundUseCase (CPU-intensive Operations)

Use `BackgroundUseCase` for operations that should run on a separate isolate:

```dart
class CalculatePrimesUseCase extends BackgroundUseCase<PrimeResult, PrimeParams> {
  @override
  BackgroundTask<PrimeParams> buildTask() => _calculatePrime;

  // MUST be static or top-level function!
  static void _calculatePrime(BackgroundTaskContext<PrimeParams> context) {
    final n = context.params.n;
    final prime = calculateNthPrime(n);
    context.sendData(PrimeResult(n, prime));
    context.sendDone();
  }
}
```

### 4. Controller and CleanView

The presentation layer uses `Controller` for state management and `CleanView` for the UI:

```dart
class TodoController extends Controller {
  TodoState _state = const TodoState();
  TodoState get state => _state;

  Future<void> createTodo(String title) async {
    _setState(_state.copyWith(isCreating: true));
    
    final result = await execute(_createTodo, title);
    
    result.fold(
      (todo) => _setState(_state.copyWith(isCreating: false)),
      (failure) => _setState(_state.copyWith(error: failure)),
    );
  }

  void _setState(TodoState newState) {
    _state = newState;
    refreshUI();
  }
}
```

### 5. ControlledWidgetBuilder (Fine-grained Rebuilds)

Use `ControlledWidgetBuilder` for widgets that need to rebuild when the controller changes:

```dart
ControlledWidgetBuilder<TodoController>(
  builder: (context, controller) {
    if (controller.state.isLoading) {
      return const CircularProgressIndicator();
    }
    return Text(controller.state.todos.length.toString());
  },
)
```

### 6. Result and AppFailure (Type-safe Error Handling)

All operations return `Result<T, AppFailure>` for type-safe error handling:

```dart
result.fold(
  (success) => handleSuccess(success),
  (failure) => handleFailure(failure),
);

// Pattern matching on failure types
switch (failure) {
  case ValidationFailure(:final message):
    showValidationError(message);
  case NetworkFailure():
    showOfflineMessage();
  case NotFoundFailure():
    showNotFound();
  default:
    showGenericError();
}
```

### 7. CancelToken (Cooperative Cancellation)

Use `CancelToken` to cancel long-running operations:

```dart
final cancelToken = createCancelToken();
final result = await execute(useCase, params, cancelToken: cancelToken);

// Later, to cancel:
cancelToken.cancel('User navigated away');
```

## Project Structure

```
lib/
├── main.dart                           # App entry point
└── src/
    ├── data/
    │   └── repositories/
    │       └── in_memory_todo_repository.dart  # Repository implementation
    ├── domain/
    │   ├── entities/
    │   │   ├── todo.dart               # Todo entity
    │   │   └── prime_result.dart       # Prime calculation result
    │   ├── repositories/
    │   │   └── todo_repository.dart    # Repository interface
    │   ├── usecases/
    │   │   ├── get_todo_usecase.dart       # Single-shot UseCase
    │   │   ├── create_todo_usecase.dart    # UseCase with validation
    │   │   ├── toggle_todo_usecase.dart    # UseCase for updates
    │   │   ├── delete_todo_usecase.dart    # CompletableUseCase (void return)
    │   │   ├── watch_todos_usecase.dart    # StreamUseCase
    │   │   └── calculate_primes_usecase.dart # BackgroundUseCase
    │   └── domain.dart                 # Barrel export
    └── presentation/
        └── pages/
            ├── todo_state.dart         # Immutable state class
            ├── todo_controller.dart    # Controller with all use cases
            └── todo_page.dart          # CleanView with UI
```

## Running the Example

```bash
cd example
flutter pub get
flutter run
```

## Running Tests

```bash
cd example
flutter test
```

## Key Concepts

1. **Single-shot by default**: `UseCase` returns `Future<Result<T, AppFailure>>` instead of streams
2. **Opt-in streaming**: Use `StreamUseCase` when you need reactive updates
3. **Type-safe errors**: `AppFailure` is a sealed class for exhaustive pattern matching
4. **Automatic cleanup**: `Controller` automatically cancels operations on dispose
5. **Fine-grained rebuilds**: Use `ControlledWidgetBuilder` to rebuild only what's needed
6. **Immutable state**: Use immutable state classes with `copyWith` for predictable updates