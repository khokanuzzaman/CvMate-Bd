import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/core/widgets/app_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: Center(child: child)));
}

void main() {
  group('PrimaryButton', () {
    testWidgets('renders its label and fires onPressed when tapped', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(PrimaryButton(label: 'Tailor my CV', onPressed: () => taps++)),
      );

      expect(find.text('Tailor my CV'), findsOneWidget);

      await tester.tap(find.text('Tailor my CV'));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('is disabled and does not fire when onPressed is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const PrimaryButton(label: 'Disabled', onPressed: null)),
      );

      expect(find.text('Disabled'), findsOneWidget);
      // Tapping a disabled button must be a no-op (no exception, no callback).
      await tester.tap(find.text('Disabled'));
      await tester.pump();
    });

    testWidgets('renders an optional trailing icon', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PrimaryButton(
            label: 'Continue',
            trailingIcon: Icons.arrow_forward_rounded,
            onPressed: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
    });
  });

  group('AppChip', () {
    testWidgets('every variant renders its label', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Wrap(
            children: [
              AppChip(label: 'Neutral'),
              AppChip(label: 'Selected', variant: AppChipVariant.selected),
              AppChip(label: 'Matched', variant: AppChipVariant.matched),
              AppChip(label: 'Missing', variant: AppChipVariant.missing),
              AppChip(label: 'Removable', variant: AppChipVariant.removable),
            ],
          ),
        ),
      );

      for (final label in ['Neutral', 'Selected', 'Matched', 'Missing', 'Removable']) {
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets('missing variant shows a leading "+" icon', (tester) async {
      await tester.pumpWidget(
        _wrap(const AppChip(label: 'TypeScript', variant: AppChipVariant.missing)),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('removable variant shows "×" and fires onRemove', (tester) async {
      var removed = 0;
      await tester.pumpWidget(
        _wrap(
          AppChip(
            label: 'React',
            variant: AppChipVariant.removable,
            onRemove: () => removed++,
          ),
        ),
      );

      expect(find.byIcon(Icons.close), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(removed, 1);
    });
  });
}
