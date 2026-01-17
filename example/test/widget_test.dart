import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example/main.dart';

void main() {
  group('CleanArchitectureExampleApp', () {
    testWidgets('should render the app with MaterialApp',
        (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const CleanArchitectureExampleApp());

      // Verify the app renders with the correct title
      expect(find.text('Clean Architecture Demo'), findsOneWidget);
    });

    testWidgets('should show empty state when no todos exist',
        (WidgetTester tester) async {
      await tester.pumpWidget(const CleanArchitectureExampleApp());

      // Wait for initial loading
      await tester.pumpAndSettle();

      // Should show empty state
      expect(find.text('No todos yet!'), findsOneWidget);
      expect(find.text('Add one above to get started.'), findsOneWidget);
    });

    testWidgets('should have a text field for adding todos',
        (WidgetTester tester) async {
      await tester.pumpWidget(const CleanArchitectureExampleApp());
      await tester.pumpAndSettle();

      // Should have a text field with placeholder
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('What needs to be done?'), findsOneWidget);
    });

    testWidgets('should have an Add button', (WidgetTester tester) async {
      await tester.pumpWidget(const CleanArchitectureExampleApp());
      await tester.pumpAndSettle();

      // Should have an Add button
      expect(find.widgetWithText(ElevatedButton, 'Add'), findsOneWidget);
    });

    testWidgets('should have a calculate prime button in app bar',
        (WidgetTester tester) async {
      await tester.pumpWidget(const CleanArchitectureExampleApp());
      await tester.pumpAndSettle();

      // Should have a calculate icon button
      expect(find.byIcon(Icons.calculate), findsOneWidget);
    });

    testWidgets('should create a todo when text is entered and Add is pressed',
        (WidgetTester tester) async {
      await tester.pumpWidget(const CleanArchitectureExampleApp());
      await tester.pumpAndSettle();

      // Enter text
      await tester.enterText(find.byType(TextField), 'Buy groceries');
      await tester.pumpAndSettle();

      // Tap Add button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
      await tester.pumpAndSettle();

      // Should show the todo in the list
      expect(find.text('Buy groceries'), findsOneWidget);

      // Empty state should be gone
      expect(find.text('No todos yet!'), findsNothing);
    });

    testWidgets('should show stats footer when todos exist',
        (WidgetTester tester) async {
      await tester.pumpWidget(const CleanArchitectureExampleApp());
      await tester.pumpAndSettle();

      // Create a todo
      await tester.enterText(find.byType(TextField), 'Test todo');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
      await tester.pumpAndSettle();

      // Should show stats
      expect(find.text('1 active'), findsOneWidget);
      expect(find.text('0 completed'), findsOneWidget);
    });

    testWidgets('should toggle todo when checkbox is tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(const CleanArchitectureExampleApp());
      await tester.pumpAndSettle();

      // Create a todo
      await tester.enterText(find.byType(TextField), 'Toggle me');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
      await tester.pumpAndSettle();

      // Verify initial stats
      expect(find.text('1 active'), findsOneWidget);
      expect(find.text('0 completed'), findsOneWidget);

      // Tap the checkbox
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      // Stats should update
      expect(find.text('0 active'), findsOneWidget);
      expect(find.text('1 completed'), findsOneWidget);
    });

    testWidgets('should delete todo when swiped', (WidgetTester tester) async {
      await tester.pumpWidget(const CleanArchitectureExampleApp());
      await tester.pumpAndSettle();

      // Create a todo
      await tester.enterText(find.byType(TextField), 'Delete me');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
      await tester.pumpAndSettle();

      // Verify todo exists
      expect(find.text('Delete me'), findsOneWidget);

      // Swipe to delete
      await tester.drag(find.text('Delete me'), const Offset(-500, 0));
      await tester.pumpAndSettle();

      // Todo should be gone
      expect(find.text('Delete me'), findsNothing);

      // Should show empty state again
      expect(find.text('No todos yet!'), findsOneWidget);
    });

    testWidgets('should clear text field after adding todo',
        (WidgetTester tester) async {
      await tester.pumpWidget(const CleanArchitectureExampleApp());
      await tester.pumpAndSettle();

      // Enter text
      await tester.enterText(find.byType(TextField), 'My todo');

      // Verify text is in field
      expect(find.text('My todo'), findsOneWidget);

      // Tap Add
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
      await tester.pumpAndSettle();

      // Text field should be cleared (find only in list, not in TextField)
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);
    });

    testWidgets('should not add empty todo', (WidgetTester tester) async {
      await tester.pumpWidget(const CleanArchitectureExampleApp());
      await tester.pumpAndSettle();

      // Tap Add without entering text
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
      await tester.pumpAndSettle();

      // Should still show empty state (no todo created)
      expect(find.text('No todos yet!'), findsOneWidget);
    });

    testWidgets('should open prime calculation dialog when icon is tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(const CleanArchitectureExampleApp());
      await tester.pumpAndSettle();

      // Tap the calculate icon
      await tester.tap(find.byIcon(Icons.calculate));
      await tester.pumpAndSettle();

      // Dialog should appear
      expect(find.text('Calculate Prime'), findsOneWidget);
      expect(find.text('CALCULATE'), findsOneWidget);
      expect(find.text('CANCEL'), findsOneWidget);
    });

    testWidgets('should close dialog when CANCEL is tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(const CleanArchitectureExampleApp());
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.byIcon(Icons.calculate));
      await tester.pumpAndSettle();

      // Tap CANCEL
      await tester.tap(find.text('CANCEL'));
      await tester.pumpAndSettle();

      // Dialog should be closed
      expect(find.text('Calculate Prime'), findsNothing);
    });

    testWidgets('should create multiple todos', (WidgetTester tester) async {
      await tester.pumpWidget(const CleanArchitectureExampleApp());
      await tester.pumpAndSettle();

      // Create first todo
      await tester.enterText(find.byType(TextField), 'First todo');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
      await tester.pumpAndSettle();

      // Create second todo
      await tester.enterText(find.byType(TextField), 'Second todo');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
      await tester.pumpAndSettle();

      // Create third todo
      await tester.enterText(find.byType(TextField), 'Third todo');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
      await tester.pumpAndSettle();

      // All todos should be visible
      expect(find.text('First todo'), findsOneWidget);
      expect(find.text('Second todo'), findsOneWidget);
      expect(find.text('Third todo'), findsOneWidget);

      // Stats should be correct
      expect(find.text('3 active'), findsOneWidget);
      expect(find.text('0 completed'), findsOneWidget);
    });
  });
}
