import 'package:careermatebd/core/widgets/app_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final variant in AppChipVariant.values) {
    testWidgets(
      'a very long ${variant.name} label wraps instead of overflowing',
      (tester) async {
        tester.view.physicalSize = const Size(375, 667);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        tester.platformDispatcher.textScaleFactorTestValue = 1.5;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(18),
                // Chips live in Wraps, which give each one at most the full width.
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AppChip(
                      label:
                          'Compassionate Registered Nurse Intensive Care Unit',
                      variant: variant,
                      onRemove: variant == AppChipVariant.removable
                          ? () {}
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        // A RenderFlex overflow is reported as an exception.
        expect(tester.takeException(), isNull);
        expect(
          tester.getRect(find.byType(AppChip)).right,
          lessThanOrEqualTo(375 - 18),
        );
      },
    );
  }
}
