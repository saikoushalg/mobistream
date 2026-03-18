import 'package:flutter_test/flutter_test.dart';

import 'package:app/main.dart';

void main() {
  testWidgets('Mobistream app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MobistreamApp());

    // Verify that the app title is present.
    expect(find.text('Mobistream'), findsOneWidget);
  });
}
