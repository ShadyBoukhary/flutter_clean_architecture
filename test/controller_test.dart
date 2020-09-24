import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';

GlobalKey snackBar = GlobalKey();
GlobalKey inc = GlobalKey();

void main() {
  var numberOfWidgetBuilds = 0;
  var numberOfUncontrolledWidgetBuilds = 0;
  var numberOfControlledWidgetBuilds = 0;

  testWidgets('Controller can change data and refresh View',
      (WidgetTester tester) async {
    final AutomatedTestWidgetsFlutterBinding binding = tester.binding;
    binding.addTime(const Duration(seconds: 3));
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
      ),
    ));

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
  });
}

class CounterController extends Controller {
  int counter;
  CounterController() : counter = 0;

  void increment() {
    counter++;
    refreshUI();
  }

  void showSnackBar() {
    ScaffoldState scaffoldState = getState();
    scaffoldState.showSnackBar(SnackBar(content: Text('Hi')));
  }

  @override
  void initListeners() {
    // No presenter needed for controller test
  }
}

class CounterPage extends View {
  final Function onWidgetBuild;
  final Function onUncontrolledWidgetBuild;
  final Function onControlledWidgetBuild;

  CounterPage(
      {this.onWidgetBuild,
      this.onUncontrolledWidgetBuild,
      this.onControlledWidgetBuild});

  @override
  State<StatefulWidget> createState() => CounterState();
}

class CounterState extends ViewState<CounterPage, CounterController> {
  CounterState() : super(CounterController());

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
                  key: snackBar, onPressed: () => controller.showSnackBar());
            },
          ),
        ],
      ),
    );
  }
}
