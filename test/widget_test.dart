import 'package:events_app/firebase_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Firebase options are configured for iOS', () {
    final options = DefaultFirebaseOptions.ios;
    expect(options.apiKey, isNotEmpty);
    expect(options.projectId, 'events-app-48a05');
  });
}
