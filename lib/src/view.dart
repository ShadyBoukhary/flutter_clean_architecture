import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture/src/controller.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:provider/provider.dart';

enum ScreenSizeType {
  TABLET,
  DESKTOP,
  MOBILE,
}

/// The [ResponsiveViewState] represents the [State] of a [StatefulWidget], typically of a screen or a
/// page. The [ResponsiveViewState] requires a [Controller] to handle its events and provide its data.
///
/// The [ResponsiveViewState] allow us to provide until three build methods to abstract responsivity for the
/// developer, and the screen renders the view based on [MediaQuery] screen width.
///
///
/// The [ResponsiveViewState] also has a default [globalKey] that can be used inside its `builds` function
/// in a widget to grant easy access to the [Controller], which could then use it to display
/// snackbars, dialogs, and so on.
///
/// The [ResponsiveViewState] lifecycle is also handled by the [Controller].
/// ```dart
///     class CounterState extends ViewResponsiveState<CounterPage, CounterController> {
///       CounterState(CounterController controller) : super(controller);
///
///       @override
///       Widget buildMobileView(BuildContext context) {
///         return Text("Mobile view");
///       }
///
///       @override
///       Widget buildTabletView(BuildContext context) {
///         return Text("Tablet view");
///       }
///
///       @override
///       Widget buildDesktopBiew(BuildContext context) {
///         return Text("Desktop view");
///       }
///     }
/// ```
abstract class ResponsiveViewState<Page extends View, Con extends Controller>
    extends ViewState<Page, Con> {
  /// To fill breakpoint params, they must be passed on super with it's name.
  /// ```dart
  /// SomePageState(SomeController controller)
  /// : super(
  ///     controller,
  ///     tabletBreakpointMinimumWidth: 700,
  ///     desktopBreakpointMinimumWidth: 1200,
  ///   );
  /// ```
  ///
  ResponsiveViewState(
    Con controller, {
    this.tabletBreakpointMinimumWidth = 600,
    this.desktopBreakpointMinimumWidth = 1024,
  })  : assert(desktopBreakpointMinimumWidth > tabletBreakpointMinimumWidth,
            'Desktop breakpoint must not be less than tablet'),
        super(controller);

  /// This breakpoint targets the minimum width of [Tablet] size. The default value is 600.
  /// When the width size from [context] comes under 600 (or the given value), it automatically switchs to [Mobile Viewport].
  final double tabletBreakpointMinimumWidth;

  /// This breakpoint targets the minimum width of [Desktop] size. The default value is 1024.
  /// When the width size from [context] comes under 1024 (or the given value), it automatically switchs to [Tablet Viewport].
  final double desktopBreakpointMinimumWidth;

  /// Abstract Method to be implemented by the developer which implements [Mobile ViewPort].
  Widget buildMobileView();

  /// Abstract Method to be implemented by the developer which implements [Tablet/Pad ViewPort].
  Widget buildTabletView();

  /// Abstract Method to be implemented by the developer which implements [Desktop ViewPort].
  Widget buildDesktopView();

  /// This method verify the dimensions using [MediaQuery], and so it defines which viewport will be exposed: [MOBILE], [TABLET] or [DESKTOP].
  /// The Default ViewPort is [MOBILE].
  ScreenSizeType get _screenSizeType {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < tabletBreakpointMinimumWidth) {
      return ScreenSizeType.MOBILE;
    }

    if (screenWidth < desktopBreakpointMinimumWidth &&
        screenWidth >= tabletBreakpointMinimumWidth) {
      return ScreenSizeType.TABLET;
    }

    return ScreenSizeType.DESKTOP;
  }

  /// This turns buildPage into an implicit method that build according to the given builds methods: [MOBILE], [TABLET] and [DESKTOP].
  /// The Default Viewport is [MOBILE]. When [TABLET] or [DESKTOP] builds are null, [MOBILE] viewport will be called. If all the build are null,
  /// it will throw an [UnimplentedError].
  @override
  @nonvirtual
  Widget buildPage() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        try {
          switch (_screenSizeType) {
            case ScreenSizeType.MOBILE:
              return buildMobileView() ??
                  buildTabletView() ??
                  buildDesktopView();
            case ScreenSizeType.TABLET:
              return buildTabletView() ??
                  buildDesktopView() ??
                  buildMobileView();
            case ScreenSizeType.DESKTOP:
              return buildDesktopView() ??
                  buildTabletView() ??
                  buildMobileView();
            default:
          }
        } catch (e) {
          print(e);
        }
        throw UnimplementedError('Implement at least one build method');
      },
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
    extends State<Page> {
  final GlobalKey<State<StatefulWidget>> globalKey =
      GlobalKey<State<StatefulWidget>>();
  Con _controller;
  Logger _logger;
  Con get controller => _controller;
  ViewState(this._controller) {
    _controller.initController(globalKey);
    WidgetsBinding.instance.addObserver(_controller);
    _logger = Logger('${runtimeType}');
  }

  @override
  @mustCallSuper
  void didChangeDependencies() {
    if (widget.routeObserver != null) {
      _logger.info('$runtimeType is observring route events.');
      widget.routeObserver.subscribe(_controller, ModalRoute.of(context));
    }

    super.didChangeDependencies();
  }

  Widget buildPage();

  @override
  @nonVirtual
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<Con>.value(
        value: _controller,
        child: Consumer<Con>(builder: (ctx, con, _) {
          _controller = con;
          return buildPage();
        }));
  }

  @override
  @mustCallSuper
  void dispose() {
    _logger.info('Disposing $runtimeType.');
    _controller.dispose();
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
  final Key key;
  final RouteObserver routeObserver;
  View({this.routeObserver, this.key}) : super(key: key);
}
