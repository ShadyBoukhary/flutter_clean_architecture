import 'dart:async';

import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CancelToken', () {
    group('initial state', () {
      test('isCancelled is false initially', () {
        final token = CancelToken();
        expect(token.isCancelled, isFalse);
      });

      test('cancelReason is null initially', () {
        final token = CancelToken();
        expect(token.cancelReason, isNull);
      });
    });

    group('cancel()', () {
      test('sets isCancelled to true', () {
        final token = CancelToken();
        token.cancel();
        expect(token.isCancelled, isTrue);
      });

      test('stores cancel reason', () {
        final token = CancelToken();
        token.cancel('User requested cancellation');
        expect(token.cancelReason, equals('User requested cancellation'));
      });

      test('is idempotent - multiple cancels have no effect', () {
        final token = CancelToken();
        token.cancel('First reason');
        token.cancel('Second reason');
        expect(token.isCancelled, isTrue);
        expect(token.cancelReason, equals('First reason'));
      });

      test('emits on onCancel stream', () async {
        final token = CancelToken();
        var emitted = false;

        token.onCancel.listen((_) {
          emitted = true;
        });

        token.cancel();
        await Future.delayed(Duration.zero);

        expect(emitted, isTrue);
      });

      test('onCancel stream closes after cancel', () async {
        final token = CancelToken();
        var streamDone = false;

        token.onCancel.listen(
          (_) {},
          onDone: () => streamDone = true,
        );

        token.cancel();
        await Future.delayed(Duration.zero);

        expect(streamDone, isTrue);
      });
    });

    group('throwIfCancelled()', () {
      test('does nothing when not cancelled', () {
        final token = CancelToken();
        expect(() => token.throwIfCancelled(), returnsNormally);
      });

      test('throws CancelledException when cancelled', () {
        final token = CancelToken();
        token.cancel();
        expect(
          () => token.throwIfCancelled(),
          throwsA(isA<CancelledException>()),
        );
      });

      test('throws with cancel reason', () {
        final token = CancelToken();
        token.cancel('Test cancellation');

        try {
          token.throwIfCancelled();
          fail('Should have thrown');
        } on CancelledException catch (e) {
          expect(e.message, equals('Test cancellation'));
        }
      });
    });

    group('linkTo()', () {
      test('child is cancelled when parent is cancelled', () {
        final parent = CancelToken();
        final child = CancelToken();

        child.linkTo(parent);
        parent.cancel('Parent cancelled');

        expect(child.isCancelled, isTrue);
        expect(child.cancelReason, equals('Parent cancelled'));
      });

      test('parent is not cancelled when child is cancelled', () {
        final parent = CancelToken();
        final child = CancelToken();

        child.linkTo(parent);
        child.cancel('Child cancelled');

        expect(parent.isCancelled, isFalse);
        expect(child.isCancelled, isTrue);
      });

      test('child inherits cancelled state from parent', () {
        final parent = CancelToken();
        parent.cancel('Already cancelled');

        final child = CancelToken();
        child.linkTo(parent);

        expect(child.isCancelled, isTrue);
      });

      test('throws when trying to link twice', () {
        final parent1 = CancelToken();
        final parent2 = CancelToken();
        final child = CancelToken();

        child.linkTo(parent1);

        expect(
          () => child.linkTo(parent2),
          throwsA(isA<StateError>()),
        );
      });

      test('isCancelled returns true if parent is cancelled', () {
        final parent = CancelToken();
        final child = CancelToken();

        child.linkTo(parent);

        expect(child.isCancelled, isFalse);
        parent.cancel();
        expect(child.isCancelled, isTrue);
      });
    });

    group('createChild()', () {
      test('creates a linked child token', () {
        final parent = CancelToken();
        final child = parent.createChild();

        expect(child.isCancelled, isFalse);

        parent.cancel('Parent cancelled');

        expect(child.isCancelled, isTrue);
      });

      test('child is independent until parent cancels', () {
        final parent = CancelToken();
        final child = parent.createChild();

        child.cancel('Child cancelled');

        expect(child.isCancelled, isTrue);
        expect(parent.isCancelled, isFalse);
      });

      test('multiple children are all cancelled', () {
        final parent = CancelToken();
        final child1 = parent.createChild();
        final child2 = parent.createChild();
        final child3 = parent.createChild();

        parent.cancel();

        expect(child1.isCancelled, isTrue);
        expect(child2.isCancelled, isTrue);
        expect(child3.isCancelled, isTrue);
      });

      test('grandchildren are cancelled', () {
        final grandparent = CancelToken();
        final parent = grandparent.createChild();
        final child = parent.createChild();

        grandparent.cancel();

        expect(parent.isCancelled, isTrue);
        expect(child.isCancelled, isTrue);
      });
    });

    group('dispose()', () {
      test('closes the stream', () async {
        final token = CancelToken();
        var streamDone = false;

        token.onCancel.listen(
          (_) {},
          onDone: () => streamDone = true,
        );

        token.dispose();
        await Future.delayed(Duration.zero);

        expect(streamDone, isTrue);
      });

      test('clears children', () {
        final parent = CancelToken();
        final child = parent.createChild();

        parent.dispose();

        // Parent should not affect child after dispose
        // (children list is cleared)
        expect(child.isCancelled, isFalse);
      });
    });

    group('timeout factory', () {
      test('creates token that cancels after timeout', () async {
        final token = CancelToken.timeout(const Duration(milliseconds: 50));

        expect(token.isCancelled, isFalse);

        await Future.delayed(const Duration(milliseconds: 100));

        expect(token.isCancelled, isTrue);
        expect(token.cancelReason, contains('Timeout'));
      });

      test('can be cancelled before timeout', () async {
        final token = CancelToken.timeout(const Duration(seconds: 10));

        token.cancel('Manual cancel');

        expect(token.isCancelled, isTrue);
        expect(token.cancelReason, equals('Manual cancel'));
      });
    });

    group('fromFuture factory', () {
      test('cancels when future completes', () async {
        final completer = Completer<void>();
        final token = CancelToken.fromFuture(completer.future, 'Future done');

        expect(token.isCancelled, isFalse);

        completer.complete();
        await Future.delayed(Duration.zero);

        expect(token.isCancelled, isTrue);
        expect(token.cancelReason, equals('Future done'));
      });

      test('does not cancel if already cancelled', () async {
        final completer = Completer<void>();
        final token = CancelToken.fromFuture(completer.future, 'Future done');

        token.cancel('Manual cancel');

        completer.complete();
        await Future.delayed(Duration.zero);

        expect(token.cancelReason, equals('Manual cancel'));
      });
    });
  });

  group('CancelledException', () {
    test('has default message', () {
      const exception = CancelledException();
      expect(exception.message, equals('Operation was cancelled'));
    });

    test('accepts custom message', () {
      const exception = CancelledException('Custom cancellation');
      expect(exception.message, equals('Custom cancellation'));
    });

    test('toString returns formatted message', () {
      const exception = CancelledException('Test');
      expect(exception.toString(), equals('CancelledException: Test'));
    });
  });

  group('CancelTokenFutureExtension', () {
    test('withCancellation completes normally if not cancelled', () async {
      final token = CancelToken();
      final future = Future.delayed(
        const Duration(milliseconds: 50),
        () => 'result',
      );

      final result = await future.withCancellation(token);
      expect(result, equals('result'));
    });

    test('withCancellation throws if cancelled', () async {
      final token = CancelToken();
      final future = Future.delayed(
        const Duration(milliseconds: 100),
        () => 'result',
      );

      // Cancel after a short delay
      Future.delayed(const Duration(milliseconds: 20), () {
        token.cancel('Cancelled');
      });

      expect(
        () => future.withCancellation(token),
        throwsA(isA<CancelledException>()),
      );
    });

    test('withCancellation throws immediately if already cancelled', () async {
      final token = CancelToken();
      token.cancel('Already cancelled');

      final future = Future.delayed(
        const Duration(milliseconds: 100),
        () => 'result',
      );

      expect(
        () => future.withCancellation(token),
        throwsA(isA<CancelledException>()),
      );
    });

    test('withCancellation with null token just returns future', () async {
      final future = Future.value('result');
      final result = await future.withCancellation(null);
      expect(result, equals('result'));
    });
  });

  group('CancelTokenStreamExtension', () {
    test('withCancellation forwards events normally', () async {
      final token = CancelToken();
      final stream = Stream.fromIterable([1, 2, 3]);

      final results = await stream.withCancellation(token).toList();
      expect(results, equals([1, 2, 3]));
    });

    test('withCancellation closes stream on cancel', () async {
      final token = CancelToken();
      final controller = StreamController<int>();

      final results = <int>[];
      Object? error;

      controller.stream.withCancellation(token).listen(
            results.add,
            onError: (e) => error = e,
          );

      controller.add(1);
      controller.add(2);
      await Future.delayed(Duration.zero);

      token.cancel('Cancelled');
      await Future.delayed(Duration.zero);

      controller.add(3); // Should not be received
      await Future.delayed(Duration.zero);

      expect(results, equals([1, 2]));
      expect(error, isA<CancelledException>());

      await controller.close();
    });

    test('withCancellation with null token returns original stream', () async {
      final stream = Stream.fromIterable([1, 2, 3]);
      final results = await stream.withCancellation(null).toList();
      expect(results, equals([1, 2, 3]));
    });
  });
}
