import 'package:events_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows campus events and sends a global chat message', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CampusLoopApp());

    expect(find.text('CampusLoop'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Test Student');
    await tester.enterText(find.byType(TextFormField).at(1), 'UCP');
    await tester.enterText(find.byType(TextFormField).at(2), 'test@ucp.edu.pk');
    await tester.enterText(find.byType(TextFormField).at(3), 'campus123');
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('AI Startup Weekend'), findsOneWidget);

    await tester.tap(find.text('Global'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Is the music night open?');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();

    expect(find.text('Is the music night open?'), findsOneWidget);
  });
}
