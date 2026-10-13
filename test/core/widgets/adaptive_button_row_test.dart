import 'package:careermatebd/core/widgets/adaptive_button_row.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester, {required double textScale}) async {
    // iPhone SE width.
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: EdgeInsets.all(18),
            child: AdaptiveButtonRow(
              secondary: SecondaryButton(label: 'Cover letter', onPressed: null),
              primary: PrimaryButton(label: 'Save & export', onPressed: null),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('sits side by side at normal text', (tester) async {
    await pump(tester, textScale: 1.0);

    final secondary = tester.getRect(find.byType(SecondaryButton));
    final primary = tester.getRect(find.byType(PrimaryButton));
    expect(secondary.top, primary.top);
    expect(secondary.right, lessThan(primary.left));
    expect(tester.takeException(), isNull);
  });

  testWidgets('still side by side at 1.3x', (tester) async {
    await pump(tester, textScale: 1.3);

    expect(
      tester.getRect(find.byType(SecondaryButton)).top,
      tester.getRect(find.byType(PrimaryButton)).top,
    );
  });

  testWidgets('stacks, primary on top and full width, above 1.3x', (
    tester,
  ) async {
    await pump(tester, textScale: 1.5);

    final secondary = tester.getRect(find.byType(SecondaryButton));
    final primary = tester.getRect(find.byType(PrimaryButton));
    expect(primary.bottom, lessThanOrEqualTo(secondary.top));
    expect(primary.width, secondary.width);
    expect(primary.width, closeTo(375 - 36, 1), reason: 'full width');
    expect(tester.takeException(), isNull);
  });
}
