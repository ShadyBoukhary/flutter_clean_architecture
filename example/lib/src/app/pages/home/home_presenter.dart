import '../../../domain/usecases/get_user_usecase.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart' as clean;

class HomePresenter extends clean.Presenter {
  Function? getUserOnNext;
  Function? getUserOnComplete;
  Function? getUserOnError;

  final GetUserUseCase getUserUseCase;
  HomePresenter(usersRepo) : getUserUseCase = GetUserUseCase(usersRepo);

  void getUser(String uid) {
    // execute getUseruserCase
    getUserUseCase.execute(
        _GetUserUseCaseObserver(this), GetUserUseCaseParams(uid));
  }

  @override
  void dispose() {
    getUserUseCase.dispose();
  }
}

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
