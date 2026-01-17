import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:provider/provider.dart';

import 'controller.dart';

/// A Clean Architecture View.
///
/// [CleanView] is a [StatefulWidget] that serves as the base class for
/// all views (screens/pages) in the application. It integrates with
/// [Controller] for state management and business logic coordination.
///
/// ## Features
/// - Automatic Controller lifecycle management
/// - Provider integration for dependency injection
/// - Route awareness for navigation callbacks
/// - Built-in global key for Controller access to context/state
///
/// ## Example
/// ```dart
/// class ProductPage extends CleanView {
///   final String productId;
///
///   const ProductPage({
///     required this.productId,
///     super.key,
///     super.routeObserver,
///   });
///
///   @override
///   State<ProductPage> createState() => _ProductPageState();
/// }
///
/// class _ProductPageState extends CleanViewState<ProductPage, ProductController> {
///   _ProductPageState() : super(ProductController());
///
///   @override
///   Widget get view {
///     return Scaffold(
///       key: globalKey, // Important: use globalKey on root widget
///       appBar: AppBar(title: Text('Product')),
///       body: ControlledWidgetBuilder<ProductController>(
///         builder: (context, controller) {
///           if (controller.state.isLoading) {
///             return const CircularProgressIndicator();
///           }
///           return ProductDetails(product: controller.state.product);
///         },
///       ),
///     );
///   }
///
///   @override
///   void onInitState() {
///     super.onInitState();
///     controller.loadProduct(widget.productId);
///   }
/// }
/// ```
abstract class CleanView extends StatefulWidget {
  /// Optional [RouteObserver] for route awareness.
  ///
  /// If provided, the Controller will receive callbacks for route events
  /// (push, pop, etc.) via [RouteAware].
  final RouteObserver<ModalRoute<void>>? routeObserver;

  const CleanView({
    super.key,
    this.routeObserver,
  });
}

/// The state for a [CleanView].
///
/// [CleanViewState] manages the lifecycle of a [Controller] and provides
/// integration with Flutter's widget lifecycle, Provider for state management,
/// and route observation.
///
/// ## Key Features
/// - Automatic Controller initialization and disposal
/// - Global key for Controller access to BuildContext and State
/// - Provider integration for [ControlledWidgetBuilder]
/// - Route awareness via [RouteObserver]
///
/// ## Usage
/// 1. Extend this class with your Page and Controller types
/// 2. Pass the Controller instance to super constructor
/// 3. Override `view` getter to build your UI
/// 4. Use `globalKey` on your root widget (usually Scaffold)
/// 5. Use [ControlledWidgetBuilder] for widgets that need Controller access
///
/// ## Example
/// ```dart
/// class _HomePageState extends CleanViewState<HomePage, HomeController> {
///   _HomePageState() : super(HomeController());
///
///   @override
///   Widget get view {
///     return Scaffold(
///       key: globalKey,
///       body: ControlledWidgetBuilder<HomeController>(
///         builder: (context, controller) {
///           return Text(controller.state.message);
///         },
///       ),
///     );
///   }
/// }
/// ```
abstract class CleanViewState<P extends CleanView, Con extends Controller>
    extends State<P> {
  /// The Controller for this view.
  ///
  /// Access this to call Controller methods or read state.
  @protected
  final Con controller;

  /// Global key for the root widget.
  ///
  /// **Important**: Use this key on your root widget (usually Scaffold)
  /// to enable the Controller to access BuildContext and State.
  ///
  /// Example:
  /// ```dart
  /// Scaffold(
  ///   key: globalKey,
  ///   body: ...,
  /// )
  /// ```
  final GlobalKey<State<StatefulWidget>> globalKey =
      GlobalKey<State<StatefulWidget>>();

  late final Logger _logger;

  /// Create a [CleanViewState] with the given [controller].
  CleanViewState(this.controller) {
    controller.initController(globalKey);
    _logger = Logger('$runtimeType');
  }

  /// Override this to build your view.
  ///
  /// This is the main build method for your page. Use [globalKey] on
  /// the root widget and [ControlledWidgetBuilder] for widgets that
  /// need to react to Controller state changes.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Widget get view {
  ///   return Scaffold(
  ///     key: globalKey,
  ///     appBar: AppBar(title: const Text('My Page')),
  ///     body: ControlledWidgetBuilder<MyController>(
  ///       builder: (context, controller) {
  ///         return Text(controller.state.data);
  ///       },
  ///     ),
  ///   );
  /// }
  /// ```
  Widget get view;

  // ============================================================
  // Flutter Lifecycle
  // ============================================================

  @override
  @mustCallSuper
  void initState() {
    super.initState();
    _logger.fine('initState');

    // Register for app lifecycle events
    WidgetsBinding.instance.addObserver(controller);

    // Notify controller
    controller.onInitState();
  }

  @override
  @mustCallSuper
  void didChangeDependencies() {
    super.didChangeDependencies();
    _logger.fine('didChangeDependencies');

    // Subscribe to route events if observer is provided
    if (widget.routeObserver != null) {
      final route = ModalRoute.of(context);
      if (route != null) {
        widget.routeObserver!.subscribe(controller, route);
        _logger.fine('Subscribed to route observer');
      }
    }

    // Notify controller
    controller.onDidChangeDependencies();
  }

  @override
  @nonVirtual
  Widget build(BuildContext context) {
    // Wrap in ChangeNotifierProvider for ControlledWidgetBuilder access
    return ChangeNotifierProvider<Con>.value(
      value: controller,
      child: view,
    );
  }

  @override
  @mustCallSuper
  void deactivate() {
    _logger.fine('deactivate');
    controller.onDeactivated();
    super.deactivate();
  }

  @override
  @mustCallSuper
  void reassemble() {
    _logger.fine('reassemble');
    controller.onReassembled();
    super.reassemble();
  }

  @override
  @mustCallSuper
  void dispose() {
    _logger.fine('dispose');

    // Unregister from app lifecycle events
    WidgetsBinding.instance.removeObserver(controller);

    // Unsubscribe from route events
    if (widget.routeObserver != null) {
      widget.routeObserver!.unsubscribe(controller);
    }

    // Notify controller and dispose
    controller.onDisposed();

    super.dispose();
  }
}
