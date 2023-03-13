import 'package:example/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:example/main.dart' as test_main;

void main() {
  testWidgets('main ...', (tester) async {
    await tester.pumpWidget(MyApp());
    expect(find.text('Flutter Clean Demo Page'), findsOneWidget);
  });
}
