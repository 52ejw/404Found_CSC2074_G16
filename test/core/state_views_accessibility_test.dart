import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:found404/core/widgets/state_views.dart';

void main() {
  testWidgets('loading state announces its message', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(home: LoadingView(message: 'Loading claims')),
    );

    expect(find.bySemanticsLabel('Loading claims'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('error state announces the error and provides retry', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: ErrorRetryView(
          message: 'Network unavailable',
          onRetry: () => retried = true,
        ),
      ),
    );

    expect(
      find.bySemanticsLabel('Something went wrong. Network unavailable'),
      findsOneWidget,
    );
    await tester.tap(find.text('Retry'));
    expect(retried, isTrue);
    handle.dispose();
  });

  testWidgets('empty state exposes title and guidance together', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: EmptyView(
          title: 'No conversations yet',
          subtitle: 'Open a post to start a chat.',
        ),
      ),
    );

    expect(
      find.bySemanticsLabel(
        'No conversations yet. Open a post to start a chat.',
      ),
      findsOneWidget,
    );
    handle.dispose();
  });
}
