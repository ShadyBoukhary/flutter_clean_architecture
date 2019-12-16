import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import 'dart:isolate';
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:async';

enum BackgroundUseCaseState { idle, loading, calculating }
typedef UseCaseTask = void Function(BackgroundUseCaseParams message);

class BackgroundUseCaseMessage<T> {
  T data;
  Error error;
  bool done;
  BackgroundUseCaseMessage({this.data, this.error, this.done = false});
}

class BackgroundUseCaseParams<T> {
  T params;
  SendPort port;
  BackgroundUseCaseParams(this.port, {this.params});
}

abstract class BackgroundUseCase<T, Params> extends UseCase<T, Params> {
  BehaviorSubject<T> _subject;
  BackgroundUseCaseState _state = BackgroundUseCaseState.idle;
  Isolate _isolate;
  final ReceivePort _receivePort;
  static UseCaseTask _run;

  BackgroundUseCase()
      : _receivePort = ReceivePort(),
        _subject = BehaviorSubject(),
        super() {
    _receivePort.listen(_handleMessage);
  }

  BackgroundUseCaseState get state => _state;
  bool get isRunning => _state != BackgroundUseCaseState.idle;

  /// Subscribes to the [Observerable] with the [Observer] callback functions.
  @override
  void execute(Observer<T> observer, [Params params]) async {
    if (!isRunning) {
      _state = BackgroundUseCaseState.loading;
      _subject.listen(observer.onNext,
          onError: observer.onError, onDone: observer.onComplete);
      _run = buildUseCaseTask(params);
      Isolate.spawn<BackgroundUseCaseParams>(_run, BackgroundUseCaseParams(_receivePort.sendPort, params: params))
          .then<void>((Isolate isolate) {
        if (!isRunning) {
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
  Future<Observable<T>> buildUseCaseObservable(Params params) {
    return null;
  }

  UseCaseTask buildUseCaseTask(Params params);

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  void _stop() {
    if (isRunning) {
      _state = BackgroundUseCaseState.idle;
      if (_isolate != null) {
        _isolate.kill(priority: Isolate.immediate);
        _isolate = null;
      }
    }
  }

  void _handleMessage(dynamic message) {
    assert(message is BackgroundUseCaseMessage);
    var msg = message as BackgroundUseCaseMessage;
    if (msg.data != null) {
      assert(msg.data is T);
      _subject.add(msg.data);
    } else if (msg.error != null) {
      _subject.addError(msg.error);
      _subject.close();
    }

    if (msg.done) {
      _subject.close();
    }
  }
}
