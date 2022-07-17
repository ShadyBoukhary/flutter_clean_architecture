import 'package:flutter/foundation.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import 'dart:isolate';
import 'package:rxdart/rxdart.dart';
import 'dart:async';

enum BackgroundUseCaseState { idle, loading, calculating }

typedef UseCaseTask = void Function(
    BackgroundUseCaseParams backgroundUseCaseParams);

/// Data structure sent from the isolate back to the main isolate
class BackgroundUseCaseMessage<T> {
  T? data;
  Error? error;
  bool? done;
  BackgroundUseCaseMessage({this.data, this.error, this.done = false});
}

/// Data structure sent from the main isolate to the other isolate
class BackgroundUseCaseParams<T> {
  T? params;
  SendPort port;
  BackgroundUseCaseParams(this.port, {this.params});
}

/// A specialized type of [UseCase] that executes on a different isolate.
/// The purpose is identical to [UseCase], except that this runs on a different isolate.
/// A [BackgroundUseCase] is useful when performing expensive operations that ideally
/// should not be performed on the main isolate.
///
/// The code that is to be run on a different isolate can be provided through a
/// static method of the usecase. Then, a reference of that method should be returned
/// by overriding the [buildUseCaseTask] as shown below. Input data for the isolate
/// is provided by inside the `params` variable in [BackgroundUseCaseParams], which is
/// passed to the static method of type [UseCaseTask].
///
/// Output data can be passed back to the main isolate through `port.send()` provided
/// in the `port` member of [BackgroundUseCaseParams]. Any and all output should be
/// wrapped inside a [BackgroundUseCaseMessage]. Data can be passed by specifying the
/// `data` parameter, while errors can be reported through the `error` parameter.
///
/// In addition, a `done` flag can be set to indicate that the isolate has completed its task.
///
/// An example would be a usecase that performs matrix multiplication.
/// ```dart
/// class MatMulUseCase extends BackgroundUseCase<List<List<double>>, MatMulUseCaseParams> {
///  @override
///  buildUseCaseTask() {
///    return matmul;
///  }
///
///  static void matmul(BackgroundUseCaseParams params) async {
///    MatMulUseCaseParams matMulParams = params.params as MatMulUseCaseParams;
///    List<List<double>> result = List<List<double>>.generate(
///        10, (i) => List<double>.generate(10, (j) => 0));
///
///    for (int i = 0; i < matMulParams.mat1.length; i++) {
///      for (int j = 0; j < matMulParams.mat1.length; j++) {
///        for (int k = 0; k < matMulParams.mat1.length; k++) {
///          result[i][j] += matMulParams.mat1[i][k] * matMulParams.mat2[k][j];
///        }
///      }
///    }
///    params.port.send(BackgroundUseCaseMessage(data: result));
///
///  }
///}
///
/// ```
/// Just like a regular [UseCase], a parameter class is recommended for any [BackgroundUseCase].
/// An example corresponding to the above example would be
/// ```dart
/// class MatMulUseCaseParams {
///  List<List<double>> mat1;
///  List<List<double>> mat2;
///  MatMulUseCaseParams(this.mat1, this.mat2);
///  MatMulUseCaseParams.random() {
///    var size = 10;
///    mat1 = List<List<double>>.generate(size,
///        (i) => List<double>.generate(size, (j) => i.toDouble() * size + j));
///
///    mat2 = List<List<double>>.generate(size,
///        (i) => List<double>.generate(size, (j) => i.toDouble() * size + j));
///  }
///}
/// ```
abstract class BackgroundUseCase<T, Params> extends UseCase<T, Params> {
  BackgroundUseCaseState _state = BackgroundUseCaseState.idle;
  late Isolate? _isolate;
  final BehaviorSubject<T> _subject;
  final ReceivePort _receivePort;
  static late UseCaseTask _run;

  BackgroundUseCase()
      : assert(!kIsWeb, '''
        [BackgroundUseCase] is not supported on web due to dart:isolate limitations.
      '''),
        _receivePort = ReceivePort(),
        _subject = BehaviorSubject(),
        super() {
    _receivePort.listen(_handleMessage);
  }

  BackgroundUseCaseState get state => _state;
  bool get isRunning => _state != BackgroundUseCaseState.idle;

  /// Executes the usecase on a different isolate. Spawns [_isolate]
  /// using the static method provided by [buildUseCaseTask] and listens
  /// to a [BehaviorSubject] using the [observer] provided by the user.
  /// All [Params] are sent to the [_isolate] through [BackgroundUseCaseParams].
  @override
  void execute(Observer<T> observer, [Params? params]) async {
    if (!isRunning) {
      _state = BackgroundUseCaseState.loading;
      _subject.listen(observer.onNext,
          onError: observer.onError, onDone: observer.onComplete);
      _run = buildUseCaseTask();
      Isolate.spawn<BackgroundUseCaseParams>(_run,
              BackgroundUseCaseParams(_receivePort.sendPort, params: params))
          .then<void>((Isolate isolate) {
        if (!isRunning) {
          logger.info('Killing background isolate.');
          isolate.kill(priority: Isolate.immediate);
        } else {
          _state = BackgroundUseCaseState.calculating;
          _isolate = isolate;
        }
      });
    }
  }

  @override
  @nonVirtual
  Future<Stream<T?>> buildUseCaseStream(_) => Future.value(null);

  /// Provides a [UseCaseTask] to be executed on a different isolate.
  /// Must be overridden.
  UseCaseTask buildUseCaseTask();

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  /// Kills the [_isolate] if it is running.
  void _stop() {
    if (isRunning) {
      _state = BackgroundUseCaseState.idle;
      if (_isolate != null) {
        logger.info('Killing background isolate.');
        _isolate!.kill(priority: Isolate.immediate);
        _isolate = null;
      }
    }
  }

  /// Handles [BackgroundUseCaseMessage]s sent from the [_isolate].
  /// The message could either be data or an error. Data and errors are forwarded to
  /// the observer to be handled by the user.
  void _handleMessage(dynamic message) {
    assert(message is BackgroundUseCaseMessage,
        '''All data and errors sent from the isolate in the static method provided by the user must be
    wrapped inside a `BackgroundUseCaseMessage` object.''');
    var msg = message as BackgroundUseCaseMessage;
    if (msg.data != null) {
      assert(msg.data is T);
      _subject.add(msg.data);
    } else if (msg.error != null) {
      _subject.addError(msg.error!);
      _subject.close();
    }

    if (msg.done!) {
      _subject.close();
    }
  }
}
