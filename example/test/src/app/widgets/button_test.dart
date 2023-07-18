import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart' as clean;
import 'package:flutter_test/flutter_test.dart';

import 'package:example/src/app/pages/home/home_controller.dart';
import 'package:example/src/app/widgets/button.dart';
import 'package:example/src/data/repositories/data_users_repository.dart';

void main() {
  testWidgets(
      'Given stateless button when homepagebutton is added to parent widget then return homepagebutton',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
      body: TestPage(),
    )));

    final buttonFinder = find.byType(HomePageButton);
    expect(buttonFinder, findsOneWidget);

    final textFinder = find.text('Get User');
    expect(textFinder, findsOneWidget);

    await tester.tap(buttonFinder);
    await tester.pump();
  });
}

class TestPage extends clean.View {
  const TestPage({
    Key? key,
  }) : super(key: key);

  @override
  TestPageState createState() => TestPageState();
}

class TestPageState extends clean.ViewState<TestPage, HomeController> {
  TestPageState() : super(HomeController(DataUsersRepository()));

  @override
  Widget get view =>
      Scaffold(key: globalKey, body: const HomePageButton(text: 'Get User'));
}
