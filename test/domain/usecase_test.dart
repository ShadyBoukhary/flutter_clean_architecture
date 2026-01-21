import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_matchers.dart';

void main() {
  group('UseCase', () {
    group('successful execution', () {
      test('returns Success with result', () async {
        final useCase = _SuccessfulUseCase();
        final result = await useCase('input');

        expect(result, isSuccess<String>());
        expect(result.getOrNull(), equals('processed: input'));
      });

      test('works with NoParams', () async {
        final useCase = _NoParamsUseCase();
        final result = await useCase(const NoParams());

        expect(result, isSuccess<int>());
        expect(result.getOrNull(), equals(42));
      });

      test('works with complex types', () async {
        final useCase = _ComplexUseCase();
        final params = _ComplexParams(name: 'test', value: 123);
        final result = await useCase(params);

        expect(result, isSuccess<_ComplexResult>());
        expect(result.getOrNull()?.name, equals('test'));
        expect(result.getOrNull()?.value, equals(123));
      });
    });

    group('failure handling', () {
      test('returns Failure when AppFailure is thrown', () async {
        final useCase = _FailingUseCase();
        final result = await useCase('input');

        expect(result, isFailure());
        expect(result, isFailureOfType<NotFoundFailure>());
      });

      test('wraps non-AppFailure exceptions in UnknownFailure', () async {
        final useCase = _ThrowingExceptionUseCase();
        final result = await useCase('input');

        expect(result, isFailure());
        expect(result, isFailureOfType<UnknownFailure>());
        expect(result.getFailureOrNull()?.message,
            contains('Something went wrong'));
      });

      test('wraps ArgumentError in ValidationFailure', () async {
        final useCase = _ThrowingErrorUseCase();
        final result = await useCase('input');

        expect(result, isFailure());
        expect(result, isFailureOfType<ValidationFailure>());
        expect(result.getFailureOrNull()?.message, contains('Bad argument'));
      });

      test('preserves stackTrace on exception', () async {
        final useCase = _ThrowingExceptionUseCase();
        final result = await useCase('input');

        final failure = result.getFailureOrNull();
        expect(failure, isNotNull);
        expect(failure?.stackTrace, isNotNull);
      });
    });

    group('cancellation', () {
      test('returns CancellationFailure when cancelled before execution',
          () async {
        final useCase = _SlowUseCase();
        final cancelToken = CancelToken();
        cancelToken.cancel('Test cancellation');

        final result = await useCase('input', cancelToken: cancelToken);

        expect(result, isFailure());
        expect(result, isFailureOfType<CancellationFailure>());
        expect(
            result.getFailureOrNull()?.message, contains('Test cancellation'));
      });

      test('returns CancellationFailure when throwIfCancelled is called',
          () async {
        final useCase = _CancellationCheckingUseCase();
        final cancelToken = CancelToken();

        // Cancel after a short delay
        Future.delayed(const Duration(milliseconds: 50), () {
          cancelToken.cancel('Cancelled mid-operation');
        });

        final result = await useCase('input', cancelToken: cancelToken);

        expect(result, isFailure());
        expect(result, isFailureOfType<CancellationFailure>());
      });

      test('completes successfully if not cancelled', () async {
        final useCase = _CancellationCheckingUseCase();
        final cancelToken = CancelToken();

        final result = await useCase('fast', cancelToken: cancelToken);

        expect(result, isSuccess<String>());
      });
    });

    group('logging', () {
      test('logger is accessible', () {
        final useCase = _SuccessfulUseCase();
        expect(useCase.logger, isNotNull);
        expect(useCase.logger.name, equals('_SuccessfulUseCase'));
      });
    });
  });

  group('CompletableUseCase', () {
    test('returns Success<void> on completion', () async {
      final useCase = _CompletableSuccessUseCase();
      final result = await useCase('input');

      expect(result, isSuccess<void>());
    });

    test('returns Failure on error', () async {
      final useCase = _CompletableFailingUseCase();
      final result = await useCase('input');

      expect(result, isFailure());
      expect(result, isFailureOfType<ServerFailure>());
    });

    test('supports cancellation', () async {
      final useCase = _CompletableSlowUseCase();
      final cancelToken = CancelToken();
      cancelToken.cancel();

      final result = await useCase('input', cancelToken: cancelToken);

      expect(result, isFailure());
      expect(result, isFailureOfType<CancellationFailure>());
    });
  });

  group('NoParams', () {
    test('equality works', () {
      const params1 = NoParams();
      const params2 = NoParams();

      expect(params1, equals(params2));
      expect(params1.hashCode, equals(params2.hashCode));
    });

    test('toString returns readable format', () {
      const params = NoParams();
      expect(params.toString(), equals('NoParams'));
    });
  });
}

// ============================================================
// Test UseCases
// ============================================================

class _SuccessfulUseCase extends UseCase<String, String> {
  @override
  Future<String> execute(String params, CancelToken? cancelToken) async {
    return 'processed: $params';
  }
}

class _NoParamsUseCase extends UseCase<int, NoParams> {
  @override
  Future<int> execute(NoParams params, CancelToken? cancelToken) async {
    return 42;
  }
}

class _ComplexUseCase extends UseCase<_ComplexResult, _ComplexParams> {
  @override
  Future<_ComplexResult> execute(
      _ComplexParams params, CancelToken? cancelToken) async {
    return _ComplexResult(name: params.name, value: params.value);
  }
}

class _FailingUseCase extends UseCase<String, String> {
  @override
  Future<String> execute(String params, CancelToken? cancelToken) async {
    throw const NotFoundFailure('Resource not found');
  }
}

class _ThrowingExceptionUseCase extends UseCase<String, String> {
  @override
  Future<String> execute(String params, CancelToken? cancelToken) async {
    throw Exception('Something went wrong');
  }
}

class _ThrowingErrorUseCase extends UseCase<String, String> {
  @override
  Future<String> execute(String params, CancelToken? cancelToken) async {
    throw ArgumentError('Bad argument');
  }
}

class _SlowUseCase extends UseCase<String, String> {
  @override
  Future<String> execute(String params, CancelToken? cancelToken) async {
    await Future.delayed(const Duration(seconds: 10));
    return 'done';
  }
}

class _CancellationCheckingUseCase extends UseCase<String, String> {
  @override
  Future<String> execute(String params, CancelToken? cancelToken) async {
    if (params == 'fast') {
      return 'fast result';
    }

    // Simulate work with cancellation checks
    for (var i = 0; i < 10; i++) {
      cancelToken?.throwIfCancelled();
      await Future.delayed(const Duration(milliseconds: 20));
    }

    return 'done';
  }
}

class _CompletableSuccessUseCase extends CompletableUseCase<String> {
  @override
  Future<void> execute(String params, CancelToken? cancelToken) async {
    // Do some work
  }
}

class _CompletableFailingUseCase extends CompletableUseCase<String> {
  @override
  Future<void> execute(String params, CancelToken? cancelToken) async {
    throw const ServerFailure('Internal error', statusCode: 500);
  }
}

class _CompletableSlowUseCase extends CompletableUseCase<String> {
  @override
  Future<void> execute(String params, CancelToken? cancelToken) async {
    await Future.delayed(const Duration(seconds: 10));
  }
}

// ============================================================
// Test Data Classes
// ============================================================

class _ComplexParams {
  final String name;
  final int value;

  const _ComplexParams({required this.name, required this.value});
}

class _ComplexResult {
  final String name;
  final int value;

  const _ComplexResult({required this.name, required this.value});
}
