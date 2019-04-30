/// A [Presenter] prepares data for the [Controller], listens to [UseCase], and
/// handles its creation and distruction. A [Presenter] should be aggregated inside
/// a [Controller]. Its dependencies are also provided by the [Controller]. Once the 
/// [Controller] is disposed, it should also call [dispose()] of the [Presenter] in order
/// to dispose of the [UseCase]. The [Presenter] utilizes an [Observer] to listen to the 
/// [UseCase]. However, it is a separate class since Dart does not yet support inner 
/// or anonymous classes.
/// ```dart
/// 
///     LoginPresenter() {
/// 
///       Function loginOnComplete; // alternatively `void loginOnComplete();`
///       Function loginOnError;
///       Function loginOnNext; // not needed in the case of a login presenter
/// 
///       final LoginUseCase loginUseCase;
///       // dependency injection from controller
///       LoginPresenter(authenticationRepo): loginUseCase = LoginUseCase(authenticationRepo);
/// 
///       /// login function called by the controller
///       void login(String email, String password) {
///         loginUseCase.execute(_LoginUseCaseObserver(this), LoginUseCaseParams(email, password));
///       }
/// 
///        /// Disposes of the [LoginUseCase] and unsubscribes
///        @override
///        void dispose() {
///          _loginUseCase.dispose();
///        }
///     }
/// 
///     /// The [Observer] used to observe the `Observable` of the [LoginUseCase]
///     class _LoginUseCaseObserver implements Observer<void> {
///     
///       // The above presenter
///       // This is not optimal, but it is a workaround due to dart limitations. Dart does
///       // not support inner classes or anonymous classes.
///       final LoginPresenter loginPresenter;
///     
///       _LoginUseCaseObserver(this.loginPresenter);
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
///     
///       }
///     
///       /// Login was unsuccessful, trigger event in [LoginController]
///       void onError(e) {
///         // any cleaning or preparation goes here
///         assert(loginPresenter.loginOnError != null);
///         loginPresenter.loginOnError(e);
///       }
///     }
/// 
/// 
/// ```
abstract class Presenter {
  void dispose();
}