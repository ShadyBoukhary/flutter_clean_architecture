import 'package:example/src/app/pages/home/home_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'Given Add Button when click then increment counter and display Button pressed 1 times. text',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: HomePage(key: Key('homePage'), title: 'Flutter Demo Home Page'),
    ));
    expect(find.byKey(const Key('homePage')), findsOneWidget);
    await tester.tap(find.widgetWithIcon(FloatingActionButton, Icons.add));
    await tester.pumpAndSettle();
    var counterFinder = find.text('Button pressed 1 times.');
    expect(counterFinder, findsOneWidget);
  });

  testWidgets(
      'Given Get User Button when click then display John Smith, 18 text',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: HomePage(key: Key('homePage'), title: 'Flutter Demo Home Page'),
    ));
    expect(find.byKey(const Key('homePage')), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Get User'));
    await tester.pump();
    var counterFinder = find.text('John Smith, 18');
    expect(counterFinder, findsOneWidget);
  });

  testWidgets(
      'Given Get User Button when click then display John Smith, 18 text',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: HomePage(key: Key('homePage'), title: 'Flutter Demo Home Page'),
    ));
    expect(find.byKey(const Key('homePage')), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Get User Error'));
    await tester.pump();
    var counterFinder = find.text('No element');
    expect(counterFinder, findsOneWidget);
  });

  testWidgets('Trigger Reassemble', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: HomePage(key: Key('homePage'), title: 'Flutter Demo Home Page'),
    ));

    tester.binding.reassembleApplication();
    tester.idle();
  });
  testWidgets('Trigger Resumed', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: HomePage(key: Key('homePage'), title: 'Flutter Demo Home Page'),
    ));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });
}
