import 'package:careermatebd/core/widgets/custom_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('stays reachable on a small screen at 2x text', (tester) async {
    // iPhone SE (3rd gen) minus the app bar and the bottom nav.
    tester.view.physicalSize = const Size(375, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    var added = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(22),
            child: CustomEmptyState(
              title: 'No applications yet',
              message:
                  'Track your first application to see interviews, follow-ups '
                  'and linked CVs in one place.',
              actionLabel: 'Add application',
              onAction: () => added++,
            ),
          ),
        ),
      ),
    );

    // A RenderFlex overflow is reported as an exception.
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(find.text('Add application'), 100);
    await tester.tap(find.text('Add application'));
    expect(added, 1, reason: 'the action must be reachable by scrolling');
  });

  testWidgets('is still centered when there is room', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CustomEmptyState(title: 'Nothing here', message: 'Empty.'),
        ),
      ),
    );

    final center = tester.getCenter(find.text('Nothing here'));
    expect(center.dy, closeTo(400, 80));
  });
}
