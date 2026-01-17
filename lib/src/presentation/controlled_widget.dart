import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controller.dart';

/// A function that builds a widget using a [Controller].
typedef ControlledBuilder<Con extends Controller> = Widget Function(
  BuildContext context,
  Con controller,
);

/// A widget that rebuilds when the [Controller] calls [Controller.refreshUI].
///
/// [ControlledWidgetBuilder] uses [Consumer] from Provider to listen to
/// the Controller's [ChangeNotifier] notifications and rebuild only the
/// widgets that depend on the Controller's state.
///
/// This enables fine-grained rebuilds — only [ControlledWidgetBuilder]
/// widgets will rebuild, not the entire view.
///
/// ## Example
/// ```dart
/// class _ProductPageState extends CleanViewState<ProductPage, ProductController> {
///   _ProductPageState() : super(ProductController());
///
///   @override
///   Widget get view {
///     return Scaffold(
///       key: globalKey,
///       appBar: AppBar(
///         // This Text doesn't rebuild when controller changes
///         title: const Text('Product Details'),
///       ),
///       body: Column(
///         children: [
///           // This rebuilds when controller.refreshUI() is called
///           ControlledWidgetBuilder<ProductController>(
///             builder: (context, controller) {
///               if (controller.state.isLoading) {
///                 return const CircularProgressIndicator();
///               }
///               return Text(controller.state.product?.name ?? 'No product');
///             },
///           ),
///           // This also rebuilds independently
///           ControlledWidgetBuilder<ProductController>(
///             builder: (context, controller) {
///               return Text('Price: \$${controller.state.product?.price}');
///             },
///           ),
///         ],
///       ),
///     );
///   }
/// }
/// ```
///
/// ## Accessing Controller Without Rebuilding
/// If you need to access the controller but don't want to rebuild,
/// use `FlutterCleanArchitecture.getController`:
/// ```dart
/// onPressed: () {
///   final controller = FlutterCleanArchitecture.getController<MyController>(
///     context,
///     listen: false, // Don't rebuild on changes
///   );
///   controller.doSomething();
/// }
/// ```
class ControlledWidgetBuilder<Con extends Controller> extends StatelessWidget {
  /// The builder function that builds the widget using the [Controller].
  ///
  /// This function is called whenever the Controller calls [Controller.refreshUI].
  final ControlledBuilder<Con> builder;

  /// Create a [ControlledWidgetBuilder].
  ///
  /// The [builder] function receives the [BuildContext] and the [Controller]
  /// and should return the widget to display.
  const ControlledWidgetBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<Con>(
      builder: (BuildContext context, Con controller, Widget? child) {
        return builder(context, controller);
      },
    );
  }
}

/// A variant of [ControlledWidgetBuilder] with a static child widget.
///
/// Use this when part of your widget tree doesn't depend on the Controller
/// and shouldn't be rebuilt. The [child] widget is built once and passed
/// to the [builder] function on each rebuild.
///
/// ## Example
/// ```dart
/// ControlledWidgetBuilderWithChild<ProductController>(
///   // This widget is built once and reused
///   child: const ExpensiveWidget(),
///   builder: (context, controller, child) {
///     return Column(
///       children: [
///         Text(controller.state.title), // Rebuilds
///         child!, // Doesn't rebuild
///       ],
///     );
///   },
/// )
/// ```
class ControlledWidgetBuilderWithChild<Con extends Controller>
    extends StatelessWidget {
  /// The builder function that builds the widget using the [Controller] and [child].
  final Widget Function(BuildContext context, Con controller, Widget? child)
      builder;

  /// A widget that doesn't depend on the Controller.
  ///
  /// This widget is built once and passed to [builder] on each rebuild,
  /// avoiding unnecessary rebuilds of expensive widgets.
  final Widget? child;

  /// Create a [ControlledWidgetBuilderWithChild].
  const ControlledWidgetBuilderWithChild({
    super.key,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<Con>(
      builder: builder,
      child: child,
    );
  }
}

/// A selector variant of [ControlledWidgetBuilder] that only rebuilds
/// when a specific value changes.
///
/// Use this for fine-grained control over when rebuilds occur. The widget
/// only rebuilds when the value returned by [selector] changes.
///
/// ## Example
/// ```dart
/// // Only rebuilds when the product name changes, not other state
/// ControlledWidgetSelector<ProductController, String?>(
///   selector: (controller) => controller.state.product?.name,
///   builder: (context, productName) {
///     return Text(productName ?? 'Unknown');
///   },
/// )
/// ```
class ControlledWidgetSelector<Con extends Controller, T>
    extends StatelessWidget {
  /// Selects a value from the Controller.
  ///
  /// The widget only rebuilds when this value changes.
  final T Function(Con controller) selector;

  /// Builds the widget using the selected value.
  final Widget Function(BuildContext context, T value) builder;

  /// Create a [ControlledWidgetSelector].
  const ControlledWidgetSelector({
    super.key,
    required this.selector,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<Con, T>(
      selector: (context, controller) => selector(controller),
      builder: (context, value, child) => builder(context, value),
    );
  }
}
