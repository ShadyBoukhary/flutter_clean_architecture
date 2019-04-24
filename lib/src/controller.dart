import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

abstract class Controller with WidgetsBindingObserver, RouteAware {
  Function refresh; // callback function for refreshing the UI
  bool isLoading; // indicates whether a loading dialog is present
  bool _isMounted = true;
  Logger logger;
  GlobalKey<ScaffoldState> _scaffoldKey;
  Controller() {
    logger = Logger('${this.runtimeType}');
    isLoading = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
        onInActive();
        break;
      case AppLifecycleState.paused:
        onPaused();
        break;
      case AppLifecycleState.resumed:
        onResumed();
        break;
      case AppLifecycleState.suspending:
        onSuspending();
        break;
    }
  }

  /// Dismisses the loading dialog. The parent `View` of this [Controller] should have its body wrapped
  /// in the ModelHUD and is listening to the [Controller]'s [isLoading]. Otherwise, this method will
  /// have no impact.
  @protected
  void dismissLoading() {
    assert(refresh != null, 'Please set the Controller refresh function inside the View');
    if (_isMounted)
      refresh(() => isLoading = false);
  }

  /// Sets the loading to true. The `View` body should be wrapped in a loader.
  /// Call on initial page load. For example, if a loader is needed as soon as you open a page.
  /// Only works when called inside the [Controller] constructor.
  @protected
  void startLoading() {
    isLoading = true;
  }

  /// Sets the loading to true. The `View` body should be wrapped in a loader.
  /// Call when a loader is needed after an event (e.g. a button press).
  /// Does not work if called inside the [Controller] constructor.
  @protected
  void resumeLoading() {
    assert(refresh != null, 'Please set the Controller refresh function inside the View');
    refresh(() => isLoading = true);
  }

  /// Refreshes the [View] associated with the [Controller] if it is still mounted.
  @protected
  void refreshUI() {
    assert(refresh != null, 'Please set the Controller refresh function inside the View');
    if (_isMounted)
      refresh((){});
  }

  @mustCallSuper
  @visibleForOverriding
  void dispose() {
    _isMounted = false;
    logger.info('Disposing ${this.runtimeType}');
  }

  /// Retrieves the [ScaffoldState] associated with the [View]
  /// Should only be called if the [Controller] was given the [ScaffoldKey]
  /// by the [View]
  @protected
  ScaffoldState getScaffold() {
    assert(_scaffoldKey != null, 'ScaffoldKey must be passed to the Controller via initController() from the View before this can be called.');
    assert(_scaffoldKey.currentState != null, 'ScaffoldKey must be passed to the Controller via initController() from the View before this can be called.');
    return _scaffoldKey.currentState;
  }

  /// Retrieves the [GlobalKey<ScaffoldState>] associated with the [View]
  /// Should only be called if the [Controller] was given the [ScaffoldKey]
  /// by the [View]
  @protected
  GlobalKey<ScaffoldState> getScaffoldKey() {
    assert(_scaffoldKey != null, 'ScaffoldKey must be passed to the Controller via initController() from the View before this can be called.');
    return _scaffoldKey;
  }

  /// Initializes optional [Controller] variables that can be used for refreshing and error displaying.
  /// Must be called in order to be able to implement loading, refreshing, and error displaying e.g. [Snackbar].
  void initController(GlobalKey<ScaffoldState> key, Function refresh) {
    _scaffoldKey = key;
    this.refresh = refresh;
  }

  /// Retrieves the [BuildContext] associated with the `View`. Will throw an error if initController() was not called prior.
  @protected
  BuildContext getContext() {
    assert(_scaffoldKey != null, 'ScaffoldKey must be passed to the Controller via initController() from the View before this can be called.');
    assert(_scaffoldKey.currentContext != null, 'The `key` property of the Scaffold must be set to `scaffoldKey` in the `View`. ');
    return _scaffoldKey.currentContext;
  }

  void initListeners();
  void onInActive() {}
  void onPaused() {}
  void onResumed() {}
  void onSuspending() {}
}
