import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Domain modules', () {
    test('UseCase onNext and onDone.', () async {
      var observer = CounterUseCaseObserver();
      CounterUseCase().execute(observer);
      await Future.delayed(const Duration(milliseconds: 1000), () {
        expect(observer.number, 2);
        expect(observer.done, true);
        expect(observer.error, false);
      });
    });

    test('UseCase .OnError.', () async {
      var observer = CounterUseCaseObserver();
      CounterUseCaseError().execute(observer);
      await Future.delayed(const Duration(milliseconds: 1000), () {
        expect(observer.number, -1);
        expect(observer.done, true);
        expect(observer.error, true);
      });
    });

    test('UseCase .dispose cancels the subscription', () async {
      var observer = CounterUseCaseObserver();
      var usecase = CounterUseCase()..execute(observer);
      await Future.delayed(const Duration(milliseconds: 15), () {
        usecase.dispose();
        expect(observer.number, 0);
        expect(observer.done, false);
        expect(observer.error, false);
      });
    });

    test('FutureUseCase onNext and onDone.', () async {
      var observer = FutureUseCaseObserver();
      await SuccessFutureUseCase().execute(observer);
      expect(observer.value, 42);
      expect(observer.done, true);
      expect(observer.error, false);
    });

    test('FutureUseCase .onError.', () async {
      var observer = FutureUseCaseObserver();
      await ErrorFutureUseCase().execute(observer);
      expect(observer.value, null);
      expect(observer.done, false);
      expect(observer.error, true);
    });
  });
}

class CounterUseCase extends UseCase<int, void> {
  @override
  Future<Stream<int>> buildUseCaseStream(void params) async {
    return Stream.periodic(const Duration(milliseconds: 10), (i) => i).take(3);
  }
}

class CounterUseCaseError extends UseCase<int, void> {
  @override
  Future<Stream<int>> buildUseCaseStream(void params) async {
    return Stream.error(Error());
  }
}

class CounterUseCaseObserver extends Observer<int> {
  int number = -1;
  bool done = false;
  bool error = false;
  @override
  void onComplete() {
    done = true;
  }

  @override
  void onError(e) {
    error = true;
  }

  @override
  void onNext(int? number) {
    this.number++;
    expect(number, this.number);
  }
}

class SuccessFutureUseCase extends FutureUseCase<int, void> {
  @override
  Future<int> buildUseCaseFuture(void params) async {
    return 42;
  }
}

class ErrorFutureUseCase extends FutureUseCase<int, void> {
  @override
  Future<int> buildUseCaseFuture(void params) async {
    throw Error();
  }
}

class FutureUseCaseObserver extends Observer<int> {
  int? value;
  bool done = false;
  bool error = false;

  @override
  void onComplete() {
    done = true;
  }

  @override
  void onError(e) {
    error = true;
  }

  @override
  void onNext(int? response) {
    value = response;
  }
}
