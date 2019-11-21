import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

/// A Clean Architecture [Controller]. Should be aggregated within a `ViewState` or
/// a `View`. However, it is preferable to be contained inside the `View` for readibility
/// and maintainability.
///
/// The [Controller] hadnles the events triggered by the `View`. For example, it handles
/// the click events of buttons, lifecycle, data-sourcing, etc...
///
/// The [Controller] is also route aware. However, in order to use it,
/// it has to be initialzied separately.
///
/// Usage of a [Controller]:
///
/// ```dart
///     // ***************** Controller *****************
///     class CounterController extends Controller {
///       int counter;
///       final MyPresenter presenter;
///       CounterController() : counter = 0, presenter = MyPresenter(), super();
///
///       void increment() {
///         counter++;
///       }
///
///       /// Shows a snackbar
///       void showSnackBar() {
///         ScaffoldState scaffoldState = getState(); // get the state, in this case, the scaffold
///         scaffoldState.showSnackBar(SnackBar(content: Text('Hi')));
///       }
///
///       @override
///       void initListeners() {
///         // Initialize presenter listeners here
///         // e.g. presenter.loginOnComplete = () => print('Login Successful);
///         // see [initListeners]
///       }
///     }
///
///     // ***************** View *****************
///     class CounterPage extends View {
///       @override
///       // you can inject dependencies for the controller and the state in here
///       State<StatefulWidget> createState() => CounterState(CounterController());
///     }
///
///     // ***************** ViewState *****************
///     class CounterState extends ViewState<CounterPage, CounterController> {
///       CounterState(CounterController controller) : super(controller);
///
///       @override
///       Widget build(BuildContext context) {
///         return MaterialApp(
///           title: 'Flutter Demo',
///           home: Scaffold(
///             key: globalKey, // using the built-in global key of the `View` for the scaffold or any other
///                             // widget provides the controller with a way to access them via getContext(), getState(), getStateKey()
///             body: Column(
///               children: <Widget>[
///                 Center(
///                   // show the number of times the button has been clicked
///                   child: Text(controller.counter.toString()),
///                 ),
///                 // wrapping the controller.increment with callHandler() automatically
///                 // refreshes the state after the counter is incremented
///                 // you can also refresh manually inside the controller
///                 // using refreshUI()
///                 MaterialButton(onPressed: () => callHandler(controller.increment)),
///               ],
///             ),
///           ),
///         );
///       }
///     }
///
/// ```
abstract class Controller with WidgetsBindingObserver, RouteAware {
  Function _refresh; // callback function for refreshing the UI
  bool isLoading; // indicates whether a loading dialog is present
  bool _isMounted = true;
  Logger logger;
  GlobalKey<State<StatefulWidget>> _globalKey;

