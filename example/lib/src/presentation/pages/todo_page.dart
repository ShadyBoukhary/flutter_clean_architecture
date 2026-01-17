import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';

import '../../data/repositories/in_memory_todo_repository.dart';
import '../../domain/entities/todo.dart';
import 'todo_controller.dart';
import 'todo_state.dart';

/// The main Todo page demonstrating Flutter Clean Architecture v7.
///
/// This page shows:
/// - [CleanView] and [CleanViewState] base classes
/// - [ControlledWidgetBuilder] for fine-grained rebuilds
/// - [ControlledWidgetSelector] for selective rebuilds
/// - Integration with [TodoController]
class TodoPage extends CleanView {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends CleanViewState<TodoPage, TodoController> {
  _TodoPageState()
      : super(TodoController(
          repository: InMemoryTodoRepository(),
        ));

  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget get view {
    return Scaffold(
      key: globalKey,
      appBar: AppBar(
        title: const Text('Clean Architecture Demo'),
        actions: [
          // Prime calculation button
          ControlledWidgetBuilder<TodoController>(
            builder: (context, controller) {
              return IconButton(
                icon: controller.viewState.isCalculatingPrime
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.calculate),
                onPressed: controller.viewState.isCalculatingPrime
                    ? controller.cancelPrimeCalculation
                    : () => _showPrimeDialog(context),
                tooltip: controller.viewState.isCalculatingPrime
                    ? 'Cancel calculation'
                    : 'Calculate prime',
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Error banner
          _buildErrorBanner(),

          // Prime result banner
          _buildPrimeResultBanner(),

          // Todo input
          _buildTodoInput(),

          // Todo list
          Expanded(child: _buildTodoList()),

          // Stats footer
          _buildStatsFooter(),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return ControlledWidgetSelector<TodoController, AppFailure?>(
      selector: (controller) => controller.viewState.error,
      builder: (context, error) {
        if (error == null) return const SizedBox.shrink();

        return MaterialBanner(
          backgroundColor: Colors.red.shade100,
          content: Text(
            _formatError(error),
            style: TextStyle(color: Colors.red.shade900),
          ),
          actions: [
            TextButton(
              onPressed: () => controller.clearError(),
              child: const Text('DISMISS'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPrimeResultBanner() {
    return ControlledWidgetSelector<TodoController, TodoState>(
      selector: (controller) => controller.viewState,
      builder: (context, state) {
        if (state.primeResult == null && state.progressMessage == null) {
          return const SizedBox.shrink();
        }

        if (state.isCalculatingPrime && state.progressMessage != null) {
          return Container(
            padding: const EdgeInsets.all(12),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(state.progressMessage!)),
                TextButton(
                  onPressed: controller.cancelPrimeCalculation,
                  child: const Text('CANCEL'),
                ),
              ],
            ),
          );
        }

        if (state.primeResult != null) {
          final result = state.primeResult!;
          return Container(
            padding: const EdgeInsets.all(12),
            color: Colors.green.shade50,
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'The ${_ordinal(result.nthPrime)} prime is ${result.value} '
                    '(calculated in ${result.duration.inMilliseconds}ms)',
                    style: TextStyle(color: Colors.green.shade900),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: controller.clearPrimeResult,
                  iconSize: 18,
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildTodoInput() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: const InputDecoration(
                hintText: 'What needs to be done?',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _createTodo(),
            ),
          ),
          const SizedBox(width: 12),
          ControlledWidgetSelector<TodoController, bool>(
            selector: (controller) => controller.viewState.isCreating,
            builder: (context, isCreating) {
              return ElevatedButton(
                onPressed: isCreating ? null : _createTodo,
                child: isCreating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Add'),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTodoList() {
    return ControlledWidgetBuilder<TodoController>(
      builder: (context, controller) {
        final state = controller.viewState;

        if (state.isLoading && state.todos.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (state.todos.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No todos yet!',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add one above to get started.',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: state.todos.length,
          itemBuilder: (context, index) {
            final todo = state.todos[index];
            return _buildTodoItem(todo);
          },
        );
      },
    );
  }

  Widget _buildTodoItem(Todo todo) {
    return Dismissible(
      key: ValueKey(todo.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => controller.deleteTodo(todo.id),
      child: ListTile(
        leading: Checkbox(
          value: todo.isCompleted,
          onChanged: (_) => controller.toggleTodo(todo.id),
        ),
        title: Text(
          todo.title,
          style: TextStyle(
            decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
            color: todo.isCompleted ? Colors.grey : null,
          ),
        ),
        subtitle: Text(
          'Created ${_formatDate(todo.createdAt)}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsFooter() {
    return ControlledWidgetSelector<TodoController, TodoState>(
      selector: (controller) => controller.viewState,
      builder: (context, state) {
        if (!state.hasTodos) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            border: Border(
              top: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${state.activeCount} active',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 24),
              Text(
                '${state.completedCount} completed',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        );
      },
    );
  }

  void _createTodo() {
    final title = _textController.text;
    if (title.isNotEmpty) {
      controller.createTodo(title);
      _textController.clear();
    }
  }

  void _showPrimeDialog(BuildContext context) {
    final primeController = TextEditingController(text: '10000');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Calculate Prime'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This demonstrates BackgroundUseCase running a CPU-intensive '
                'calculation on a separate isolate without blocking the UI.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: primeController,
                decoration: const InputDecoration(
                  labelText: 'Calculate the Nth prime',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                final n = int.tryParse(primeController.text) ?? 10000;
                controller.calculatePrime(n);
                Navigator.pop(context);
              },
              child: const Text('CALCULATE'),
            ),
          ],
        );
      },
    );
  }

  String _formatError(AppFailure failure) {
    return switch (failure) {
      ValidationFailure(:final message) => message,
      NotFoundFailure(:final message) => message,
      NetworkFailure() => 'Network error. Please check your connection.',
      TimeoutFailure() => 'Request timed out. Please try again.',
      CancellationFailure() => 'Operation was cancelled.',
      _ => failure.message,
    };
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return 'just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

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
}
