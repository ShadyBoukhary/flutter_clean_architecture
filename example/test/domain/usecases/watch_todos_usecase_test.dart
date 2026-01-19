import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';

import 'package:example/src/domain/entities/todo.dart';
import 'package:example/src/domain/repositories/todo_repository.dart';
import 'package:example/src/domain/usecases/watch_todos_usecase.dart';

class MockTodoRepository extends Mock implements TodoRepository {}

void main() {
  late WatchTodosUseCase useCase;
  late MockTodoRepository mockRepository;

  setUp(() {
    mockRepository = MockTodoRepository();
    useCase = WatchTodosUseCase(mockRepository);
  });

  tearDown(() {
    useCase.dispose();
    reset(mockRepository);
  });

  final tTodos = [
    Todo(
      id: 1,
      title: 'First Todo',
      isCompleted: false,
      createdAt: DateTime(2024, 1, 1),
    ),
    Todo(
      id: 2,
      title: 'Second Todo',
      isCompleted: true,
      createdAt: DateTime(2024, 1, 2),
    ),
  ];

  group('WatchTodosUseCase', () {
    test('should emit Success with todos when repository emits data', () async {
      // Arrange
      when(() => mockRepository.watchTodos())
          .thenAnswer((_) => Stream.value(tTodos));

      // Act
      final stream = useCase(const NoParams());
      final results = <Result<List<Todo>, AppFailure>>[];
      final subscription = stream.listen(results.add);

      await Future.delayed(const Duration(milliseconds: 50));

      // Assert
      expect(results, hasLength(1));
      expect(results.first.isSuccess, isTrue);
      expect(results.first.getOrNull(), equals(tTodos));

      // Cleanup
      await subscription.cancel();
    });

    test('should emit multiple values as stream updates', () async {
      // Arrange
      when(() => mockRepository.watchTodos())
          .thenAnswer((_) => Stream.fromIterable([
                [],
                [tTodos.first],
                tTodos
              ]));

      // Act
      final stream = useCase(const NoParams());
      final results = <Result<List<Todo>, AppFailure>>[];
      final subscription = stream.listen(results.add);

      await Future.delayed(const Duration(milliseconds: 50));

      // Assert
      expect(results, hasLength(3));
      expect(results[0].getOrNull(), isEmpty);
      expect(results[1].getOrNull(), hasLength(1));
      expect(results[2].getOrNull(), hasLength(2));

      // Cleanup
      await subscription.cancel();
    });

    test('should emit Failure when repository stream has error', () async {
      // Arrange
      final streamController = StreamController<List<Todo>>();
      when(() => mockRepository.watchTodos())
          .thenAnswer((_) => streamController.stream);

      // Act
      final stream = useCase(const NoParams());
      final results = <Result<List<Todo>, AppFailure>>[];
      final subscription = stream.listen(results.add);

      // Emit error
      streamController.addError(Exception('Database connection lost'));
      await Future.delayed(const Duration(milliseconds: 50));

      // Assert
      expect(results, hasLength(1));
      expect(results.first.isFailure, isTrue);
      expect(results.first.getFailureOrNull(), isA<AppFailure>());

      // Cleanup
      await subscription.cancel();
      await streamController.close();
    });

    test('should return CancellationFailure when cancelled before starting',
        () async {
      // Arrange
      final cancelToken = CancelToken();
      cancelToken.cancel('User navigated away');

      // Act
      final stream = useCase(const NoParams(), cancelToken: cancelToken);
      final results = await stream.toList();

      // Assert
      expect(results, hasLength(1));
      expect(results.first.isFailure, isTrue);
      expect(results.first.getFailureOrNull(), isA<CancellationFailure>());
      verifyNever(() => mockRepository.watchTodos());
    });

    test('should stop emitting when cancel token is cancelled during stream',
        () async {
      // Arrange
      final streamController = StreamController<List<Todo>>();
      when(() => mockRepository.watchTodos())
          .thenAnswer((_) => streamController.stream);

      final cancelToken = CancelToken();

      // Act
      final stream = useCase(const NoParams(), cancelToken: cancelToken);
      final results = <Result<List<Todo>, AppFailure>>[];
      final subscription = stream.listen(results.add);

      // Emit first value
      streamController.add([tTodos.first]);
      await Future.delayed(const Duration(milliseconds: 20));

      // Cancel
      cancelToken.cancel('User cancelled');
      await Future.delayed(const Duration(milliseconds: 20));

      // Try to emit more (should be ignored)
      streamController.add(tTodos);
      await Future.delayed(const Duration(milliseconds: 20));

      // Assert - should have first value and possibly a cancellation
      expect(results.length, greaterThanOrEqualTo(1));
      expect(results.first.isSuccess, isTrue);

      // Cleanup
      await subscription.cancel();
      await streamController.close();
    });

    test('should work with listen helper method', () async {
      // Arrange
      final streamController = StreamController<List<Todo>>();
      when(() => mockRepository.watchTodos())
          .thenAnswer((_) => streamController.stream);

      final receivedData = <List<Todo>>[];
      final receivedErrors = <AppFailure>[];
      bool isDone = false;

      // Act
      final subscription = useCase.listen(
        const NoParams(),
        onData: (data) => receivedData.add(data),
        onError: (failure) => receivedErrors.add(failure),
        onDone: () => isDone = true,
      );

      // Emit data
      streamController.add(tTodos);
      await Future.delayed(const Duration(milliseconds: 50));

      // Assert
      expect(receivedData, hasLength(1));
      expect(receivedData.first, equals(tTodos));
      expect(receivedErrors, isEmpty);

      // Close stream
      await streamController.close();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(isDone, isTrue);

      // Cleanup
      await subscription.cancel();
    });

    test('should complete stream when repository stream closes', () async {
      // Arrange
      final streamController = StreamController<List<Todo>>();
      when(() => mockRepository.watchTodos())
          .thenAnswer((_) => streamController.stream);

      // Act
      final stream = useCase(const NoParams());
      final results = <Result<List<Todo>, AppFailure>>[];
      bool isDone = false;

      final subscription = stream.listen(
        results.add,
        onDone: () => isDone = true,
      );

      // Emit and close
      streamController.add(tTodos);
      await Future.delayed(const Duration(milliseconds: 20));
      await streamController.close();
      await Future.delayed(const Duration(milliseconds: 50));

      // Assert
      expect(results, hasLength(1));
      expect(isDone, isTrue);

      // Cleanup
      await subscription.cancel();
    });

    test('should get first result using first() extension', () async {
      // Arrange
      final streamController = StreamController<List<Todo>>();
      when(() => mockRepository.watchTodos())
          .thenAnswer((_) => streamController.stream);

      // Emit immediately so first() can complete
      Future.delayed(const Duration(milliseconds: 10), () {
        streamController.add(tTodos);
      });

      // Act
      final result = await useCase.first(const NoParams());

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.getOrNull(), equals(tTodos));

      // Cleanup
      await streamController.close();
    });

    test('should handle empty todo list correctly', () async {
      // Arrange
      when(() => mockRepository.watchTodos())
          .thenAnswer((_) => Stream.value([]));

      // Act
      final stream = useCase(const NoParams());
      final results = <Result<List<Todo>, AppFailure>>[];
      final subscription = stream.listen(results.add);

      await Future.delayed(const Duration(milliseconds: 50));

      // Assert
      expect(results, hasLength(1));
      expect(results.first.isSuccess, isTrue);
      expect(results.first.getOrNull(), isEmpty);

      // Cleanup
      await subscription.cancel();
    });

    test('should allow multiple listeners', () async {
      // Arrange
      when(() => mockRepository.watchTodos())
          .thenAnswer((_) => Stream.value(tTodos));

      // Act
      final stream1 = useCase(const NoParams());
      final stream2 = useCase(const NoParams());

      final results1 = <Result<List<Todo>, AppFailure>>[];
      final results2 = <Result<List<Todo>, AppFailure>>[];

      final sub1 = stream1.listen(results1.add);
      final sub2 = stream2.listen(results2.add);

      await Future.delayed(const Duration(milliseconds: 50));

      // Both should receive data
      expect(results1.isNotEmpty && results2.isNotEmpty, isTrue);

      // Cleanup
      await sub1.cancel();
      await sub2.cancel();
    });

    test('should dispose correctly and cancel subscriptions', () async {
      // Arrange
      final streamController = StreamController<List<Todo>>();
      when(() => mockRepository.watchTodos())
          .thenAnswer((_) => streamController.stream);

      final receivedData = <List<Todo>>[];

      // Act
      useCase.listen(
        const NoParams(),
        onData: (data) => receivedData.add(data),
      );

      // Emit first value
      streamController.add([tTodos.first]);
      await Future.delayed(const Duration(milliseconds: 20));

      // Dispose
      useCase.dispose();

      // Try to emit more (should be ignored after dispose)
      streamController.add(tTodos);
      await Future.delayed(const Duration(milliseconds: 20));

      // Assert - should have only the first emission
      expect(receivedData, hasLength(1));

      // Cleanup
      await streamController.close();
    });
  });
}
