import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';

import 'package:example/src/domain/entities/todo.dart';
import 'package:example/src/domain/repositories/todo_repository.dart';
import 'package:example/src/domain/usecases/create_todo_usecase.dart';

class MockTodoRepository extends Mock implements TodoRepository {}

void main() {
  late CreateTodoUseCase useCase;
  late MockTodoRepository mockRepository;

  setUp(() {
    mockRepository = MockTodoRepository();
    useCase = CreateTodoUseCase(mockRepository);
  });

  group('CreateTodoUseCase', () {
    final tTodo = Todo(
      id: 1,
      title: 'Buy groceries',
      isCompleted: false,
      createdAt: DateTime(2024, 1, 1),
    );

    test('should return Success with created todo when repository succeeds',
        () async {
      // Arrange
      when(() => mockRepository.createTodo('Buy groceries'))
          .thenAnswer((_) async => tTodo);

      // Act
      final result = await useCase('Buy groceries');

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.getOrNull(), equals(tTodo));
      expect(result.getOrNull()?.title, equals('Buy groceries'));
      verify(() => mockRepository.createTodo('Buy groceries')).called(1);
    });

    test('should trim whitespace from title before creating', () async {
      // Arrange
      when(() => mockRepository.createTodo('Buy groceries'))
          .thenAnswer((_) async => tTodo);

      // Act
      final result = await useCase('  Buy groceries  ');

      // Assert
      expect(result.isSuccess, isTrue);
      verify(() => mockRepository.createTodo('Buy groceries')).called(1);
    });

    test('should return ValidationFailure when title is empty', () async {
      // Act
      final result = await useCase('');

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.getFailureOrNull(), isA<ValidationFailure>());

      final failure = result.getFailureOrNull() as ValidationFailure;
      expect(failure.message, contains('empty'));
      verifyNever(() => mockRepository.createTodo(any()));
    });

    test('should return ValidationFailure when title is only whitespace',
        () async {
      // Act
      final result = await useCase('   ');

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.getFailureOrNull(), isA<ValidationFailure>());
      verifyNever(() => mockRepository.createTodo(any()));
    });

    test('should return Failure when repository throws exception', () async {
      // Arrange
      when(() => mockRepository.createTodo('Test'))
          .thenThrow(Exception('Database error'));

      // Act
      final result = await useCase('Test');

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.getFailureOrNull(), isA<AppFailure>());
    });

    test('should return CancellationFailure when cancelled before execution',
        () async {
      // Arrange
      final cancelToken = CancelToken();
      cancelToken.cancel('User cancelled');

      // Act
      final result = await useCase('Test', cancelToken: cancelToken);

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.getFailureOrNull(), isA<CancellationFailure>());
      verifyNever(() => mockRepository.createTodo(any()));
    });

    test('should work with various valid titles', () async {
      // Arrange
      final titles = [
        'Short',
        'A longer todo item with more details',
        'Todo with numbers 123',
        'Todo with special chars !@#',
        '日本語のタスク',
      ];

      for (final title in titles) {
        final todo = Todo(
          id: 1,
          title: title,
          isCompleted: false,
          createdAt: DateTime.now(),
        );
        when(() => mockRepository.createTodo(title))
            .thenAnswer((_) async => todo);

        // Act
        final result = await useCase(title);

        // Assert
        expect(result.isSuccess, isTrue, reason: 'Failed for title: $title');
      }
    });

    test('should handle ValidationFailure field errors correctly', () async {
      // Act
      final result = await useCase('');

      // Assert
      final failure = result.getFailureOrNull() as ValidationFailure;
      expect(failure.hasErrorFor('title'), isTrue);
      expect(failure.errorsFor('title'), contains('Title is required'));
      expect(failure.firstErrorFor('title'), equals('Title is required'));
    });

    test('should fold success correctly', () async {
      // Arrange
      when(() => mockRepository.createTodo('Test'))
          .thenAnswer((_) async => tTodo);

      // Act
      final result = await useCase('Test');

      String message = '';
      result.fold(
        (todo) => message = 'Created: ${todo.title}',
        (failure) => message = 'Error: ${failure.message}',
      );

      // Assert
      expect(message, equals('Created: Buy groceries'));
    });

    test('should fold failure correctly', () async {
      // Act
      final result = await useCase('');

      String message = '';
      result.fold(
        (todo) => message = 'Created: ${todo.title}',
        (failure) => message = 'Error: ${failure.message}',
      );

      // Assert
      expect(message, contains('Error'));
    });
  });
}
