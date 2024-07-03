import 'package:flutter/material.dart' hide View;
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';

GlobalKey snackBar = GlobalKey();
GlobalKey inc = GlobalKey();

void main() {
  var stateInitialized = false;
  var viewDidChangeViewDependenciesTriggered = false;
  var stateDeactivated = false;
  var numberOfWidgetBuilds = 0;
  var numberOfUncontrolledWidgetBuilds = 0;
  var numberOfControlledWidgetBuilds = 0;

  testWidgets('Controller can change data and refresh View',
      (WidgetTester tester) async {
    // await Future.delayed(const Duration(seconds: 3));

    await tester.pumpWidget(MaterialApp(
      home: CounterPage(
        onWidgetBuild: () {
          numberOfWidgetBuilds++;
        },
        onUncontrolledWidgetBuild: () {
          numberOfUncontrolledWidgetBuilds++;
        },
        onControlledWidgetBuild: () {
          numberOfControlledWidgetBuilds++;
        },
        controller: CounterController(
          onViewDeactivated: () {
            stateDeactivated = true;
          },
          onViewDidChangeDependencies: () {
            viewDidChangeViewDependenciesTriggered = true;
          },
          onViewInitState: () {
            stateInitialized = true;
          },
        ),
      ),
    ));

    expect(stateInitialized, isTrue);
    expect(viewDidChangeViewDependenciesTriggered, isTrue);
    // Create our Finders
    var counterFinder = find.text('0');
    expect(counterFinder, findsOneWidget);

    await tester.tap(find.byKey(inc));
    await tester.pump();

    expect(counterFinder, findsNothing);
    counterFinder = find.text('1');
    expect(counterFinder, findsOneWidget);

    await tester.tap(find.byKey(inc));
    await tester.pump();

    expect(counterFinder, findsNothing);
    counterFinder = find.text('2');
    expect(counterFinder, findsOneWidget);

    await tester.tap(find.byKey(snackBar));
    await tester.pump();
    expect(find.text('Hi'), findsOneWidget);

    expect(numberOfWidgetBuilds, equals(1));
    expect(numberOfUncontrolledWidgetBuilds, equals(1));
    expect(numberOfControlledWidgetBuilds, equals(3));

    // To remove page from tree
    await tester.pumpWidget(Container());

    expect(stateDeactivated, isTrue);
  });
}

class CounterController extends Controller {
  final Function onViewDidChangeDependencies;
  final Function onViewInitState;
  final Function onViewDeactivated;

  late int counter;

  CounterController(
      {required this.onViewDidChangeDependencies,
      required this.onViewInitState,
      required this.onViewDeactivated});

  void increment() {
    counter++;
    refreshUI();
  }

  void showSnackBar(context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hi')));
  }

  @override
  void initListeners() {
    // No presenter needed for controller test
  }

  @override
  void onInitState() {
    onViewInitState();
  }

  @override
  void onDidChangeDependencies() {
    onViewDidChangeDependencies();
    counter = 0;
  }

  @override
  void onDeactivated() {
    onViewDeactivated();
  }
}

class CounterPage extends View {
  final CounterController controller;
  final Function onWidgetBuild;
  final Function onControlledWidgetBuild;
  final Function onUncontrolledWidgetBuild;

  CounterPage(
      {required this.onWidgetBuild,
      required this.onUncontrolledWidgetBuild,
      required this.onControlledWidgetBuild,
      required this.controller});

  @override
  State<StatefulWidget> createState() => CounterState(controller: controller);
}

class CounterState extends ViewState<CounterPage, CounterController> {
  CounterState({required CounterController controller}) : super(controller);

  @override
  Widget get view {
    widget.onWidgetBuild();

    return Scaffold(
      key: globalKey,
      body: Column(
        children: <Widget>[
          Center(
            child: Builder(
              builder: (BuildContext context) {
                widget.onUncontrolledWidgetBuild();

                return Text('Uncontrolled text');
              },
            ),
          ),
          Center(
            child: ControlledWidgetBuilder<CounterController>(
              builder: (ctx, controller) {
                widget.onControlledWidgetBuild();

                return Text(controller.counter.toString());
              },
            ),
          ),
          ControlledWidgetBuilder<CounterController>(
            builder: (ctx, controller) {
              return MaterialButton(
                  key: inc, onPressed: () => controller.increment());
            },
          ),
          ControlledWidgetBuilder<CounterController>(
            builder: (ctx, controller) {
              return MaterialButton(
                  key: snackBar, onPressed: () => controller.showSnackBar(context));
            },
          ),
        ],
      ),
    );
  }
}
