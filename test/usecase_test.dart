import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Domain modules', () {
    test('UseCase onNext and onDone.', () async {
      var observer = CounterUseCaseObserver();
      CounterUseCase().execute(observer);
      await Future.delayed(Duration(milliseconds: 1000), () {
        expect(observer.number, 2);
        expect(observer.done, true);
        expect(observer.error, false);
      });
    });

    test('UseCase .OnError.', () async {
      var observer = CounterUseCaseObserver();
      CounterUseCaseError().execute(observer);
      await Future.delayed(Duration(milliseconds: 1000), () {
        expect(observer.number, -1);
        expect(observer.done, true);
        expect(observer.error, true);
      });
    });

    test('UseCase .dispose cancels the subscription', () async {
      var observer = CounterUseCaseObserver();
      var usecase = CounterUseCase()..execute(observer);
      await Future.delayed(Duration(milliseconds: 15), () {
        usecase.dispose();
        expect(observer.number, 0);
        expect(observer.done, false);
        expect(observer.error, false);
      });
    });
  });
}

class CounterUseCase extends UseCase<int, void> {
  @override
  Future<Stream<int>> buildUseCaseStream(void params) async {
    return Stream.periodic(Duration(milliseconds: 10), (i) => i).take(3);
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
