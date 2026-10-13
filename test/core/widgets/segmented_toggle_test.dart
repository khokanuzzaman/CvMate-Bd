import 'package:careermatebd/core/widgets/segmented_toggle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const options = [
    SegmentedOption(value: 1, label: 'One'),
    SegmentedOption(value: 2, label: 'Two'),
    SegmentedOption(value: 3, label: 'Three'),
  ];

  Future<void> pump(
    WidgetTester tester, {
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SegmentedToggle<int>(
            options: options,
            value: value,
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  testWidgets('marks the selected segment and reports taps', (tester) async {
    int? picked;
    await pump(tester, value: 1, onChanged: (v) => picked = v);

    expect(
      tester.getSemantics(find.bySemanticsLabel('One')),
      matchesSemantics(
        label: 'One',
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        hasTapAction: true,
        hasFocusAction: false,
        isFocusable: false,
      ),
    );

    await tester.tap(find.text('Three'));
    expect(picked, 3);
  });

  testWidgets('every segment is at least 48dp tall and equally wide', (
    tester,
  ) async {
    await pump(tester, value: 2, onChanged: (_) {});

    final sizes = [
      for (final label in ['One', 'Two', 'Three'])
        tester.getSize(
          find
              .ancestor(of: find.text(label), matching: find.byType(Container))
              .first,
        ),
    ];
    for (final size in sizes) {
      expect(size.height, greaterThanOrEqualTo(48));
    }
    expect(sizes[0].width, sizes[1].width);
    expect(sizes[1].width, sizes[2].width);
  });

  testWidgets('stacks the segments at large text instead of squeezing them', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    int? picked;
    await pump(tester, value: 1, onChanged: (v) => picked = v);

    final one = tester.getRect(find.text('One'));
    final two = tester.getRect(find.text('Two'));
    final three = tester.getRect(find.text('Three'));
    expect(one.bottom, lessThanOrEqualTo(two.top));
    expect(two.bottom, lessThanOrEqualTo(three.top));
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Three'));
    expect(picked, 3);
  });
}
