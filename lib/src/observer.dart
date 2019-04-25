abstract class Observer<T> {
  void onNext(T response);
  void onComplete();
  void onError(e);
}