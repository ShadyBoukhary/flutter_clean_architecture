import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';

CounterController controller = CounterController();
void main() {
  testWidgets('Controller can change data and refresh View',
      (WidgetTester tester) async {
    final AutomatedTestWidgetsFlutterBinding binding = tester.binding;
    binding.addTime(const Duration(seconds: 3));
    await tester.pumpWidget(CounterPage());

    // Create our Finders
    Finder counterFinder = find.text('0');
    expect(counterFinder, findsOneWidget);

    await tester.tap(find.byType(MaterialButton));
    await tester.pump();

    expect(counterFinder, findsNothing);
    counterFinder = find.text('1');
    expect(counterFinder, findsOneWidget);

    await tester.tap(find.byType(MaterialButton));
    await tester.pump();

    expect(counterFinder, findsNothing);
    counterFinder = find.text('2');
    expect(counterFinder, findsOneWidget);
    controller.showSnackBar();
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
  State<StatefulWidget> createState() => CounterState(controller);
}

class CounterState extends ViewState<CounterPage, CounterController> {
  CounterState(CounterController controller) : super(controller);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: Scaffold(
        key: globalKey,
        body: Column(
          children: <Widget>[
            Center(
              child: Text(controller.counter.toString()),
            ),
            MaterialButton(onPressed: () => callHandler(controller.increment)),
          ],
        ),
      ),
    );
  }
}
