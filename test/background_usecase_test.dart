import 'package:test/test.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import 'package:rxdart/src/observables/observable.dart';

void main() {
  group('Domain modules', () {
    test('UseCase onNext and onDone.', () async {
      CounterUseCaseObserver observer = CounterUseCaseObserver();
      CounterUseCase().execute(observer);
      await Future.delayed(Duration(milliseconds: 1000), () {
        expect(observer.number, 2);
        expect(observer.done, true);
        expect(observer.error, false);
      });
    });

    test('UseCase .OnError.', () async {
      CounterUseCaseObserver observer = CounterUseCaseObserver();
      CounterUseCaseError().execute(observer);
      await Future.delayed(Duration(milliseconds: 1000), () {
        expect(observer.number, -1);
        expect(observer.done, true);
        expect(observer.error, true);
      });
    });

    test('UseCase .dispose cancels the subscription', () async {
      CounterUseCaseObserver observer = CounterUseCaseObserver();
      CounterUseCase usecase = CounterUseCase()
      ..execute(observer);
      await Future.delayed(Duration(milliseconds: 15), () {
        usecase.dispose();
        expect(observer.number, 0);
        expect(observer.done, false);
        expect(observer.error, false);
      });
    });
  });
}

class CounterUseCase extends BackgroundUseCase<int, void> {
  @override
  Future<Observable<int>> buildUseCaseObservable(void params) async {
    return Observable.periodic(Duration(milliseconds: 10), (i) => i).take(3);
  }
}

class CounterUseCaseError extends BackgroundUseCase<int, void> {
  @override
  Future<Observable<int>> buildUseCaseObservable(void params) async {
    return Observable.error(Error());
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
  void onNext(int number) {
    this.number++;
    expect(number, this.number);
  }
}
