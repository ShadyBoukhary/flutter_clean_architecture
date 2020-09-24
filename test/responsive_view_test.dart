import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';

void main() {
  testWidgets('Run TestPage | Mobile viewport then resizes',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    final page = TestPage();

    await tester.setScreenSize(width: 540, height: 540);

    await tester.pumpWidget(MaterialApp(home: page));

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Mobile'), findsOneWidget);

    await tester.setScreenSize(width: 700, height: 600);

    await tester.pumpAndSettle();

    expect(find.text('Tablet'), findsOneWidget);

    await tester.setScreenSize(width: 1024, height: 1024);

    await tester.pumpAndSettle();

    expect(find.text('Desktop'), findsOneWidget);
  });

  testWidgets('Run TestPage | Mobile Viewport', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    final page = TestPage();

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
    // Build our app and trigger a frame.
    final page = TestPage();

    await tester.setScreenSize(width: 700, height: 600);

    await tester
        .pumpWidget(MaterialApp(home: Container(child: page, width: 800)));

    expect(find.byType(Container), findsWidgets);
    expect(find.byType(Text), findsOneWidget);
    expect(find.text('Tablet'), findsOneWidget);
    expect(find.byWidget(page), findsOneWidget);
  });

  testWidgets('Run TestPage | Desktop Viewport', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    final page = TestPage();

    await tester.setScreenSize(width: 1024, height: 1024);

    await tester
        .pumpWidget(MaterialApp(home: Container(child: page, width: 1500)));

    expect(find.byType(Container), findsWidgets);
    expect(find.byType(Text), findsOneWidget);
    expect(find.text('Desktop'), findsOneWidget);
    expect(find.byWidget(page), findsOneWidget);
  });

  testWidgets('Run TestPage | Watch Viewport', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    final page = TestPage();

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
  @override
  void initListeners() {}
}

class TestPage extends View {
  TestPage({Key key}) : super(key: key);

  @override
  _TestPageState createState() => _TestPageState(TestController());
}

class _TestPageState extends ResponsiveViewState<TestPage, TestController> {
  _TestPageState(TestController controller) : super(controller);

  @override
  ViewBuilder desktopBuilder = (BuildContext context) {
    return Container(child: Center(child: Text('Desktop')));
  };

  @override
  ViewBuilder mobileBuilder = (BuildContext context) {
    return Container(child: Center(child: Text('Mobile')));
  };

  @override
  ViewBuilder tabletBuilder = (BuildContext context) {
    return Container(child: Center(child: Text('Tablet')));
  };

  @override
  ViewBuilder watchBuilder = (BuildContext context) {
    return Container(child: Center(child: Text('Watch')));
  };
}

/// This is a snippet to change the default value of test flutter emulator size.
/// Flutter's Test Emulator by default simulates a 800x600 screen size.
extension SetScreenSize on WidgetTester {
  Future<void> setScreenSize({
    @required double width,
    @required double height,
    double pixelDensity = 1,
  }) async {
    final size = Size(width, height);
    await binding.setSurfaceSize(size);
    binding.window.physicalSizeTestValue = size;
    binding.window.devicePixelRatioTestValue = pixelDensity;
  }
}
