/// An [Observer] used by the [Presenter] to subscribe to a [UseCase]. Ideally, it would
/// be implemented as an inner class inside the [Presenter]. But, until Dart supports inner classes,
/// this is a workaround.
/// ```dart
///     /// The [Observer] used to observe the `Observable` of the [LoginUseCase]
///     class LoginUseCaseObserver implements Observer<void> {
///
///       // The above presenter
///       // This is not optimal, but it is a workaround due to dart limitations. Dart does
///       // not support inner classes or anonymous classes.
///       final LoginPresenter loginPresenter;
///
///       LoginUseCaseObserver(this.loginPresenter);
///
///       /// implement if the `Observable` emits a value
///       // in this case, unnecessary
///       void onNext(_) {}
///
///       /// Login is successfull, trigger event in [LoginController]
///       void onComplete() {
///         // any cleaning or preparation goes here
///         assert(loginPresenter.loginOnComplete != null);
///         loginPresenter.loginOnComplete();
///       }
///
///       /// Login was unsuccessful, trigger event in [LoginController]
///       void onError(e) {
///         // any cleaning or preparation goes here
///         assert(loginPresenter.loginOnError != null);
///         loginPresenter.loginOnError(e);
///       }
/// ```
///
/// An example where data is retrieved from the [UseCase]:
/// ```dart
///     class GetUsersUseCaseObserver implements Observer<void> {
///
///       // The above presenter
///       // This is not optimal, but it is a workaround due to dart limitations. Dart does
///       // not support inner classes or anonymous classes.
///       final UsersPresenter usersPresenter;
///
///       GetUsersUseCaseObserver(this.usersPresenter);
///
///       /// implement if the `Observable` emits a value
///       // in this case, unnecessary
///       // The parameter depends on what the [UseCase] emits. It could be a list or
///       // one `User` at a time
///       void onNext(List<User> users) {
///         // Any sorting, mapping, filtering of the data goes in here
///         assert(usersPresenter.getUsersOnNext != null);
///         usersPresenter.getUsersOnNext(users);
///       }
///
///       /// Login is successfull, trigger event in [LoginController]
///       void onComplete() {
///         // any cleaning or preparation goes here
///         assert(usersPresenter.getUsersOnComplete != null);
///         usersPresenter.getUsersOnComplete();
///       }
///
///       /// [UseCase] emitted an error
///       void onError(e) {
///         assert(usersPresenter.getUsersOnError != null);
///         usersPresenter.getUsersOnError(e);
///       }
/// ```
abstract class Observer<T> {
  void onNext(T? response);
  void onComplete();
  void onError(e);
}
