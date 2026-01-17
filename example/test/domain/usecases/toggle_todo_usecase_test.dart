import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';

import 'package:example/src/domain/entities/todo.dart';
import 'package:example/src/domain/repositories/todo_repository.dart';
import 'package:example/src/domain/usecases/toggle_todo_usecase.dart';

class MockTodoRepository extends Mock implements TodoRepository {}

void main() {
  late ToggleTodoUseCase useCase;
  late MockTodoRepository mockRepository;

  setUp(() {
    mockRepository = MockTodoRepository();
    useCase = ToggleTodoUseCase(mockRepository);
  });

  group('ToggleTodoUseCase', () {
    final tTodoIncomplete = Todo(
      id: 1,
      title: 'Test Todo',
      isCompleted: false,
      createdAt: DateTime(2024, 1, 1),
    );

    final tTodoCompleted = Todo(
      id: 1,
      title: 'Test Todo',
      isCompleted: true,
      createdAt: DateTime(2024, 1, 1),
    );

    test('should return Success with toggled todo (incomplete to completed)',
        () async {
      // Arrange
      when(() => mockRepository.toggleTodo(1))
          .thenAnswer((_) async => tTodoCompleted);

      // Act
      final result = await useCase(1);

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.getOrNull()?.isCompleted, isTrue);
      verify(() => mockRepository.toggleTodo(1)).called(1);
    });

    test('should return Success with toggled todo (completed to incomplete)',
        () async {
      // Arrange
      when(() => mockRepository.toggleTodo(1))
          .thenAnswer((_) async => tTodoIncomplete);

      // Act
      final result = await useCase(1);

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.getOrNull()?.isCompleted, isFalse);
      verify(() => mockRepository.toggleTodo(1)).called(1);
    });

    test('should return Failure when repository throws exception', () async {
      // Arrange
      when(() => mockRepository.toggleTodo(1))
          .thenThrow(Exception('Failed to toggle'));

      // Act
      final result = await useCase(1);

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.getFailureOrNull(), isA<AppFailure>());
    });

    test('should return NotFoundFailure when todo does not exist', () async {
      // Arrange
      when(() => mockRepository.toggleTodo(999))
          .thenThrow(Exception('Todo with id 999 not found'));

      // Act
      final result = await useCase(999);

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.getFailureOrNull(), isA<NotFoundFailure>());
    });

    test('should return CancellationFailure when cancelled before execution',
        () async {
      // Arrange
      final cancelToken = CancelToken();
      cancelToken.cancel('User cancelled');

      // Act
      final result = await useCase(1, cancelToken: cancelToken);

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.getFailureOrNull(), isA<CancellationFailure>());
      verifyNever(() => mockRepository.toggleTodo(any()));
    });

    test('should preserve todo id after toggle', () async {
      // Arrange
      when(() => mockRepository.toggleTodo(42)).thenAnswer((_) async => Todo(
            id: 42,
            title: 'My Todo',
            isCompleted: true,
            createdAt: DateTime(2024, 1, 1),
          ));

      // Act
      final result = await useCase(42);

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.getOrNull()?.id, equals(42));
    });

    test('should preserve todo title after toggle', () async {
      // Arrange
      when(() => mockRepository.toggleTodo(1))
          .thenAnswer((_) async => tTodoCompleted);

      // Act
      final result = await useCase(1);

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.getOrNull()?.title, equals('Test Todo'));
    });

    test('should handle multiple toggles correctly', () async {
      // Arrange
      when(() => mockRepository.toggleTodo(1))
          .thenAnswer((_) async => tTodoCompleted);
      when(() => mockRepository.toggleTodo(2)).thenAnswer((_) async => Todo(
            id: 2,
            title: 'Another Todo',
            isCompleted: false,
            createdAt: DateTime(2024, 1, 2),
          ));

      // Act
      final result1 = await useCase(1);
      final result2 = await useCase(2);

      // Assert
      expect(result1.getOrNull()?.isCompleted, isTrue);
      expect(result2.getOrNull()?.isCompleted, isFalse);
      verify(() => mockRepository.toggleTodo(1)).called(1);
      verify(() => mockRepository.toggleTodo(2)).called(1);
    });

    test('should fold success correctly', () async {
      // Arrange
      when(() => mockRepository.toggleTodo(1))
          .thenAnswer((_) async => tTodoCompleted);

      // Act
      final result = await useCase(1);

      String message = '';
      result.fold(
        (todo) => message = 'Toggled to ${todo.isCompleted}',
        (failure) => message = 'Error',
      );

      // Assert
      expect(message, equals('Toggled to true'));
    });

    test('should fold failure correctly', () async {
      // Arrange
      when(() => mockRepository.toggleTodo(1))
          .thenThrow(Exception('Database error'));

      // Act
      final result = await useCase(1);

      String message = '';
      result.fold(
        (todo) => message = 'Success',
        (failure) => message = 'Error: ${failure.runtimeType}',
      );

      // Assert
      expect(message, contains('Error'));
    });

    test('should handle negative id gracefully', () async {
      // Arrange
      when(() => mockRepository.toggleTodo(-1))
          .thenThrow(Exception('Invalid todo id'));

      // Act
      final result = await useCase(-1);

      // Assert
      expect(result.isFailure, isTrue);
    });

    test('should handle zero id', () async {
      // Arrange
      when(() => mockRepository.toggleTodo(0))
          .thenThrow(Exception('Todo with id 0 not found'));

      // Act
      final result = await useCase(0);

      // Assert
      expect(result.isFailure, isTrue);
    });
  });
}
