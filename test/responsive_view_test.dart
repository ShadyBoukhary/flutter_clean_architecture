import 'package:flutter/material.dart' hide View;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';

void main() {
  var stateInitialized = false;
  var viewDidChangeViewDependenciesTriggered = false;
  var stateDeactivated = false;

  late Widget page;
  late TestController controller;

  setUp(() {
    controller = TestController(
      onViewDeactivated: () {
        stateDeactivated = true;
      },
      onViewDidChangeDependencies: () {
        viewDidChangeViewDependenciesTriggered = true;
      },
      onViewInitState: () {
        stateInitialized = true;
      },
    );
    page = TestPage(controller: controller);
  });

  testWidgets('Run TestPage | Mobile viewport then resizes',
      (WidgetTester tester) async {
    await tester.setScreenSize(width: 540, height: 540);

    await tester.pumpWidget(MaterialApp(home: page));

    expect(stateInitialized, isTrue);
    expect(viewDidChangeViewDependenciesTriggered, isTrue);

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Mobile'), findsOneWidget);

    await tester.setScreenSize(width: 700, height: 600);

    await tester.pumpAndSettle();

    expect(find.text('Tablet'), findsOneWidget);

    await tester.setScreenSize(width: 1024, height: 1024);

    await tester.pumpAndSettle();

    expect(find.text('Desktop'), findsOneWidget);

    // To remove page from tree
    await tester.pumpWidget(Container());

    expect(stateDeactivated, isTrue);
  });

  testWidgets('Run TestPage | Mobile Viewport', (WidgetTester tester) async {
    await tester.setScreenSize(width: 540, height: 540);

    await tester.pumpWidget(MaterialApp(home: page));

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(Container), findsWidgets);
    expect(find.byType(Text), findsOneWidget);
    expect(find.text('Mobile'), findsOneWidget);
    expect(find.byWidget(page), findsOneWidget);
  });

  testWidgets('Run TestPage | Tablet Viewport', (WidgetTester tester) async {
    await tester.setScreenSize(width: 700, height: 600);

    await tester
        .pumpWidget(MaterialApp(home: Container(child: page, width: 800)));

    expect(find.byType(Container), findsWidgets);
    expect(find.byType(Text), findsOneWidget);
    expect(find.text('Tablet'), findsOneWidget);
    expect(find.byWidget(page), findsOneWidget);
  });

  testWidgets('Run TestPage | Desktop Viewport', (WidgetTester tester) async {
    await tester.setScreenSize(width: 1024, height: 1024);

    await tester
        .pumpWidget(MaterialApp(home: Container(child: page, width: 1500)));

    expect(find.byType(Container), findsWidgets);
    expect(find.byType(Text), findsOneWidget);
    expect(find.text('Desktop'), findsOneWidget);
    expect(find.byWidget(page), findsOneWidget);
  });

  testWidgets('Run TestPage | Watch Viewport', (WidgetTester tester) async {
    await tester.setScreenSize(width: 250, height: 250);

    await tester
        .pumpWidget(MaterialApp(home: Container(child: page, width: 250)));

    expect(find.byType(Container), findsWidgets);
    expect(find.byType(Text), findsOneWidget);
    expect(find.text('Watch'), findsOneWidget);
    expect(find.byWidget(page), findsOneWidget);
  });
}

class TestController extends Controller {
  final Function onViewDidChangeDependencies;
  final Function onViewInitState;
  final Function onViewDeactivated;

  TestController(
      {required this.onViewDidChangeDependencies,
      required this.onViewInitState,
      required this.onViewDeactivated});

  @override
  void initListeners() {}

  @override
  void onInitState() {
    onViewInitState();
  }

  @override
  void onDidChangeDependencies() {
    onViewDidChangeDependencies();
  }

  @override
  void onDeactivated() {
    onViewDeactivated();
  }
}

class TestPage extends CleanView {
  final TestController controller;

  TestPage({Key? key, required this.controller}) : super(key: key);

  @override
  _TestPageState createState() => _TestPageState(controller);
}

class _TestPageState extends ResponsiveViewState<TestPage, TestController> {
  _TestPageState(TestController controller) : super(controller);

  @override
  Widget get desktopView =>
      Container(key: globalKey, child: Center(child: Text('Desktop')));

  @override
  Widget get mobileView =>
      Container(key: globalKey, child: Center(child: Text('Mobile')));

  @override
  Widget get tabletView =>
      Container(key: globalKey, child: Center(child: Text('Tablet')));

  @override
  Widget get watchView =>
      Container(key: globalKey, child: Center(child: Text('Watch')));
}

/// This is a snippet to change the default value of test flutter emulator size.
/// Flutter's Test Emulator by default simulates a 800x600 screen size.
extension SetScreenSize on WidgetTester {
  Future<void> setScreenSize({
    required double width,
    required double height,
    double pixelDensity = 1,
  }) async {
    final size = Size(width, height);
    await binding.setSurfaceSize(size);
    binding.window.physicalSizeTestValue = size;
    binding.window.devicePixelRatioTestValue = pixelDensity;
  }
}
