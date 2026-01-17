import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:responsive_builder/responsive_builder.dart';

import 'controller.dart';
import 'view.dart';

/// A responsive variant of [CleanViewState] that automatically adapts
/// to different screen sizes.
///
/// [ResponsiveViewState] uses breakpoints to determine which view to show
/// based on the current screen width. It provides sensible defaults so you
/// only need to implement the views you care about.
///
/// ## Breakpoints (default)
/// - **Watch**: < 300dp
/// - **Mobile**: 300dp - 600dp (default)
/// - **Tablet**: 600dp - 950dp
/// - **Desktop**: > 950dp
///
/// ## Cascade Behavior
/// Views cascade from larger to smaller, then to mobile:
/// - If `desktopView` is not overridden → uses `tabletView`
/// - If `tabletView` is not overridden → uses `mobileView`
/// - If `watchView` is not overridden → uses `mobileView`
///
/// This means you can just implement `mobileView` and it will be used
/// for all screen sizes.
///
/// ## Example: Mobile-only
/// ```dart
/// class _HomePageState extends ResponsiveViewState<HomePage, HomeController> {
///   _HomePageState() : super(HomeController());
///
///   @override
///   Widget get mobileView {
///     return Scaffold(
///       key: globalKey,
///       body: const Center(child: Text('Works on all sizes!')),
///     );
///   }
/// }
/// ```
///
/// ## Example: Different layouts for mobile and tablet
/// ```dart
/// class _ProductListState extends ResponsiveViewState<ProductListPage, ProductListController> {
///   _ProductListState() : super(ProductListController());
///
///   @override
///   Widget get mobileView {
///     return Scaffold(
///       key: globalKey,
///       body: ProductListView(), // Single column
///     );
///   }
///
///   @override
///   Widget get tabletView {
///     return Scaffold(
///       key: globalKey,
///       body: ProductGridView(columns: 3), // Grid layout
///     );
///   }
///
///   @override
///   Widget get desktopView {
///     return Scaffold(
///       key: globalKey,
///       body: Row(
///         children: [
///           Sidebar(),
///           Expanded(child: ProductGridView(columns: 4)),
///         ],
///       ),
///     );
///   }
/// }
/// ```
///
/// ## Custom Breakpoints
/// Override [breakpoints] to use custom screen size thresholds:
/// ```dart
/// @override
/// ScreenBreakpoints get breakpoints => ScreenBreakpoints(
///   desktop: 1200,
///   tablet: 800,
///   watch: 200,
/// );
/// ```
///
/// ## Accessing Screen Size
/// Use [screenType] to get the current screen size type for conditional logic:
/// ```dart
/// if (screenType == ScreenSizeType.mobile) {
///   // Mobile-specific behavior
/// }
/// ```
abstract class ResponsiveViewState<P extends CleanView, Con extends Controller>
    extends CleanViewState<P, Con> {
  ResponsiveViewState(super.controller);

  /// The current screen size type.
  ///
  /// This is updated whenever the screen size changes. Use it for
  /// conditional logic that depends on screen size.
  ScreenSizeType _screenType = ScreenSizeType.mobile;

  /// Get the current screen size type.
  ScreenSizeType get screenType => _screenType;

  // ============================================================
  // View Builders
  // ============================================================

  /// The view to show on mobile devices (default).
  ///
  /// This is the **required** base view. All other views cascade to this
  /// if not overridden.
  ///
  /// **Important**: Remember to use `globalKey` on your root widget.
  Widget get mobileView;

  /// The view to show on tablets.
  ///
  /// Defaults to [mobileView] if not overridden.
  Widget get tabletView => mobileView;

  /// The view to show on desktop.
  ///
  /// Defaults to [tabletView] if not overridden, which cascades to [mobileView].
  Widget get desktopView => tabletView;

  /// The view to show on watch-sized devices.
  ///
  /// Defaults to [mobileView] if not overridden.
  Widget get watchView => mobileView;

  // ============================================================
  // Configuration
  // ============================================================

  /// Custom breakpoints for screen size detection.
  ///
  /// Override this to use custom thresholds. The defaults are:
  /// - Desktop: 950dp
  /// - Tablet: 600dp
  /// - Watch: 300dp
  ///
  /// Example:
  /// ```dart
  /// @override
  /// ScreenBreakpoints get breakpoints => ScreenBreakpoints(
  ///   desktop: 1200,
  ///   tablet: 800,
  ///   watch: 200,
  /// );
  /// ```
  ScreenBreakpoints? get breakpoints => null;

  // ============================================================
  // Build
  // ============================================================

  /// Builds the responsive view.
  ///
  /// This method is `@nonVirtual` — override the individual view getters
  /// ([mobileView], [tabletView], [desktopView], [watchView]) instead.
  @override
  @nonVirtual
  Widget get view {
    return ScreenTypeLayout.builder(
      breakpoints: breakpoints,
      mobile: (context) {
        _screenType = ScreenSizeType.mobile;
        return mobileView;
      },
      tablet: (context) {
        _screenType = ScreenSizeType.tablet;
        return tabletView;
      },
      desktop: (context) {
        _screenType = ScreenSizeType.desktop;
        return desktopView;
      },
      watch: (context) {
        _screenType = ScreenSizeType.watch;
        return watchView;
      },
    );
  }
}

/// Enum representing the current screen size type.
enum ScreenSizeType {
  /// Watch-sized screens (< 300dp by default)
  watch,

  /// Mobile-sized screens (300dp - 600dp by default)
  mobile,

  /// Tablet-sized screens (600dp - 950dp by default)
  tablet,

  /// Desktop-sized screens (> 950dp by default)
  desktop,
}
