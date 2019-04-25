import 'package:flutter_clean_architecture/src/observer.dart';
import 'package:rxdart/rxdart.dart';
import 'package:logging/logging.dart';
import 'dart:async';

/// The abstract [UseCase] to be implemented by all usecases.
/// [T] Is the type to be returned by the usecase to the presenter
/// [Params] Is the object passed to the usecase containing all the needed parameters
abstract class UseCase<T, Params> {
  /// This contains all the subscriptions to the [Observable]
  CompositeSubscription _disposables;
  Logger _logger;
  Logger get logger => _logger;

  UseCase() {
    _disposables = CompositeSubscription();
    _logger = Logger(this.runtimeType.toString());
  }

  /// Builds the [Observable] to be subscribed to. [Params] is required
  /// by the [UseCase] to retrieve the appropraite data from the repository
  Future<Observable<T>> buildUseCaseObservable(Params params);

  /// Subscribes to the [Observerable] with the [Observer] callback functions.
  void execute(Observer<T> observer, [Params params]) async {
    final StreamSubscription subscription =
        (await buildUseCaseObservable(params)).listen(observer.onNext,
            onDone: observer.onComplete, onError: observer.onError);
    _addSubscription(subscription);
  }

  /// Disposes (unsubscribes) from the [Observable]
  void dispose() {
    if (!_disposables.isDisposed) {
      _disposables.dispose();
    }
  }

  /// Adds a [StreamSubscription] i.e. the subscription to the
  /// [Observable] to the [CompositeSubscription] list of subscriptions.
  void _addSubscription(StreamSubscription subscription) {
    if (_disposables.isDisposed) {
      _disposables = CompositeSubscription();
    }
    _disposables.add(subscription);
  }
}

/// A special type of [UseCase] that does not return any value
abstract class CompletableUseCase<Params> extends UseCase<void, Params> {
  Future<Observable<void>> buildUseCaseObservable(Params params);
}
