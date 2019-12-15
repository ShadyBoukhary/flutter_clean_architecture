import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import 'dart:isolate';
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:async';

// abstract class BackgroundObserver<T> extends Observer<T> {

// }

enum BackgroundUseCaseState { idle, loading, calculating }
typedef UseCaseTask = void Function(SendPort message);
class BackgroundUseCaseMessage<T> {
  T data;
  Error error;

  BackgroundUseCaseMessage({this.data, this.error});
}

abstract class BackgroundUseCase<T, Params> extends UseCase<T, Params> {
  BehaviorSubject<T> _subject;
  BackgroundUseCaseState _state = BackgroundUseCaseState.idle;
  Isolate _isolate;
  final ReceivePort _receivePort;

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
      _subject.listen(observer.onNext, onError: observer.onError, onDone: observer.onComplete);
      _run = buildUseCaseTask(params);
      _run = hi;
      _isolate = await Isolate.spawn<SendPort>(_run, _receivePort.sendPort);
      if (!isRunning) {
        _isolate.kill(priority: Isolate.immediate);
      } else {
        _state = BackgroundUseCaseState.calculating;
      }
    }
  }

  @override
  Future<Observable<T>> buildUseCaseObservable(Params params) async {  }


  UseCaseTask buildUseCaseTask(Params params) {
    return (SendPort port) {
      print(1);
      BackgroundUseCaseMessage<T> message = BackgroundUseCaseMessage();
      port.send(message);
    };
  }

  static void hi(SendPort port) {

  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
  void stop() {
    if (isRunning) {
      _state = BackgroundUseCaseState.idle;
      if (_isolate != null) {
        _isolate.kill(priority: Isolate.immediate);
        _isolate = null;
        // TODO: add any more
      }
    }
  }
  static UseCaseTask _run;

  // static void _run(BackgroundUseCaseMessage message) {
  //   // final SendPort sender = message.sendPort;
  //   // Observable obs = message.obs;
  //   // Observer observer = message.observer;
  //   // final StreamSubscription subscription = obs.listen(observer.onNext,
  //   //     onDone: observer.onComplete, onError: observer.onError);
  //   // sender.send(subscription);
  // }

  void _handleMessage(dynamic message) {
    assert(message is BackgroundUseCaseMessage);
    var msg = message as BackgroundUseCaseMessage;
    print("Received");
    if (msg.data != null) {
      assert(msg.data is T);
      _subject.add(msg.data);
    } else if (msg.error != null) {
      _subject.addError(msg.error);
    } else {
      // TODO: warning
    }


  }
}
