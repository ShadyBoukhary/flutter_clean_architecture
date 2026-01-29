import '../../../domain/usecases/get_user_future_usecase.dart';
import '../../../domain/usecases/get_user_usecase.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart'
    as clean;

class HomePresenter extends clean.Presenter {
  Function? getUserOnNext;
  Function? getUserOnComplete;
  Function? getUserOnError;
  Function? getUserFutureOnNext;
  Function? getUserFutureOnComplete;
  Function? getUserFutureOnError;

  final GetUserUseCase getUserUseCase;
  final GetUserFutureUseCase getUserFutureUseCase;
  HomePresenter(usersRepo)
      : getUserUseCase = GetUserUseCase(usersRepo),
        getUserFutureUseCase = GetUserFutureUseCase(usersRepo);

  void getUser(String uid) {
    // execute getUseruserCase
    getUserUseCase.execute(
        _GetUserUseCaseObserver(this), GetUserUseCaseParams(uid));
  }

  void getUserFuture(String uid) {
    getUserFutureUseCase.execute(
        clean.Observer.fromCallbacks(
          onNext: (response) => getUserFutureOnNext?.call(response?.user),
          onComplete: () => getUserFutureOnComplete?.call(),
          onError: (e) => getUserFutureOnError?.call(e),
        ),
        GetUserFutureUseCaseParams(uid));
  }

  @override
  void dispose() {
    getUserUseCase.dispose();
  }
}

// alternative way to implement Observer
class _GetUserUseCaseObserver extends clean.Observer<GetUserUseCaseResponse> {
  final HomePresenter presenter;
  _GetUserUseCaseObserver(this.presenter);
  @override
  void onComplete() {
    presenter.getUserOnComplete?.call();
  }

  @override
  void onError(e) {
    presenter.getUserOnError?.call(e);
  }

  @override
  void onNext(response) {
    presenter.getUserOnNext?.call(response?.user);
  }
}
