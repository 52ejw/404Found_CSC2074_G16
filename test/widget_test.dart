import 'package:flutter_test/flutter_test.dart';

import 'package:found404/app/app.dart';
import 'package:found404/app/constants.dart';

void main() {
  testWidgets('App renders the placeholder home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    // Let the Firebase connectivity check's Future settle (no real Firebase
    // app exists in this widget test, so it resolves to an error message —
    // we're only asserting the screen itself renders without crashing).
    await tester.pump();

    expect(find.text(AppConstants.appName), findsWidgets);
  });
}
