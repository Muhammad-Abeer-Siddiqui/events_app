import 'package:events_app/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows demo auth screen', (tester) async {
    await tester.pumpWidget(const CampusLoopApp());
    await tester.pumpAndSettle();

    expect(find.text('CampusLoop'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });
}
