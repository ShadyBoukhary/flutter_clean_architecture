import 'dart:async';

import '../../domain/entities/todo.dart';
import '../../domain/repositories/todo_repository.dart';

/// In-memory implementation of [TodoRepository].
///
/// This is a simple implementation for demonstration purposes.
/// In a real app, you'd implement against an API or local database.
class InMemoryTodoRepository implements TodoRepository {
  final List<Todo> _todos = [];
  int _nextId = 1;

  final _controller = StreamController<List<Todo>>.broadcast();

  /// Create a repository with optional initial todos.
  InMemoryTodoRepository({List<Todo>? initialTodos}) {
    if (initialTodos != null) {
      _todos.addAll(initialTodos);
      _nextId = initialTodos.fold(0, (max, t) => t.id > max ? t.id : max) + 1;
    }
  }

  void _notifyListeners() {
    _controller.add(List.unmodifiable(_todos));
  }

  @override
  Future<Todo> getTodo(int id) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    final todo = _todos.where((t) => t.id == id).firstOrNull;
    if (todo == null) {
      throw Exception('Todo with id $id not found');
    }
    return todo;
  }

  @override
  Future<List<Todo>> getAllTodos() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return List.unmodifiable(_todos);
  }

  @override
  Stream<List<Todo>> watchTodos() async* {
    // Emit current state immediately
    yield List.unmodifiable(_todos);

    // Then emit updates
    yield* _controller.stream;
  }

  @override
  Future<Todo> createTodo(String title) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 200));

    final todo = Todo(
      id: _nextId++,
      title: title,
      isCompleted: false,
      createdAt: DateTime.now(),
    );

    _todos.add(todo);
    _notifyListeners();

    return todo;
  }

  @override
  Future<Todo> updateTodo(Todo todo) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 200));

    final index = _todos.indexWhere((t) => t.id == todo.id);
    if (index == -1) {
      throw Exception('Todo with id ${todo.id} not found');
    }

    _todos[index] = todo;
    _notifyListeners();

    return todo;
  }

  @override
  Future<Todo> toggleTodo(int id) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 200));

    final index = _todos.indexWhere((t) => t.id == id);
    if (index == -1) {
      throw Exception('Todo with id $id not found');
    }

    final todo = _todos[index];
    final updated = todo.copyWith(isCompleted: !todo.isCompleted);
    _todos[index] = updated;
    _notifyListeners();

    return updated;
  }

  @override
  Future<void> deleteTodo(int id) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 200));

    final index = _todos.indexWhere((t) => t.id == id);
    if (index == -1) {
      throw Exception('Todo with id $id not found');
    }

    _todos.removeAt(index);
    _notifyListeners();
  }

  /// Dispose of resources.
  void dispose() {
    _controller.close();
  }
}
