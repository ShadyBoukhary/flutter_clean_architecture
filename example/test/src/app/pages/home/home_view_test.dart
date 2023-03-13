import 'package:example/src/app/pages/home/home_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'Given Add Button when click then increment counter and display Button pressed 1 times. text',
      (tester) async {
    final binding = tester.binding;
    binding.addTime(const Duration(seconds: 3));
    await tester.pumpWidget(const MaterialApp(
      home: HomePage(key: Key('homePage'), title: 'Flutter Demo Home Page'),
    ));
    expect(find.byKey(const Key('homePage')), findsOneWidget);
    await tester.tap(find.widgetWithIcon(FloatingActionButton, Icons.add));
    await tester.pump();
    var counterFinder = find.text('Button pressed 1 times.');
    expect(counterFinder, findsOneWidget);
  });

  testWidgets(
      'Given Get User Button when click then display John Smith, 18 text',
      (tester) async {
    final binding = tester.binding;
    binding.addTime(const Duration(seconds: 3));
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
    final binding = tester.binding;
    binding.addTime(const Duration(seconds: 3));
    await tester.pumpWidget(const MaterialApp(
      home: HomePage(key: Key('homePage'), title: 'Flutter Demo Home Page'),
    ));
    expect(find.byKey(const Key('homePage')), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Get User Error'));
    await tester.pump();
    var counterFinder = find.text('No element');
    expect(counterFinder, findsOneWidget);
  });
}