  @mustCallSuper
  Controller() {
    logger = Logger('${this.runtimeType}');
    isLoading = false;
    initListeners();
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
      case AppLifecycleState.detached:
        onDetached();
        break;
    }
  }

  /// Dismisses the loading dialog. The parent `View` of this [Controller] should have its body wrapped
  /// in the ModelHUD and is listening to the [Controller]'s [isLoading]. Otherwise, this method will
  /// have no impact.
  @protected
  void dismissLoading() {
    assert(_refresh != null,
        '''The `refresh callback is somehow null. This might be because `dismissLoading()` was called
     before the `View` called `controller.initController()`.
     Please open an issue at `https://github.com/ShadyBoukhary/flutter_clean_architecture` describing 
     the error.''');
    if (_isMounted) _refresh(() => isLoading = false);
  }

  /// Sets the loading to true. The `View` body should be wrapped in a loader.
  /// Call on initial page load. For example, if a loader is needed as soon as you open a page.
  /// Only works when called inside the [Controller] constructor.
  @protected
  void loadOnStart() {
    isLoading = true;
  }

  /// Sets the loading to true. The `View` body should be wrapped in a loader.
  /// Call when a loader is needed after an event (e.g. a button press).
  /// Does not work if called inside the [Controller] constructor.
  @protected
  void showLoading() {
    assert(_refresh != null,
        '''The `_refresh callback is somehow null. This might be because `showLoading()` was called
     before the `View` called `controller.initController()`.
     Please open an issue at `https://github.com/ShadyBoukhary/flutter_clean_architecture` describing 
     the error.''');
    _refresh(() => isLoading = true);
  }

  /// _refreshes the [View] associated with the [Controller] if it is still mounted.
  @protected
  void refreshUI() {
    assert(_refresh != null,
        '''The `_refresh callback is somehow null. This might be because `refreshUI()` was called
     before the `View` called `controller.initController()`.
     Please open an issue at `https://github.com/ShadyBoukhary/flutter_clean_architecture` describing 
     the error.''');
    if (_isMounted) _refresh(() {});
  }

  /// Unmounts the [Controller] from the `View`. Called by the `View` automatically.
  /// Any cleaning, disposing should go in here.
  @mustCallSuper
  @visibleForOverriding
  void dispose() {
    _isMounted = false;
    logger.info('Disposing ${this.runtimeType}');
  }

  /// Retrieves the [State<StatefulWidget>] associated with the [View]
  @protected
  State<StatefulWidget> getState() {
    assert(_globalKey != null,
        '''The globalkey must be passed to the Controller via initController() from the View before this can be called.
    This is done automatically when the `Controller` is being constructed and this error should not occur. This might be a
    bug with the package. Please open an issue at `https://github.com/ShadyBoukhary/flutter_clean_architecture` describing 
     the error.''');

    assert(_globalKey.currentState != null,
        '''Make sure you are using the `globalKey` that is built into the `ViewState` inside your `build()` method.
        For example:
        `key: globalKey,` Otherwise, there is no state that the `Controller` could access.
        If this does not solve the issue, please open an issue at `https://github.com/ShadyBoukhary/flutter_clean_architecture` describing 
     the error.''');

    return _globalKey.currentState;
  }

  /// Retrieves the [GlobalKey<State<StatefulWidget>>] associated with the [View]
  @protected
  GlobalKey<State<StatefulWidget>> getStateKey() {
    assert(_globalKey != null,
        '''The globalkey must be passed to the Controller via initController() from the View before this can be called.
    This is done automatically when the `Controller` is being constructed and this error should not occur. This might be a
    bug with the package. Please open an issue at `https://github.com/ShadyBoukhary/flutter_clean_architecture` describing 
     the error.''');

    return _globalKey;
  }

  /// Initializes optional [Controller] variables that can be used for _refreshing and error displaying.
  /// This method is called automatically by the mounted `View`. Do not call.
  void initController(GlobalKey<State<StatefulWidget>> key, Function refresh) {
    _globalKey = key;
    this._refresh = refresh;
  }

  /// Retrieves the [BuildContext] associated with the `View`. Will throw an error if initController() was not called prior.
  @protected
  BuildContext getContext() {
    assert(_globalKey != null,
        '''The globalkey must be passed to the Controller via initController() from the View before this can be called.
    This is done automatically when the `Controller` is being constructed and this error should not occur. This might be a
    bug with the package. Please open an issue at `https://github.com/ShadyBoukhary/flutter_clean_architecture` describing 
     the error.''');

    assert(_globalKey.currentContext != null,
        '''Make sure you are using the `globalKey` that is built into the `ViewState` inside your `build()` method.
        For example:
        `key: globalKey,` Otherwise, there is no context that the `Controller` could access.
        If this does not solve the issue, please open an issue at `https://github.com/ShadyBoukhary/flutter_clean_architecture` describing 
     the error.''');

    return _globalKey.currentContext;
  }

  /// Intialize the listeners inside the the [Controller]'s [Presenter]. This method is called automatically inside the
  /// [Controller] constuctor and must be overridden. For example:
  /// ```dart
  ///     class MyController extends Controller {
  ///       final MyPresenter presenter;
  ///       MyController(): presenter = MyPresenter(), super();
  ///
  ///       @override
  ///       void initListeners() {
  ///         presenter.loginOnComplete = () {
  ///           print('Login is successful');
  ///         }
  ///         presenter.loginOnError = (e) {
  ///           print('Login is unsuccessful: $e.message');
  ///         }
  ///       }
  ///     }
  ///
  /// ```
  @protected
  void initListeners();

  /// Called when the application is in an inactive state and is not receiving user input.
  /// On iOS, this state corresponds to an app or the Flutter host view running in
  /// the foreground inactive state. Apps transition to this state when in a phone call,
  /// responding to a TouchID request, when entering the app switcher or the control center,
  /// or when the UIViewController hosting the Flutter app is transitioning.
  /// On Android, this corresponds to an app or the Flutter host view running in
  /// the foreground inactive state. Apps transition to this state when another
  /// activity is focused, such as a split-screen app, a phone call, a
  /// picture-in-picture app, a system dialog, or another window.
  ///
  /// Apps in this state should assume that they may be [onPaused] at any time.
  /// ```dart
  ///     class MyController extends Controller {
  ///       @override
  ///       void onInActive() => print('App is in the background.');
  ///     }
  /// ```
  void onInActive() {}

  /// Called when the application is not currently visible to the user, not responding to user input, and running in the background.
  /// When the application is in this state, the engine will not call the [Window.onBeginFrame] and [Window.onDrawFrame] callbacks.
  /// Android apps in this state should assume that they may enter the [suspending] state at any time.
  /// ```dart
  ///     class MyController extends Controller {
  ///       @override
  ///       void onPaused() => print('App is paused.');
  ///     }
  /// ```
  void onPaused() {}

  /// Called when the application is visible and is responding to the user i.e. in the foreground and running.
  /// ```dart
  ///     class MyController extends Controller {
  ///       @override
  ///       void onResumed() => print('App is resumed.');
  ///     }
  /// ```
  void onResumed() {}

  /// Called before the application is detached.
  /// When the application is in this state, the engine still runing but not attached to any view.
  /// 
  /// ```dart
  ///     class MyController extends Controller {
  ///       @override
  ///       void onDetached() => print('App is about to suspend.');
  ///     }
  /// ```
  void onDetached() {}
}
