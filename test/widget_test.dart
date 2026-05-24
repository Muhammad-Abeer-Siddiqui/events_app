import 'package:events_app/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows Firebase setup instructions without config', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FirebaseSetupApp());

    expect(find.text('Firebase setup needed'), findsOneWidget);
    expect(find.text('FIREBASE_WEB_API_KEY'), findsOneWidget);
    expect(find.text('FIREBASE_PROJECT_ID'), findsOneWidget);
  });
}
