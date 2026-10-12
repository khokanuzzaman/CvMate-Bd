import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/widgets/brand_logo_tile.dart';
import 'package:careermatebd/core/widgets/pager_dots.dart';
import 'package:careermatebd/core/widgets/social_auth_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Center(child: SizedBox(width: 320, child: child)),
    ),
  );
}

void main() {
  group('BrandLogoTile', () {
    testWidgets('renders the crosshair glyph at the requested size', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const Center(child: BrandLogoTile(size: 88))));

      expect(find.byIcon(Icons.gps_fixed), findsOneWidget);
      expect(tester.getSize(find.byType(BrandLogoTile)), const Size(88, 88));
    });
  });

  group('PagerDots', () {
    testWidgets('stretches only the active dot into a pill', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Center(
            child: PagerDots(
              count: 3,
              index: 0,
              dotSize: 6,
              activeWidth: 22,
              activeColor: AppColors.primary,
              inactiveColor: AppColors.lineStrong,
            ),
          ),
        ),
      );

      final dots = find.descendant(
        of: find.byType(PagerDots),
        matching: find.byType(Container),
      );
      expect(dots, findsNWidgets(3));
      expect(tester.getSize(dots.at(0)), const Size(22, 6));
      expect(tester.getSize(dots.at(1)), const Size(6, 6));
      expect(tester.getSize(dots.at(2)), const Size(6, 6));
    });

    testWidgets('keeps the active dot round when no activeWidth is given', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const Center(
            child: PagerDots(
              count: 3,
              index: 1,
              activeColor: AppColors.accent,
              inactiveColor: AppColors.lineStrong,
            ),
          ),
        ),
      );

      final dots = find.descendant(
        of: find.byType(PagerDots),
        matching: find.byType(Container),
      );
      for (var i = 0; i < 3; i++) {
        expect(tester.getSize(dots.at(i)), const Size(8, 8));
      }
    });

    test('rejects an out-of-range index', () {
      // Non-const on purpose: the assert must fire at runtime, not compile time.
      final outOfRange = int.parse('3');
      expect(
        () => PagerDots(
          count: 3,
          index: outOfRange,
          activeColor: AppColors.primary,
          inactiveColor: AppColors.lineStrong,
        ),
        throwsAssertionError,
      );
    });
  });

  group('SocialAuthButton', () {
    testWidgets('fires onPressed when enabled and has no tooltip', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(
          SocialAuthButton(
            label: 'Continue with Google',
            onPressed: () => taps++,
            disabledHint: 'Coming soon',
          ),
        ),
      );

      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('G'), findsOneWidget);
      expect(find.byType(Tooltip), findsNothing);

      await tester.tap(find.text('Continue with Google'));
      expect(taps, 1);
    });

    testWidgets('is inert and explains itself when disabled', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SocialAuthButton(
            label: 'Continue with Google',
            onPressed: null,
            disabledHint: 'Coming soon',
          ),
        ),
      );

      expect(find.byTooltip('Coming soon'), findsOneWidget);
      // Tapping a disabled button must be a no-op (no exception).
      await tester.tap(find.text('Continue with Google'));
      await tester.pump();
    });
  });
}
