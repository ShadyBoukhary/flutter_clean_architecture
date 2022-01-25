import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:provider/provider.dart';

/// A Clean Architecture [Controller]. Should be aggregated within a `ViewState` or
/// a `View`. However, it is preferable to be contained inside the `View` for readability
/// and maintainability.
///
/// The [Controller] handles the events triggered by the `View`. For example, it handles
/// the click events of buttons, lifecycle, data-sourcing, etc...
///
/// The [Controller] is also route-aware. However, in order to use it,
/// it has to be initialized separately.
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
///                 MaterialButton(onPressed: () => controller.increment()),
///               ],
///             ),
///           ),
///         );
///       }
///     }
///
/// ```
abstract class Controller
    with WidgetsBindingObserver, RouteAware, ChangeNotifier {
  late bool _isMounted;
  late Logger logger;
  late GlobalKey<State<StatefulWidget>> _globalKey;

  @mustCallSuper
  Controller() {
    logger = Logger('$runtimeType');
    _isMounted = true;
    initListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isMounted) {
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
  }

  /// _refreshes the [ControlledWidgets] and the [StatefulWidgets] that depends on [FlutterCleanArchitecture.getController] of the [View] associated with the [Controller] if it is still mounted.
  @protected
  void refreshUI() {
    if (_isMounted) {
      notifyListeners();
    }
  }

  /// Unmounts the [Controller] from the `View`. Called by the `View` automatically.
  /// Any cleaning, disposing should go in here.
  ///
  /// To perform correct actions that depends on latest [BuildContext] used on view before dispose, you must
  /// use injected context.
  ///
  /// The usage of [Controller.getContext] will be impossible here. Since the context will be null after the widget be removed from the widget
  /// tree.
  @mustCallSuper
  void onDisposed() {
    assert(_globalKey.currentContext == null,
        '''Make sure you are not calling `dispose` in any other call. This method should only be called from view `dispose` method.
        
        Also, the usage of context `onDispose` lifecycle is unsafe and it may lead to errors. If you need to remove any resources from the
        tree, please check if `onDeactivate` lifecycle, that controls `deactivate` view state are enough to your case.
        
        For example:
        If this does not resolve for you, please open an issue at `https://github.com/ShadyBoukhary/flutter_clean_architecture` describing 
     the error.''');
    dispose();
  }

  @override
  @nonVirtual
  void dispose() {
    _isMounted = false;
    logger.info('Disposing $runtimeType');
    super.dispose();
  }

  /// Retrieves the [State<StatefulWidget>] associated with the [View]
  @protected
  State<StatefulWidget> getState() {
    assert(_globalKey.currentState != null,
        '''Make sure you are using the `globalKey` that is built into the `ViewState` inside your `build()` method.
        For example:
        `key: globalKey,` Otherwise, there is no state that the `Controller` could access.
        If this does not solve the issue, please open an issue at `https://github.com/ShadyBoukhary/flutter_clean_architecture` describing 
     the error.''');

    return _globalKey.currentState!;
  }

  /// Retrieves the [GlobalKey<State<StatefulWidget>>] associated with the [View]
  @protected
  GlobalKey<State<StatefulWidget>> getStateKey() {
    return _globalKey;
  }

  /// Initializes optional [Controller] variables that can be used for _refreshing and error displaying.
  /// This method is called automatically by the mounted `View`. Do not call.
  void initController(GlobalKey<State<StatefulWidget>> key) {
    _globalKey = key;
  }

  /// Retrieves the [BuildContext] associated with the `View`. Will throw an error if initController() was not called prior.
  @protected
  BuildContext getContext() {
    assert(_globalKey.currentContext != null,
        '''Make sure you are using the `globalKey` that is built into the `ViewState` inside your `build()` method.
        For example:
        `key: globalKey,` Otherwise, there is no context that the `Controller` could access.
        If this does not solve the issue, please open an issue at `https://github.com/ShadyBoukhary/flutter_clean_architecture` describing 
     the error.''');

    return _globalKey.currentContext!;
  }

  /// Initialize the listeners inside the the [Controller]'s [Presenter]. This method is called automatically inside the
  /// [Controller] constructor and must be overridden. For example:
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
  @visibleForOverriding
  void onInActive() {}

  /// Called when the application is not currently visible to the user, not responding to user input, and running in the background.
  /// When the application is in this state, the engine will not call the [Window.onBeginFrame] and [Window.onDrawFrame] callbacks.
  /// Android apps in this state should assume that they may enter the [detached] state at any time.
  /// ```dart
  ///     class MyController extends Controller {
  ///       @override
  ///       void onPaused() => print('App is paused.');
  ///     }
  /// ```
  @visibleForOverriding
  void onPaused() {}

  /// Called when the application is visible and is responding to the user i.e. in the foreground and running.
  /// ```dart
  ///     class MyController extends Controller {
  ///       @override
  ///       void onResumed() => print('App is resumed.');
  ///     }
  /// ```
  @visibleForOverriding
  void onResumed() {}

  /// Called before the application is detached.
  /// When the application is in this state, the engine is still running but not attached to any view.
  ///
  /// ```dart
  ///     class MyController extends Controller {
  ///       @override
  ///       void onDetached() => print('App is about to detach.');
  ///     }
  /// ```
  @visibleForOverriding
  void onDetached() {}

  /// Called before the view is deactivated.
  /// When the view is in this context, it means that the view is about to be extracted from the widget tree, but it may be
  /// added again. Quoting the view `deactivate` docs from `https://api.flutter.dev/flutter/widgets/State/deactivate.html`:
  ///
  /// ```The framework calls this method whenever it removes this State object from the tree.
  ///   In some cases, the framework will reinsert the State object into another part of the tree
  ///   (e.g., if the subtree containing this State object is grafted from one location in the tree to another).
  ///   If that happens, the framework will ensure that it calls build to give the
  ///   State object a chance to adapt to its new location in the tree.
  /// ```
  ///
  /// So, this may be the correct lifecycle to remove any resources that depend on other widgets in the widget tree.
  ///
  /// Usage:
  ///
  /// ```dart
  ///     class MyController extends Controller {
  ///       @override
  ///       void onDeactivated() => print('View is about to be deactivated and maybe disposed');
  ///     }
  /// ```
  @visibleForOverriding
  void onDeactivated() {}

  /// Called before the view is reassembled.
  /// When this method is called on view life cycle on `reassemble`, and it guarantees that `build` lifecycle will
  /// be called. Quoting the docs:
  ///
  /// ```Most widgets therefore do not need to do anything in the [reassemble] method.```
  ///
  /// Please be sure to read docs before use this life cycle.
  ///
  /// Usage:
  ///
  /// ```dart
  ///     class MyController extends Controller {
  ///       @override
  ///       void onReassembled() => print('View is about to be reassembled');
  ///     }
  /// ```
  @visibleForOverriding
  void onReassembled() {}

  /// Called before [View.didChangeDependencies] is called
  ///
  /// Should be used when need to perform some action on [View.didChangeDependencies] life cycle.
  /// [View.initViewState] should be called before the actions you need to perform. Like [didChangeDependencies], you can safely perform
  /// actions that depends on [BuildContext] here.
  ///
  /// ```dart
  ///     class MyController extends Controller {
  ///       @override
  ///       void onDidChangeDependencies() => print('View is about to run didChangeDependencies life cycle');
  ///     }
  /// ```
  @visibleForOverriding
  void onDidChangeDependencies() {}

  /// Called before [View.initState] is called
  ///
  /// Should be used when need to perform some action on [View.initState] life cycle.
  ///
  /// ```dart
  ///     class MyController extends Controller {
  ///       @override
  ///       void onInitState() => print('View is about to run initState life cycle');
  ///     }
  /// ```
  @visibleForOverriding
  void onInitState() {}
}

