import 'package:careermatebd/core/widgets/bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The bar's fixed content height; the widget adds a 1px top hairline border.
const double _barContentHeight = 64;
const double _hairline = 1;

/// Pumps the real [BottomNavBar] on a 390px-wide phone surface.
Future<List<int>> _pumpNavBar(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final taps = <int>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        bottomNavigationBar: BottomNavBar(currentIndex: 0, onTap: taps.add),
      ),
    ),
  );
  return taps;
}

Finder get _centerCircle => find.ancestor(
  of: find.byIcon(Icons.gps_fixed),
  matching: find.byType(Container),
);

void main() {
  testWidgets('labels cap their text scale: no overflow at 2x', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pumpNavBar(tester);

    // A RenderFlex overflow is reported as an exception.
    expect(tester.takeException(), isNull);
    // "Tracker" stays on one line ("Tracke / r" before).
    expect(tester.getSize(find.text('Tracker')).height, lessThan(24));
  });

  group('BottomNavBar (390px wide)', () {
    testWidgets('lays out without overflow and keeps the 64px bar height', (
      tester,
    ) async {
      await _pumpNavBar(tester);

      // An overflow would surface here (and would also fail the test).
      expect(tester.takeException(), isNull);
      final size = tester.getSize(find.byType(BottomNavBar));
      expect(size.height, _barContentHeight + _hairline);
      expect(size.width, 390);
    });

    testWidgets('center circle is 50px and floats above the bar', (
      tester,
    ) async {
      await _pumpNavBar(tester);

      final circle = _centerCircle.first;
      expect(tester.getSize(circle), const Size(50, 50));

      // Measured from the top of the 64px content area (below the hairline).
      final contentTop =
          tester.getTopLeft(find.byType(BottomNavBar)).dy + _hairline;
      final circleTop = tester.getTopLeft(circle).dy;
      expect(
        contentTop - circleTop,
        16,
        reason: 'circle floats 16px above bar',
      );

      // Horizontally centered in the bar.
      expect(tester.getCenter(circle).dx, 195);
    });

    testWidgets('center label shares a baseline with the other labels', (
      tester,
    ) async {
      await _pumpNavBar(tester);

      final homeLabel = tester.getCenter(find.text('Home')).dy;
      expect(tester.getCenter(find.text('Tailor')).dy, homeLabel);
      expect(tester.getCenter(find.text('Profile')).dy, homeLabel);
    });

    testWidgets('every item, including the center circle, is tappable', (
      tester,
    ) async {
      final taps = await _pumpNavBar(tester);

      for (final label in ['Home', 'CVs', 'Tailor', 'Tracker', 'Profile']) {
        await tester.tap(find.text(label));
      }
      // Tap the circle itself (its centre lies inside the bar).
      await tester.tapAt(tester.getCenter(_centerCircle.first));

      expect(taps, [0, 1, 2, 3, 4, 2]);
    });
  });
}
