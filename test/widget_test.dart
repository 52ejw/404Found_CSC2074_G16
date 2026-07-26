import 'package:flutter_test/flutter_test.dart';

import 'package:found404/app/app.dart';
import 'package:found404/app/constants.dart';

void main() {
  testWidgets('App renders the placeholder home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const App());

    expect(find.text(AppConstants.appName), findsWidgets);
  });
}
