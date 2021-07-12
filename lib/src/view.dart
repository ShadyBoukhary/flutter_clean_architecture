import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:responsive_builder/responsive_builder.dart';

enum ScreenSizeType {
  TABLET,
  DESKTOP,
  MOBILE,
}

/// Defines a function type that receives a [BuildContext] and returns a [Widget] for widget builders.
typedef ViewBuilder = Widget Function(BuildContext context);

/// The [ResponsiveViewState] represents the [State] of a [StatefulWidget], typically of a screen or a
/// page. The [ResponsiveViewState] requires a [Controller] to handle its events and provide its data.
///
/// The [ResponsiveViewState] allow us to provide until four build methods to abstract responsiveness for the
/// developer, and the screen renders the view based on [MediaQuery] screen width managed by [ScreenTypeLayout.builder].
///
///
/// The [ResponsiveViewState] also has a default [globalKey] that can be used inside its `builds` function
/// in a widget to grant easy access to the [Controller], which could then use it to display
/// snackbars, dialogs, and so on.
///
/// The [ResponsiveViewState] lifecycle is also handled by the [Controller].
///
/// You can optionally define builders for layouts that you want to implement (It will always give priority to bigger to smaller
/// resolutions (e.g: If desktop isn't provided on desktop resolution, it will try to build tablet and forward)
/// ```dart
///     class CounterState extends ResponsiveViewState<CounterPage, CounterController> {
///       CounterState(CounterController controller) : super(controller);
///
///       @override
///       ViewBuilder mobileBuilder = (BuildContext context) {
///         return Text("Mobile view");
///       };
///
///       @override
///       ViewBuilder tabletBuilder = (BuildContext context) {
///         return Text("Tablet view");
///       };
///
///       @override
///       ViewBuilder desktopBuilder = (BuildContext context) {
///         return Text("Desktop view");
///       };
///
///       @override
///       ViewBuilder watchBuilder = (BuildContext context) {
///         return Text("Watch view");
///       };
///     }
/// ```
///
/// You can optionally set globally new default values for breakpoints. To do so, just check on [FlutterCleanArchitecture.setDefaultViewBreakpoints]
abstract class ResponsiveViewState<Page extends View, Con extends Controller>
    extends ViewState<Page, Con> {
  ResponsiveViewState(Con controller) : super(controller);

  /// To be implemented by the developer which will build on [Watch ViewPort].
  /// The default breakpoint value is less than [300]
  Widget get watchView;

  /// To be implemented by the developer which will build on [Mobile ViewPort].
  /// The default breakpoint value is more than [375]
  Widget get mobileView;

  /// To be implemented by the developer which will build on [Tablet/Pad ViewPort].
  /// The default breakpoint value is [600]
  Widget get tabletView;

  /// To be implemented by the developer which will build on [Desktop ViewPort].
  /// The default breakpoint value is [950]
  Widget get desktopView;

  /// This turns view into an implicit method that build according to the given builds methods: [MOBILE], [TABLET], [DESKTOP] and [WATCH].
  /// The Default Viewport is [MOBILE]. When [TABLET] or [DESKTOP] builds are null, [MOBILE] viewport will be called.
  @override
  @nonVirtual
  Widget get view {
    return ScreenTypeLayout.builder(
      mobile: (_) => mobileView,
      tablet: (_) => tabletView,
      desktop: (_) => desktopView,
      watch: (_) => watchView,
    );
  }
}

/// The [ViewState] represents the [State] of a [StatefulWidget], typically of a screen or a
/// page. The [ViewState] requires a [Controller] to handle its events and provide its data.
///
/// The [ViewState] also has a default [globalKey] that can be used inside its `build()` function
/// in a widget to grant easy access to the [Controller], which could then use it to display
/// snackbars, dialogs, and so on.
///
/// The [ViewState] lifecycle is also handled by the [Controller].
/// ```dart
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
///                 // you can refresh manually inside the controller
///                 // using refreshUI()
///                 MaterialButton(onPressed: controller.increment),
///               ],
///             ),
///           ),
///         );
///       }
///     }
///
/// ```
abstract class ViewState<Page extends View, Con extends Controller>
    extends State<Page> with Diagnosticable {
  final GlobalKey<State<StatefulWidget>> globalKey =
      GlobalKey<State<StatefulWidget>>();
  final Con _controller;
  late Logger _logger;
  late ViewBuilder builder;

  /// Implement the [Widget] you want to be displayed on [View]
  Widget get view;

  ViewState(this._controller) {
    _controller.initController(globalKey);
    WidgetsBinding.instance!.addObserver(_controller);
    _logger = Logger('$runtimeType');
  }

  @override
  @mustCallSuper
  void didChangeDependencies() {
    if (widget.routeObserver != null) {
      _logger.info('$runtimeType is observing route events.');
      widget.routeObserver!.subscribe(_controller, ModalRoute.of(context)!);
    }

    _logger.info('didChangeDependencies triggered on $runtimeType');
    _controller.onDidChangeDependencies();
    super.didChangeDependencies();
  }

  @override
  @nonVirtual
  void initState() {
    _logger.info('Initializing state of $runtimeType');
    _controller.onInitState();
    super.initState();
  }

  @override
  @nonVirtual
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<Con>.value(value: _controller, child: view);
  }

  @override
  @mustCallSuper
  void deactivate() {
    _logger.info(
        'Deactivating $runtimeType. (This is usually called right before dispose)');
    _controller.onDeactivated();
    super.deactivate();
  }

  @override
  @mustCallSuper
  void reassemble() {
    _logger.info('Reassembling $runtimeType.');
    _controller.onReassembled();
    super.reassemble();
  }

  @override
  @mustCallSuper
  void dispose() {
    _logger.info('Disposing $runtimeType.');
    _controller.onDisposed();
    super.dispose();
  }
}

/// The [View] represents a [StatefulWidget]. The [View] is typically a page or screen in
/// the application. However, a [View] can be any [StatefulWidget]. The [View] must have a
/// [State], and that [State] should be of type [ViewState<MyView, MyController>].
///
/// If a [RouteObserver] is given to the [View], it is used to register its [Controller] as
/// a subscriber, which provides the ability to listen to push and pop route events.
/// ```dart
///   class CounterPage extends View {
///     CounterPage({RouteObserver observer, Key key}): super(routeObserver: routeObserver, key: key);
///     @override
///     // Dependencies can be injected here
///     State<StatefulWidget> createState() => CounterState(Controller());
///   }
///
/// ```
///
abstract class View extends StatefulWidget {
  @override
  final Key? key;
  final RouteObserver? routeObserver;

  View({this.routeObserver, this.key}) : super(key: key);
}
