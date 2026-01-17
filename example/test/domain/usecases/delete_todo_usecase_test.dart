import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';

import 'package:example/src/domain/repositories/todo_repository.dart';
import 'package:example/src/domain/usecases/delete_todo_usecase.dart';

class MockTodoRepository extends Mock implements TodoRepository {}

void main() {
  late DeleteTodoUseCase useCase;
  late MockTodoRepository mockRepository;

  setUp(() {
    mockRepository = MockTodoRepository();
    useCase = DeleteTodoUseCase(mockRepository);
  });

  group('DeleteTodoUseCase', () {
    test('should return Success with void when deletion succeeds', () async {
      // Arrange
      when(() => mockRepository.deleteTodo(1)).thenAnswer((_) async {});

      // Act
      final result = await useCase(1);

      // Assert
      expect(result.isSuccess, isTrue);
      verify(() => mockRepository.deleteTodo(1)).called(1);
    });

    test('should return Failure when repository throws exception', () async {
      // Arrange
      when(() => mockRepository.deleteTodo(1))
          .thenThrow(Exception('Failed to delete'));

      // Act
      final result = await useCase(1);

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.getFailureOrNull(), isA<AppFailure>());
    });

    test('should return NotFoundFailure when todo does not exist', () async {
      // Arrange
      when(() => mockRepository.deleteTodo(999))
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
      verifyNever(() => mockRepository.deleteTodo(any()));
    });

    test('should delete correct todo by id', () async {
      // Arrange
      when(() => mockRepository.deleteTodo(42)).thenAnswer((_) async {});

      // Act
      final result = await useCase(42);

      // Assert
      expect(result.isSuccess, isTrue);
      verify(() => mockRepository.deleteTodo(42)).called(1);
      verifyNever(() => mockRepository.deleteTodo(1));
    });

    test('should handle multiple deletes correctly', () async {
      // Arrange
      when(() => mockRepository.deleteTodo(1)).thenAnswer((_) async {});
      when(() => mockRepository.deleteTodo(2)).thenAnswer((_) async {});
      when(() => mockRepository.deleteTodo(3)).thenAnswer((_) async {});

      // Act
      final result1 = await useCase(1);
      final result2 = await useCase(2);
      final result3 = await useCase(3);

      // Assert
      expect(result1.isSuccess, isTrue);
      expect(result2.isSuccess, isTrue);
      expect(result3.isSuccess, isTrue);
      verify(() => mockRepository.deleteTodo(1)).called(1);
      verify(() => mockRepository.deleteTodo(2)).called(1);
      verify(() => mockRepository.deleteTodo(3)).called(1);
    });

    test('should fold success correctly', () async {
      // Arrange
      when(() => mockRepository.deleteTodo(1)).thenAnswer((_) async {});

      // Act
      final result = await useCase(1);

      String message = '';
      result.fold(
        (_) => message = 'Deleted successfully',
        (failure) => message = 'Error',
      );

      // Assert
      expect(message, equals('Deleted successfully'));
    });

    test('should fold failure correctly', () async {
      // Arrange
      when(() => mockRepository.deleteTodo(1))
          .thenThrow(Exception('Database error'));

      // Act
      final result = await useCase(1);

      String message = '';
      result.fold(
        (_) => message = 'Success',
        (failure) => message = 'Error: ${failure.runtimeType}',
      );

      // Assert
      expect(message, contains('Error'));
    });

    test('should handle network failure', () async {
      // Arrange
      when(() => mockRepository.deleteTodo(1))
          .thenThrow(Exception('Connection refused'));

      // Act
      final result = await useCase(1);

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.getFailureOrNull(), isA<NetworkFailure>());
    });

    test('should handle timeout failure', () async {
      // Arrange
      when(() => mockRepository.deleteTodo(1))
          .thenThrow(Exception('Request timed out'));

      // Act
      final result = await useCase(1);

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.getFailureOrNull(), isA<TimeoutFailure>());
    });

    test('should handle negative id gracefully', () async {
      // Arrange
      when(() => mockRepository.deleteTodo(-1))
          .thenThrow(Exception('Invalid todo id'));

      // Act
      final result = await useCase(-1);

      // Assert
      expect(result.isFailure, isTrue);
    });

    test('should handle zero id', () async {
      // Arrange
      when(() => mockRepository.deleteTodo(0))
          .thenThrow(Exception('Todo with id 0 not found'));

      // Act
      final result = await useCase(0);

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.getFailureOrNull(), isA<NotFoundFailure>());
    });

    test('should not throw when called multiple times for same id', () async {
      // Arrange
      when(() => mockRepository.deleteTodo(1)).thenAnswer((_) async {});

      // Act & Assert - should not throw
      await useCase(1);

      // Second call - repository might throw "not found" but use case handles it
      when(() => mockRepository.deleteTodo(1))
          .thenThrow(Exception('Todo with id 1 not found'));

      final result = await useCase(1);
      expect(result.isFailure, isTrue);
    });

    test('should be a CompletableUseCase returning void on success', () async {
      // Arrange
      when(() => mockRepository.deleteTodo(1)).thenAnswer((_) async {});

      // Act
      final result = await useCase(1);

      // Assert
      expect(result.isSuccess, isTrue);
      // The success value should be void (null when accessed)
      result.fold(
        (value) {
          // void type - this is the expected behavior for CompletableUseCase
          // void type - this is the expected behavior for CompletableUseCase
        },
        (failure) => fail('Expected success'),
      );
    });
  });
}
