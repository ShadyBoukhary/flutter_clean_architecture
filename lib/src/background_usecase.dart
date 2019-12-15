import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import 'dart:isolate';
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:async';

// abstract class BackgroundObserver<T> extends Observer<T> {

// }

enum BackgroundUseCaseState { idle, loading, calculating }

class BackgroundUseCaseMessage<T> {
  Observable<T> obs;
  SendPort sendPort;
  Observer<T> observer;
  BackgroundUseCaseMessage(this.obs, this.sendPort, this.observer);
}

abstract class BackgroundUseCase<T, Params> extends UseCase<T, Params> {
  BackgroundUseCaseState _state = BackgroundUseCaseState.idle;
  Isolate _isolate;
  final ReceivePort _receivePort;

  BackgroundUseCase()
      : _receivePort = ReceivePort(),
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
      Observable<T> obs = await buildUseCaseObservable(params);

      BackgroundUseCaseMessage<T> message = BackgroundUseCaseMessage(
          obs, _receivePort.sendPort, observer);
      a = b;

      _isolate = await Isolate.spawn<BackgroundUseCaseMessage>(_run, null);
      if (!isRunning) {
        _isolate.kill(priority: Isolate.immediate);
      } else {
        _state = BackgroundUseCaseState.calculating;
      }
    }
  }
  static Function a;
  void b() {print(1);}
  @override
  void dispose() {
    stop();
    super.dispose();
  }
  void stop() {
    if (isRunning) {
      _state = BackgroundUseCaseState.idle;
      dispose();
      if (_isolate != null) {
        _isolate.kill(priority: Isolate.immediate);
        _isolate = null;
        // TODO: add any more
      }
    }
  }

  static void _run(BackgroundUseCaseMessage message) {
    a();
    // final SendPort sender = message.sendPort;
    // Observable obs = message.obs;
    // Observer observer = message.observer;
    // final StreamSubscription subscription = obs.listen(observer.onNext,
    //     onDone: observer.onComplete, onError: observer.onError);
    // sender.send(subscription);
  }

  void _handleMessage(dynamic subscription) {
    StreamSubscription sub = subscription as StreamSubscription;
    addSubscription(sub);

  }
}
