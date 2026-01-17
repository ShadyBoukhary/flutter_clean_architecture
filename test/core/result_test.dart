import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result', () {
    group('Success', () {
      test('isSuccess returns true', () {
        const result = Success<int, String>(42);
        expect(result.isSuccess, isTrue);
        expect(result.isFailure, isFalse);
      });

      test('value returns the wrapped value', () {
        const result = Success<String, String>('hello');
        expect(result.value, equals('hello'));
      });

      test('fold calls onSuccess', () {
        const result = Success<int, String>(42);
        final folded = result.fold(
          (value) => 'success: $value',
          (error) => 'failure: $error',
        );
        expect(folded, equals('success: 42'));
      });

      test('map transforms the value', () {
        const result = Success<int, String>(42);
        final mapped = result.map((value) => value * 2);
        expect(mapped, isA<Success<int, String>>());
        expect((mapped as Success).value, equals(84));
      });

      test('mapFailure returns unchanged Success', () {
        const result = Success<int, String>(42);
        final mapped = result.mapFailure((error) => 'mapped: $error');
        expect(mapped, isA<Success<int, String>>());
        expect((mapped as Success).value, equals(42));
      });

      test('flatMap chains operations', () {
        const result = Success<int, String>(42);
        final chained = result.flatMap((value) => Success(value.toString()));
        expect(chained, isA<Success<String, String>>());
        expect((chained as Success).value, equals('42'));
      });

      test('getOrElse returns the value', () {
        const result = Success<int, String>(42);
        expect(result.getOrElse(() => 0), equals(42));
      });

      test('getOrNull returns the value', () {
        const result = Success<int, String>(42);
        expect(result.getOrNull(), equals(42));
      });

      test('getOrThrow returns the value', () {
        const result = Success<int, String>(42);
        expect(result.getOrThrow(), equals(42));
      });

      test('getFailureOrNull returns null', () {
        const result = Success<int, String>(42);
        expect(result.getFailureOrNull(), isNull);
      });

      test('onSuccess executes the action', () {
        const result = Success<int, String>(42);
        int? captured;
        result.onSuccess((value) => captured = value);
        expect(captured, equals(42));
      });

      test('onFailure does not execute the action', () {
        const result = Success<int, String>(42);
        String? captured;
        result.onFailure((error) => captured = error);
        expect(captured, isNull);
      });

      test('equality works correctly', () {
        const result1 = Success<int, String>(42);
        const result2 = Success<int, String>(42);
        const result3 = Success<int, String>(43);

        expect(result1, equals(result2));
        expect(result1, isNot(equals(result3)));
      });

      test('hashCode is consistent with equality', () {
        const result1 = Success<int, String>(42);
        const result2 = Success<int, String>(42);

        expect(result1.hashCode, equals(result2.hashCode));
      });

      test('toString returns readable representation', () {
        const result = Success<int, String>(42);
        expect(result.toString(), equals('Success(42)'));
      });
    });

    group('Failure', () {
      test('isFailure returns true', () {
        const result = Failure<int, String>('error');
        expect(result.isFailure, isTrue);
        expect(result.isSuccess, isFalse);
      });

      test('error returns the wrapped error', () {
        const result = Failure<int, String>('error');
        expect(result.error, equals('error'));
      });

      test('fold calls onFailure', () {
        const result = Failure<int, String>('error');
        final folded = result.fold(
          (value) => 'success: $value',
          (error) => 'failure: $error',
        );
        expect(folded, equals('failure: error'));
      });

      test('map returns unchanged Failure', () {
        const result = Failure<int, String>('error');
        final mapped = result.map((value) => value * 2);
        expect(mapped, isA<Failure<int, String>>());
        expect((mapped as Failure).error, equals('error'));
      });

      test('mapFailure transforms the error', () {
        const result = Failure<int, String>('error');
        final mapped = result.mapFailure((error) => 'mapped: $error');
        expect(mapped, isA<Failure<int, String>>());
        expect((mapped as Failure).error, equals('mapped: error'));
      });

      test('flatMap returns unchanged Failure', () {
        const result = Failure<int, String>('error');
        final chained = result.flatMap((value) => Success(value.toString()));
        expect(chained, isA<Failure<String, String>>());
        expect((chained as Failure).error, equals('error'));
      });

      test('getOrElse returns the default value', () {
        const result = Failure<int, String>('error');
        expect(result.getOrElse(() => 0), equals(0));
      });

      test('getOrNull returns null', () {
        const result = Failure<int, String>('error');
        expect(result.getOrNull(), isNull);
      });

      test('getOrThrow throws the error', () {
        const result = Failure<int, Exception>(FormatException('bad format'));
        expect(() => result.getOrThrow(), throwsA(isA<FormatException>()));
      });

      test('getOrThrow wraps non-exception errors', () {
        const result = Failure<int, String>('error');
        expect(() => result.getOrThrow(), throwsA(isA<Exception>()));
      });

      test('getFailureOrNull returns the error', () {
        const result = Failure<int, String>('error');
        expect(result.getFailureOrNull(), equals('error'));
      });

      test('onSuccess does not execute the action', () {
        const result = Failure<int, String>('error');
        int? captured;
        result.onSuccess((value) => captured = value);
        expect(captured, isNull);
      });

      test('onFailure executes the action', () {
        const result = Failure<int, String>('error');
        String? captured;
        result.onFailure((error) => captured = error);
        expect(captured, equals('error'));
      });

      test('equality works correctly', () {
        const result1 = Failure<int, String>('error');
        const result2 = Failure<int, String>('error');
        const result3 = Failure<int, String>('different');

        expect(result1, equals(result2));
        expect(result1, isNot(equals(result3)));
      });

      test('hashCode is consistent with equality', () {
        const result1 = Failure<int, String>('error');
        const result2 = Failure<int, String>('error');

        expect(result1.hashCode, equals(result2.hashCode));
      });

      test('toString returns readable representation', () {
        const result = Failure<int, String>('error');
        expect(result.toString(), equals('Failure(error)'));
      });
    });

    group('Result factory constructors', () {
      test('Result.success creates Success', () {
        final result = Result<int, String>.success(42);
        expect(result, isA<Success<int, String>>());
        expect(result.isSuccess, isTrue);
      });

      test('Result.failure creates Failure', () {
        final result = Result<int, String>.failure('error');
        expect(result, isA<Failure<int, String>>());
        expect(result.isFailure, isTrue);
      });
    });

    group('foldAsync', () {
      test('calls onSuccess for Success', () async {
        const result = Success<int, String>(42);
        final folded = await result.foldAsync(
          (value) async => 'success: $value',
          (error) async => 'failure: $error',
        );
        expect(folded, equals('success: 42'));
      });

      test('calls onFailure for Failure', () async {
        const result = Failure<int, String>('error');
        final folded = await result.foldAsync(
          (value) async => 'success: $value',
          (error) async => 'failure: $error',
        );
        expect(folded, equals('failure: error'));
      });
    });

    group('toFuture', () {
      test('completes with value for Success', () async {
        const result = Success<int, String>(42);
        expect(await result.toFuture(), equals(42));
      });

      test('throws for Failure', () async {
        const result = Failure<int, Exception>(FormatException('bad'));
        expect(() => result.toFuture(), throwsA(isA<FormatException>()));
      });
    });
  });

  group('ResultAsyncExtensions', () {
    test('mapAsync transforms value asynchronously', () async {
      const result = Success<int, String>(42);
      final mapped = await result.mapAsync((value) async => value * 2);
      expect(mapped, isA<Success<int, String>>());
      expect((mapped as Success).value, equals(84));
    });

    test('mapAsync preserves Failure', () async {
      const result = Failure<int, String>('error');
      final mapped = await result.mapAsync((value) async => value * 2);
      expect(mapped, isA<Failure<int, String>>());
    });

    test('flatMapAsync chains operations', () async {
      const result = Success<int, String>(42);
      final chained = await result.flatMapAsync(
        (value) async => Success<String, String>(value.toString()),
      );
      expect(chained, isA<Success<String, String>>());
      expect((chained as Success).value, equals('42'));
    });
  });

  group('FutureResultExtensions', () {
    test('map transforms success value', () async {
      final future = Future.value(Result<int, String>.success(42));
      final mapped = await future.map((value) => value * 2);
      expect(mapped.getOrNull(), equals(84));
    });

    test('flatMap chains futures', () async {
      final future = Future.value(Result<int, String>.success(42));
      final chained = await future.flatMap(
        (value) async => Result<String, String>.success(value.toString()),
      );
      expect(chained.getOrNull(), equals('42'));
    });

    test('getOrElse returns value for success', () async {
      final future = Future.value(Result<int, String>.success(42));
      expect(await future.getOrElse(() => 0), equals(42));
    });

    test('getOrElse returns default for failure', () async {
      final future = Future.value(Result<int, String>.failure('error'));
      expect(await future.getOrElse(() => 0), equals(0));
    });

    test('getOrNull returns value for success', () async {
      final future = Future.value(Result<int, String>.success(42));
      expect(await future.getOrNull(), equals(42));
    });

    test('getOrNull returns null for failure', () async {
      final future = Future.value(Result<int, String>.failure('error'));
      expect(await future.getOrNull(), isNull);
    });

    test('fold works on future', () async {
      final future = Future.value(Result<int, String>.success(42));
      final result = await future.fold(
        (value) => 'success: $value',
        (error) => 'failure: $error',
      );
      expect(result, equals('success: 42'));
    });
  });
}
