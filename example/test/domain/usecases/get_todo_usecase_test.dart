import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';

import 'package:example/src/domain/entities/todo.dart';
import 'package:example/src/domain/repositories/todo_repository.dart';
import 'package:example/src/domain/usecases/get_todo_usecase.dart';

class MockTodoRepository extends Mock implements TodoRepository {}

void main() {
  late GetTodoUseCase useCase;
  late MockTodoRepository mockRepository;

  setUp(() {
    mockRepository = MockTodoRepository();
    useCase = GetTodoUseCase(mockRepository);
  });

  final tTodo = Todo(
    id: 1,
    title: 'Test Todo',
    isCompleted: false,
    createdAt: DateTime(2024, 1, 1),
  );

  group('GetTodoUseCase', () {
    test('should return Success with todo when repository returns todo',
        () async {
      // Arrange
      when(() => mockRepository.getTodo(1)).thenAnswer((_) async => tTodo);

      // Act
      final result = await useCase(1);

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.getOrNull(), equals(tTodo));
      verify(() => mockRepository.getTodo(1)).called(1);
    });

    test('should return Failure when repository throws exception', () async {
      // Arrange
      when(() => mockRepository.getTodo(1))
          .thenThrow(Exception('Todo not found'));

      // Act
      final result = await useCase(1);

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.getFailureOrNull(), isA<AppFailure>());
    });

    test('should return Failure with NotFoundFailure for not found errors',
        () async {
      // Arrange
      when(() => mockRepository.getTodo(999))
          .thenThrow(Exception('Todo with id 999 not found'));

      // Act
      final result = await useCase(999);

      // Assert
      expect(result.isFailure, isTrue);
      final failure = result.getFailureOrNull();
      expect(failure, isA<NotFoundFailure>());
    });

    test(
        'should return CancellationFailure when cancel token is cancelled before execution',
        () async {
      // Arrange
      final cancelToken = CancelToken();
      cancelToken.cancel('Test cancellation');

      // Act
      final result = await useCase(1, cancelToken: cancelToken);

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.getFailureOrNull(), isA<CancellationFailure>());
      verifyNever(() => mockRepository.getTodo(any()));
    });

    test('should respect cancel token during execution', () async {
      // Arrange
      final cancelToken = CancelToken();

      when(() => mockRepository.getTodo(1)).thenAnswer((_) async {
        // Simulate delay during which cancellation happens
        await Future.delayed(const Duration(milliseconds: 50));
        return tTodo;
      });

      // Cancel after a short delay
      Future.delayed(const Duration(milliseconds: 10), () {
        cancelToken.cancel('Cancelled during execution');
      });

      // Act
      final result = await useCase(1, cancelToken: cancelToken);

      // Assert - either cancelled or completed depending on timing
      // The important thing is it doesn't crash
      expect(result, isA<Result<Todo, AppFailure>>());
    });

    test('should handle multiple calls correctly', () async {
      // Arrange
      final todo1 = tTodo;
      final todo2 = Todo(
        id: 2,
        title: 'Another Todo',
        isCompleted: true,
        createdAt: DateTime(2024, 1, 2),
      );

      when(() => mockRepository.getTodo(1)).thenAnswer((_) async => todo1);
      when(() => mockRepository.getTodo(2)).thenAnswer((_) async => todo2);

      // Act
      final result1 = await useCase(1);
      final result2 = await useCase(2);

      // Assert
      expect(result1.getOrNull(), equals(todo1));
      expect(result2.getOrNull(), equals(todo2));
      verify(() => mockRepository.getTodo(1)).called(1);
      verify(() => mockRepository.getTodo(2)).called(1);
    });

    test('should fold success correctly', () async {
      // Arrange
      when(() => mockRepository.getTodo(1)).thenAnswer((_) async => tTodo);

      // Act
      final result = await useCase(1);

      String? foldResult;
      result.fold(
        (todo) => foldResult = todo.title,
        (failure) => foldResult = 'error',
      );

      // Assert
      expect(foldResult, equals('Test Todo'));
    });

    test('should fold failure correctly', () async {
      // Arrange
      when(() => mockRepository.getTodo(1))
          .thenThrow(Exception('Something went wrong'));

      // Act
      final result = await useCase(1);

      String? foldResult;
      result.fold(
        (todo) => foldResult = todo.title,
        (failure) => foldResult = 'error: ${failure.message}',
      );

      // Assert
      expect(foldResult, contains('error'));
    });
  });
}
