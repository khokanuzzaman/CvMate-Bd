import 'package:careermatebd/core/widgets/app_chip.dart';
import 'package:careermatebd/core/widgets/choice_chips.dart';
import 'package:careermatebd/core/widgets/picker_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: child)),
  ),
);

void main() {
  group('ChoiceChips', () {
    testWidgets('marks the chosen option and reports taps', (tester) async {
      String? picked;
      await _pump(
        tester,
        ChoiceChips<String>(
          options: const ['One', 'Two', 'Three'],
          value: 'Two',
          labelOf: (option) => option,
          onChanged: (value) => picked = value,
        ),
      );

      AppChipVariant variant(String label) =>
          tester.widget<AppChip>(find.widgetWithText(AppChip, label)).variant;
      expect(variant('Two'), AppChipVariant.selected);
      expect(variant('One'), AppChipVariant.neutral);

      await tester.tap(find.text('Three'));
      expect(picked, 'Three');
    });

    testWidgets('every chip is a 48dp-high touch target', (tester) async {
      await _pump(
        tester,
        ChoiceChips<int>(
          options: const [1, 2],
          value: 1,
          labelOf: (option) => 'Option $option',
          onChanged: (_) {},
        ),
      );

      for (final label in ['Option 1', 'Option 2']) {
        final target = find
            .ancestor(
              of: find.text(label),
              matching: find.byType(GestureDetector),
            )
            .first;
        expect(tester.getSize(target).height, greaterThanOrEqualTo(48));
      }
    });

    testWidgets('tapping just outside the visible chip still selects it', (
      tester,
    ) async {
      var taps = 0;
      await _pump(
        tester,
        ChoiceChips<int>(
          options: const [1],
          value: 0,
          labelOf: (option) => 'Option',
          onChanged: (_) => taps++,
        ),
      );
      final label = tester.getCenter(find.text('Option'));

      // 20dp above the label's centre is above the visible chip (about 17dp
      // each way) but still inside the 48dp touch target (24dp each way).
      await tester.tapAt(Offset(label.dx, label.dy - 20));

      expect(taps, 1);
    });
  });

  group('AppChip', () {
    testWidgets('a long label shrinks with an ellipsis instead of overflowing', (
      tester,
    ) async {
      await _pump(
        tester,
        const SizedBox(
          width: 120,
          child: Wrap(
            children: [
              AppChip(
                label:
                    'A very long keyword that cannot possibly fit in the width',
              ),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('PickerField', () {
    testWidgets('shows the value and opens on tap; clear is optional', (
      tester,
    ) async {
      var opened = 0;
      var cleared = 0;
      await _pump(
        tester,
        PickerField(
          label: 'Deadline',
          value: '12 Sep 2026',
          onTap: () => opened++,
          onClear: () => cleared++,
          clearTooltip: 'Clear date',
        ),
      );

      await tester.tap(find.text('12 Sep 2026'));
      expect(opened, 1);
      await tester.tap(find.byTooltip('Clear date'));
      expect(cleared, 1);
    });

    testWidgets('has no clear button without onClear', (tester) async {
      await _pump(
        tester,
        PickerField(label: 'Deadline', value: 'Optional', onTap: () {}),
      );

      expect(find.byIcon(Icons.close_rounded), findsNothing);
    });
  });

  group('showOptionSheet', () {
    Future<String?> open(WidgetTester tester, {String? noneLabel}) async {
      String? result = 'unset';
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async => result = await showOptionSheet(
                  context,
                  title: 'Pick one',
                  selectedId: 'b',
                  noneLabel: noneLabel,
                  options: const [
                    OptionItem(id: 'a', title: 'Alpha', subtitle: 'first'),
                    OptionItem(id: 'b', title: 'Beta'),
                  ],
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('lists the options and returns the chosen id', (tester) async {
      await open(tester);
      expect(find.text('Pick one'), findsOneWidget);
      expect(find.text('first'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();
      // The sheet closed.
      expect(find.text('Pick one'), findsNothing);
    });

    testWidgets('offers a none entry when asked', (tester) async {
      await open(tester, noneLabel: 'Nothing');

      expect(find.text('Nothing'), findsOneWidget);
    });
  });
}
