import '../entities/todo.dart';

/// Repository interface for Todo operations.
///
/// This abstract class defines the contract for Todo data operations.
/// Implementations can use different data sources (API, local DB, etc.)
abstract class TodoRepository {
  /// Get a single todo by ID.
  ///
  /// Throws [Exception] if the todo is not found.
  Future<Todo> getTodo(int id);

  /// Get all todos.
  Future<List<Todo>> getAllTodos();

  /// Watch all todos for real-time updates.
  ///
  /// Emits the current list of todos whenever changes occur.
  Stream<List<Todo>> watchTodos();

  /// Create a new todo.
  ///
  /// Returns the created todo with its assigned ID.
  Future<Todo> createTodo(String title);

  /// Update an existing todo.
  ///
  /// Returns the updated todo.
  Future<Todo> updateTodo(Todo todo);

  /// Toggle the completion status of a todo.
  ///
  /// Returns the updated todo.
  Future<Todo> toggleTodo(int id);

  /// Delete a todo by ID.
  Future<void> deleteTodo(int id);
}
