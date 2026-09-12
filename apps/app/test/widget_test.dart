// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:app/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the demo sign-in flow', (WidgetTester tester) async {
    await tester.pumpWidget(const SrkApp());

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in to LandDesk'), findsOneWidget);

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Good morning, Arjun'), findsOneWidget);
    expect(find.text('Recent verifications'), findsOneWidget);
  });
}
