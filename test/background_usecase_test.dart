import 'package:test/test.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';

void main() {
  group('BackgroundUseCase', () {
    test('BackgroundUseCase onNext and onDone.', () async {
      CounterUseCaseObserver observer = CounterUseCaseObserver();
      CounterUseCase().execute(observer);
      await Future.delayed(Duration(milliseconds: 200));
      expect(observer.number, 2);
      expect(observer.done, true);
      expect(observer.error, false);
    });

    test('BackgroundUseCase .OnError.', () async {
      CounterUseCaseObserver observer = CounterUseCaseObserver();
      CounterUseCaseError().execute(observer);
      await Future.delayed(Duration(milliseconds: 500));
      expect(observer.number, -1);
      expect(observer.done, true);
      expect(observer.error, true);
    });

    test('BackgroundUseCase .dispose cancels the background usecase', () async {
      CounterUseCaseObserver observer = CounterUseCaseObserver();
      CounterUseCaseCancelled usecase = CounterUseCaseCancelled()
        ..execute(observer);
      await Future.delayed(Duration(milliseconds: 100));
      usecase.dispose();
      await Future.delayed(Duration(milliseconds: 40));
      expect(observer.number, 0);
      expect(observer.done, false);
      expect(observer.error, false);
    });

    test('BackgroundUseCase matmul', () async {
      MatMulUseCaseObserver observer = MatMulUseCaseObserver();
      MatMulUseCase()..execute(observer, MatMulUseCaseParams.random());
      await Future.delayed(Duration(milliseconds: 400));

    });
  });
}

class CounterUseCase extends BackgroundUseCase<int, void> {
  @override
  buildUseCaseTask(void params) {
    return hi;
  }

  static hi(BackgroundUseCaseParams params) {
    for (int i = 0; i < 3; i++) {
      BackgroundUseCaseMessage<int> message = BackgroundUseCaseMessage(data: i);
      params.port.send(message);
    }
    BackgroundUseCaseMessage<int> message =
        BackgroundUseCaseMessage(done: true);
    params.port.send(message);
  }
}

class CounterUseCaseError extends BackgroundUseCase<int, void> {
  @override
  buildUseCaseTask(void params) {
    return hi;
  }

  static hi(BackgroundUseCaseParams params) {
    BackgroundUseCaseMessage<int> message =
        BackgroundUseCaseMessage(error: Error());

    params.port.send(message);
  }
}

class CounterUseCaseCancelled extends BackgroundUseCase<int, void> {
  @override
  buildUseCaseTask(void params) {
    return hi;
  }

  static hi(BackgroundUseCaseParams params) async {
    BackgroundUseCaseMessage<int> message = BackgroundUseCaseMessage(data: 0);
    params.port.send(message);
    await Future.delayed(Duration(seconds: 1));
    message = BackgroundUseCaseMessage(error: Error());
    params.port.send(message);
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

class MatMulUseCase extends BackgroundUseCase<List<List<double>>, MatMulUseCaseParams> {
  @override
  buildUseCaseTask(void params) {
    return matmul;
  }

  static void matmul(BackgroundUseCaseParams params) async {
    MatMulUseCaseParams matMulParams = params.params as MatMulUseCaseParams;
    List<List<double>> result = List<List<double>>.generate(
        10, (i) => List<double>.generate(10, (j) => 0));

    for (int i = 0; i < matMulParams.mat1.length; i++) {
      for (int j = 0; j < matMulParams.mat1.length; j++) {
        for (int k = 0; k < matMulParams.mat1.length; k++) {
          result[i][j] += matMulParams.mat1[i][k] * matMulParams.mat2[k][i];
        }
      }
    }
    params.port.send(BackgroundUseCaseMessage(data: result));

  }
}

class MatMulUseCaseParams {
  List<List<double>> mat1;
  List<List<double>> mat2;
  MatMulUseCaseParams(this.mat1, this.mat2);
  MatMulUseCaseParams.random() {
    var size = 10;
    mat1 = List<List<double>>.generate(size,
        (i) => List<double>.generate(size, (j) => i.toDouble() * size + j));

    mat2 = List<List<double>>.generate(size,
        (i) => List<double>.generate(size, (j) => i.toDouble() * size + j));
  }
}

class MatMulUseCaseObserver extends Observer<List<List<double>>> {

  @override
  void onComplete() {
  }

  @override
  void onError(e) {
  }

  @override
  void onNext(List<List<double>> mat) {
    expect(mat.first.first, 2850.0);
    expect(mat.last.last, 51855.0);
  }
}
