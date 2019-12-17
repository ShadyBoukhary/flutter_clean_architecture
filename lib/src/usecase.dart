import 'package:flutter_clean_architecture/src/observer.dart';
import 'package:rxdart/rxdart.dart';
import 'package:logging/logging.dart';
import 'dart:async';

/// The abstract [UseCase] to be implemented by all usecases.
/// [T] Is the type to be returned by the [UseCase] to the [Presenter]
/// [Params] Is the object passed to the usecase containing all the needed parameters
/// for the [UseCase]
///
/// The [UseCase] represents a business-level process. It should be written purely
/// in `Dart` and `MUST NOT` include any `Flutter` code whatsoever. The `UseCase` is a part
/// of the `Domain` module of the application in the `Clean Architecture`.
///
/// Dependencies used by the [UseCase] must be injected by the [Presenter]. The [UseCase]
/// is essentially an `Observable` managing class. When the [execute()] function is triggered
/// by the [UseCase], an `Observable` is built using the `buildUseCaseObservable()` method, subscribed to
/// by the [Observer] passed, and passed any required [params]. The [StreamSubscription] is then added
/// to a [CompositeSubscription]. This is later disposed when `dispose()` is called.
///
/// When extended, the extending class should override [buildUseCaseObservable()], where the behavior and functionality
/// of the [UseCase] are defined. This method will return the `Observable` to be subscribed to, and will fire events to
/// the `Observer` in the [Presenter].
///
/// Get a list of `User` example:
///
/// ```dart
///   // In this case, no parameters were needed. Hence, void. Otherwise, change to appropriate.
///   // Typically, a GetUsersUseCaseParams class is defined and wrapped around the parameters
///   class GetUsersUseCase extends UseCase<List<User>, void> {
///     final UsersRepository _usersRepository; // some dependency to be injected
///                                             // the functionality is hidden behind this
///                                             // abstract class defined in the Domain module
///                                             // It should be implemented inside the Data or Device
///                                             // module and passed polymorphically.
///
///     GetUsersUseCase(this._usersRepository);
///
///     @override
///     // Since the parameter type is void, `_` ignores the parameter. Change according to the type
///     // used in the template.
///     Future<Observable<GetSponsorsUseCaseResponse>> buildUseCaseObservable(_) async {
///       final StreamController<GetSponsorsUseCaseResponse> controller = StreamController();
///       try {
///         // get users
///         List<User> users = await _usersRepository.getAllUsers();
///         // Adding it triggers the .onNext() in the `Observer`
///         // It is usually better to wrap the reponse inside a respose object.
///         controller.add(users);
///         logger.finest('GetUsersUseCase successful.');
///         controller.close();
///       } catch (e) {
///         print(e);
///         logger.severe('GetUsersUseCase unsuccessful.');
///         // Trigger .onError
///         controller.addError(e);
///       }
///       return Observable(controller.stream);
///     }
///   }
///
/// ```
///
/// The dependencies injected into the [UseCase] `MUST` be in the form of `abstract` classes only, in order
/// to act as interfaces. These `abstract` classes are known as `Repositories`. The [UseCase] `MUST NOT` accept
/// anything as a dependency in the form of a class that contains any implemented code according to the `Clean Architecture`.
///
/// The `abstract` repositories are defined in the `Domain` module and implemented in either `Device` or `Data` modules.
/// They are then injected polymorphically into the [UseCase]. The repositories should be injected inwards from the
/// outermost layer `View -> Controller -> Presenter -> UseCase`.
///
/// For example, the below is a an `abstract` repository defined in the `Domain` module.
/// ```dart
///
///   abstract class AuthenticationRepository {
///     Future<void> register(
///         {@required String firstName,
///         @required String lastName,
///         @required String email,
///         @required String password});
///
///     /// Authenticates a user using his [username] and [password]
///     Future<void> authenticate(
///         {@required String email, @required String password});
///
///     /// Returns whether the [User] is authenticated.
///     Future<bool> isAuthenticated();
///
///     /// Returns the current authenticated [User].
///     Future<User> getCurrentUser();
///
///     /// Resets the password of a [User]
///     Future<void> forgotPassword(String email);
///
///     /// Logs out the [User]
///     Future<void> logout();
///   }
/// ```
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

/// A special type of [UseCase] that does not return any value.
/// This [UseCase] only performs a task and reports either success or failure.
/// A good candidate for such a [UseCase] would be logout or login.
/// ```dart
///     // A `UseCase` for logging out a `User`
///     class LogoutUseCase extends CompletableUseCase<void> {
///
///       AuthenticationRepository _authenticationRepository;///
///       LogoutUseCase(this._authenticationRepository);
///
///       @override
///       Future<Observable<User>> buildUseCaseObservable(void ignore) async {
///         final StreamController<User> controller = StreamController();
///         try {
///           await _authenticationRepository.logout();
///           controller.close();
///         } catch (e) {
///           controller.addError(e);
///         }
///         return Observable(controller.stream);
///       }
///     }
///
/// ```
abstract class CompletableUseCase<Params> extends UseCase<void, Params> {
  Future<Observable<void>> buildUseCaseObservable(Params params);
}
