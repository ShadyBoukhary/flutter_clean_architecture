import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture/src/controller.dart';

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
abstract class ViewState<Page extends View, Con extends Controller>
    extends State<Page> {
  final GlobalKey<State<StatefulWidget>> globalKey =
      GlobalKey<State<StatefulWidget>>();
  final Con controller;

  ViewState(this.controller) {
    controller.initController(globalKey, callHandler);
    WidgetsBinding.instance.addObserver(controller);
  }

  @override
  @mustCallSuper
  void didChangeDependencies() {
    if (widget.routeObserver != null) {
      widget.routeObserver.subscribe(controller, ModalRoute.of(context));
    }
    super.didChangeDependencies();
  }

  /// A wrapper around a [Function] of the [Controller]. This method can be used to handle
  /// button press events that always refresh the state. This method calls the the [fn] provided
  /// then refreshes the state of the widget.
  ///
  /// Any optional [params] are also passed to the [fn] as a [Map].
  /// ```dart
  ///     MaterialButton(onPressed: () => callHandler(controller.increment)),
  ///     MaterialButton(onPressed: () => callHandler(controller.increment, params: { 'arg1': '5' })),
  /// ```
  void callHandler(Function fn, {Map<String, dynamic> params}) {
    setState(() {
      if (params == null) {
        fn();
      } else {
        fn(params);
      }
    });
  }

  @override
  @mustCallSuper
  void dispose() {
    controller.dispose();
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
///     @override
///     // Dependencies can be injected here
///     State<StatefulWidget> createState() => CounterState(Controller());
///   }
///
/// ```
///
abstract class View extends StatefulWidget {
  final RouteObserver routeObserver;
  final Key key;
  View({this.routeObserver, this.key}) : super(key: key);
}