typedef ControlledBuilder<Con extends Controller> = Widget Function(
    BuildContext context, Con controller);

/// This is a representation of a widget that is controlled by a [Controller] and needs to be re-rendered when
/// [Controller.refreshUI] is triggered.
///
/// This was created to optimize the render cycle from a [ViewState]'s widget tree.
///
/// When [Controller.refreshUI] is called, only the ControlledWidgets inside [ViewState.view] will be re-rendered.
///
/// Example:
///
/// ```dart
///   class ExamplePage extends View {
///     @override
///     State<StatefulWidget> createState() => ExampleState();
///   }
///
///   class ExampleState extends ViewState<ExamplePage, ExampleController> {
///     ExampleState() : super(ExampleController());
///
///     Widget get view {
///       return Scaffold(
///         key: globalKey,
///         body: SingleChildScrollView(
///           child: Column(
///             children: [
///               Text("Uncontrolled title that will not re-render"),
///               ControlledWidgetBuilder(
///                 builder: (context, controller) {
///                   // Controlled widget that depends on controllers value
///                   return Text(controller.foo);
///                 }
///               )
///             ]
///           )
///         )
///       )
///     }
///   }
/// ``
class ControlledWidgetBuilder<Con extends Controller> extends StatelessWidget {
  final ControlledBuilder<Con> builder;

  ControlledWidgetBuilder({required this.builder});

  @override
  Widget build(BuildContext context) => Consumer<Con>(
      builder: (BuildContext context, Con controller, _) =>
          builder(context, controller));
}
