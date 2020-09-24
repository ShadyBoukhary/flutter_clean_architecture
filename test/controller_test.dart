import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';

GlobalKey snackBar = GlobalKey();
GlobalKey inc = GlobalKey();

void main() {
  testWidgets('Controller can change data and refresh View',
      (WidgetTester tester) async {
    final AutomatedTestWidgetsFlutterBinding binding = tester.binding;
    binding.addTime(const Duration(seconds: 3));
    await tester.pumpWidget(MaterialApp(
      home: CounterPage(),
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
  @override
  State<StatefulWidget> createState() => CounterState();
}

class CounterState extends ViewState<CounterPage, CounterController> {
  CounterState() : super(CounterController());

  @override
  Widget get view {
    return Scaffold(
      key: globalKey,
      body: Column(
        children: <Widget>[
          Center(
            child: ControlledWidget<CounterController>(
              builder: (ctx, controller) {
                return Text(controller.counter.toString());
              },
            ),
          ),
          ControlledWidget<CounterController>(
            builder: (ctx, controller) {
              return MaterialButton(
                  key: inc, onPressed: () => controller.increment());
            },
          ),
          ControlledWidget<CounterController>(
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
