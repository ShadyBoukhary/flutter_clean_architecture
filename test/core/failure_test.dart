import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppFailure', () {
    group('factory constructor from()', () {
      test('returns same instance if already AppFailure', () {
        const failure = ServerFailure('test error', statusCode: 500);
        final result = AppFailure.from(failure);
        expect(identical(result, failure), isTrue);
      });

      test('creates NetworkFailure for socket exceptions', () {
        final error = Exception('SocketException: Connection refused');
        final failure = AppFailure.from(error);
        expect(failure, isA<NetworkFailure>());
        expect(failure.cause, equals(error));
      });

      test('creates NetworkFailure for connection errors', () {
        final error = Exception('Connection reset by peer');
        final failure = AppFailure.from(error);
        expect(failure, isA<NetworkFailure>());
      });

      test('creates NetworkFailure for failed host lookup', () {
        final error = Exception('Failed host lookup');
        final failure = AppFailure.from(error);
        expect(failure, isA<NetworkFailure>());
      });

      test('creates TimeoutFailure for timeout errors', () {
        final error = Exception('Request timed out');
        final failure = AppFailure.from(error);
        expect(failure, isA<TimeoutFailure>());
      });

      test('creates TimeoutFailure for deadline exceeded', () {
        final error = Exception('Deadline exceeded');
        final failure = AppFailure.from(error);
        expect(failure, isA<TimeoutFailure>());
      });

      test('creates NotFoundFailure for 404 errors', () {
        final error = Exception('HTTP 404 Not Found');
        final failure = AppFailure.from(error);
        expect(failure, isA<NotFoundFailure>());
      });

      test('creates NotFoundFailure for "does not exist" errors', () {
        final error = Exception('Resource does not exist');
        final failure = AppFailure.from(error);
        expect(failure, isA<NotFoundFailure>());
      });

      test('creates UnauthorizedFailure for 401 errors', () {
        final error = Exception('HTTP 401 Unauthorized');
        final failure = AppFailure.from(error);
        expect(failure, isA<UnauthorizedFailure>());
      });

      test('creates UnauthorizedFailure for token errors', () {
        final error = Exception('Token expired');
        final failure = AppFailure.from(error);
        expect(failure, isA<UnauthorizedFailure>());
      });

      test('creates ForbiddenFailure for 403 errors', () {
        final error = Exception('HTTP 403 Forbidden');
        final failure = AppFailure.from(error);
        expect(failure, isA<ForbiddenFailure>());
      });

      test('creates ServerFailure for 500 errors', () {
        final error = Exception('HTTP 500 Internal Server Error');
        final failure = AppFailure.from(error);
        expect(failure, isA<ServerFailure>());
      });

      test('creates ServerFailure for 502 errors', () {
        final error = Exception('Bad Gateway 502');
        final failure = AppFailure.from(error);
        expect(failure, isA<ServerFailure>());
      });

      test('creates ServerFailure for 503 errors', () {
        final error = Exception('Service Unavailable 503');
        final failure = AppFailure.from(error);
        expect(failure, isA<ServerFailure>());
      });

      test('creates UnknownFailure for unrecognized errors', () {
        final error = Exception('Something completely random happened');
        final failure = AppFailure.from(error);
        expect(failure, isA<UnknownFailure>());
      });

      test('preserves stackTrace', () {
        final error = Exception('Test error');
        final stackTrace = StackTrace.current;
        final failure = AppFailure.from(error, stackTrace);
        expect(failure.stackTrace, equals(stackTrace));
      });

      test('preserves cause', () {
        final error = Exception('Test error');
        final failure = AppFailure.from(error);
        expect(failure.cause, equals(error));
      });
    });

    group('ServerFailure', () {
      test('stores statusCode', () {
        const failure = ServerFailure('Server error', statusCode: 503);
        expect(failure.statusCode, equals(503));
      });

      test('toString includes statusCode when present', () {
        const failure = ServerFailure('Server error', statusCode: 500);
        expect(failure.toString(), contains('500'));
        expect(failure.toString(), contains('Server error'));
      });

      test('toString works without statusCode', () {
        const failure = ServerFailure('Server error');
        expect(failure.toString(), equals('ServerFailure: Server error'));
      });
    });

    group('NetworkFailure', () {
      test('stores message', () {
        const failure = NetworkFailure('No internet connection');
        expect(failure.message, equals('No internet connection'));
      });

      test('toString returns correct format', () {
        const failure = NetworkFailure('Connection refused');
        expect(
            failure.toString(), equals('NetworkFailure: Connection refused'));
      });
    });

    group('CacheFailure', () {
      test('stores message', () {
        const failure = CacheFailure('Cache miss');
        expect(failure.message, equals('Cache miss'));
      });

      test('toString returns correct format', () {
        const failure = CacheFailure('Cache corrupted');
        expect(failure.toString(), equals('CacheFailure: Cache corrupted'));
      });
    });

    group('ValidationFailure', () {
      test('stores fieldErrors', () {
        const failure = ValidationFailure(
          'Validation failed',
          fieldErrors: {
            'email': ['Invalid email format'],
            'password': ['Too short', 'Missing special character'],
          },
        );
        expect(failure.fieldErrors, isNotNull);
        expect(failure.fieldErrors!['email'], hasLength(1));
        expect(failure.fieldErrors!['password'], hasLength(2));
      });

      test('hasErrorFor returns true for fields with errors', () {
        const failure = ValidationFailure(
          'Validation failed',
          fieldErrors: {
            'email': ['Invalid']
          },
        );
        expect(failure.hasErrorFor('email'), isTrue);
        expect(failure.hasErrorFor('password'), isFalse);
      });

      test('errorsFor returns errors for field', () {
        const failure = ValidationFailure(
          'Validation failed',
          fieldErrors: {
            'email': ['Invalid', 'Required']
          },
        );
        expect(failure.errorsFor('email'), equals(['Invalid', 'Required']));
        expect(failure.errorsFor('password'), isEmpty);
      });

      test('firstErrorFor returns first error', () {
        const failure = ValidationFailure(
          'Validation failed',
          fieldErrors: {
            'email': ['First error', 'Second error']
          },
        );
        expect(failure.firstErrorFor('email'), equals('First error'));
        expect(failure.firstErrorFor('password'), isNull);
      });

      test('toString includes fieldErrors when present', () {
        const failure = ValidationFailure(
          'Validation failed',
          fieldErrors: {
            'email': ['Invalid']
          },
        );
        expect(failure.toString(), contains('email'));
        expect(failure.toString(), contains('Invalid'));
      });

      test('toString works without fieldErrors', () {
        const failure = ValidationFailure('Validation failed');
        expect(
            failure.toString(), equals('ValidationFailure: Validation failed'));
      });
    });

    group('NotFoundFailure', () {
      test('stores resourceId and resourceType', () {
        const failure = NotFoundFailure(
          'User not found',
          resourceId: '123',
          resourceType: 'User',
        );
        expect(failure.resourceId, equals('123'));
        expect(failure.resourceType, equals('User'));
      });

      test('toString includes resource info when present', () {
        const failure = NotFoundFailure(
          'Not found',
          resourceId: '123',
          resourceType: 'User',
        );
        expect(failure.toString(), contains('User'));
        expect(failure.toString(), contains('123'));
      });

      test('toString works without resource info', () {
        const failure = NotFoundFailure('Resource not found');
        expect(
            failure.toString(), equals('NotFoundFailure: Resource not found'));
      });
    });

    group('UnauthorizedFailure', () {
      test('stores message', () {
        const failure = UnauthorizedFailure('Token expired');
        expect(failure.message, equals('Token expired'));
      });

      test('toString returns correct format', () {
        const failure = UnauthorizedFailure('Invalid credentials');
        expect(failure.toString(),
            equals('UnauthorizedFailure: Invalid credentials'));
      });
    });

    group('ForbiddenFailure', () {
      test('stores requiredPermission', () {
        const failure = ForbiddenFailure(
          'Access denied',
          requiredPermission: 'admin',
        );
        expect(failure.requiredPermission, equals('admin'));
      });

      test('toString returns correct format', () {
        const failure = ForbiddenFailure('Access denied');
        expect(failure.toString(), equals('ForbiddenFailure: Access denied'));
      });
    });

    group('ConflictFailure', () {
      test('stores conflictType', () {
        const failure = ConflictFailure(
          'Duplicate entry',
          conflictType: 'duplicate_email',
        );
        expect(failure.conflictType, equals('duplicate_email'));
      });

      test('toString returns correct format', () {
        const failure = ConflictFailure('Version conflict');
        expect(failure.toString(), equals('ConflictFailure: Version conflict'));
      });
    });

    group('TimeoutFailure', () {
      test('stores timeout duration', () {
        const failure = TimeoutFailure(
          'Request timed out',
          timeout: Duration(seconds: 30),
        );
        expect(failure.timeout, equals(const Duration(seconds: 30)));
      });

      test('toString includes timeout when present', () {
        const failure = TimeoutFailure(
          'Request timed out',
          timeout: Duration(seconds: 30),
        );
        expect(failure.toString(), contains('30s'));
      });

      test('toString works without timeout', () {
        const failure = TimeoutFailure('Request timed out');
        expect(failure.toString(), equals('TimeoutFailure: Request timed out'));
      });
    });

    group('CancellationFailure', () {
      test('has default message', () {
        const failure = CancellationFailure();
        expect(failure.message, equals('Operation was cancelled'));
      });

      test('accepts custom message', () {
        const failure = CancellationFailure('User cancelled');
        expect(failure.message, equals('User cancelled'));
      });

      test('toString returns correct format', () {
        const failure = CancellationFailure();
        expect(failure.toString(),
            equals('CancellationFailure: Operation was cancelled'));
      });
    });

    group('UnknownFailure', () {
      test('stores message', () {
        const failure = UnknownFailure('Something went wrong');
        expect(failure.message, equals('Something went wrong'));
      });

      test('toString returns correct format', () {
        const failure = UnknownFailure('Unknown error');
        expect(failure.toString(), equals('UnknownFailure: Unknown error'));
      });
    });

    group('ExceptionToFailure extension', () {
      test('converts Exception to AppFailure', () {
        final exception = Exception('Test error');
        final failure = exception.toFailure();
        expect(failure, isA<AppFailure>());
        expect(failure.message, contains('Test error'));
      });

      test('preserves stackTrace', () {
        final exception = Exception('Test error');
        final stackTrace = StackTrace.current;
        final failure = exception.toFailure(stackTrace);
        expect(failure.stackTrace, equals(stackTrace));
      });
    });

    group('ErrorToFailure extension', () {
      test('converts Error to AppFailure', () {
        final error = ArgumentError('Invalid argument');
        final failure = error.toFailure();
        expect(failure, isA<AppFailure>());
        expect(failure.message, contains('Invalid argument'));
      });
    });

    group('sealed class exhaustiveness', () {
      test('all failure types can be matched in switch', () {
        const failures = <AppFailure>[
          ServerFailure('test'),
          NetworkFailure('test'),
          CacheFailure('test'),
          ValidationFailure('test'),
          NotFoundFailure('test'),
          UnauthorizedFailure('test'),
          ForbiddenFailure('test'),
          ConflictFailure('test'),
          TimeoutFailure('test'),
          CancellationFailure('test'),
          UnknownFailure('test'),
        ];

        for (final failure in failures) {
          final type = switch (failure) {
            ServerFailure() => 'server',
            NetworkFailure() => 'network',
            CacheFailure() => 'cache',
            ValidationFailure() => 'validation',
            NotFoundFailure() => 'notFound',
            UnauthorizedFailure() => 'unauthorized',
            ForbiddenFailure() => 'forbidden',
            ConflictFailure() => 'conflict',
            TimeoutFailure() => 'timeout',
            CancellationFailure() => 'cancellation',
            UnknownFailure() => 'unknown',
          };
          expect(type, isNotEmpty);
        }
      });
    });
  });
}
