import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/cv_mate_theme.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/features/subscription/presentation/screens/paywall_screen.dart';
import 'package:careermatebd/features/subscription/presentation/widgets/paywall_plan_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/screenshot_harness.dart';

/// iPhone SE (3rd gen): 375×667 pt with a 20 pt status bar. Real fonts are
/// loaded so text wraps as it does on the device.
Future<void> _pumpOnSe(WidgetTester tester, {double textScale = 1.0}) async {
  tester.view.physicalSize = const Size(375, 667);
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(top: 20);
  tester.view.viewPadding = const FakeViewPadding(top: 20);
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: CvMateTheme.light,
        home: const PaywallScreen(source: 'test'),
      ),
    ),
  );
  await tester.pump();
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 200)),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadTestFonts);

  testWidgets('prices are visible without scrolling on an iPhone SE', (
    tester,
  ) async {
    await _pumpOnSe(tester);

    final cta = tester.getRect(
      find.widgetWithText(PrimaryButton, AppStrings.paywallCta),
    );
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;

    // Monthly and Yearly cards, whole, above the pinned button.
    final plans = find.byType(PaywallPlanCard);
    expect(plans, findsNWidgets(2));
    for (final element in plans.evaluate()) {
      final rect = tester.getRect(find.byWidget(element.widget));
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(
        rect.bottom,
        lessThanOrEqualTo(cta.top),
        reason: 'a plan card is hidden behind the button',
      );
    }

    // The one-time option too.
    final oneTime = tester.getRect(
      find.text(AppStrings.paywallOneTimeSubtitle),
    );
    expect(oneTime.bottom, lessThanOrEqualTo(cta.top));
    expect(cta.bottom, lessThanOrEqualTo(screen.height));
    expect(tester.takeException(), isNull);
  });

  testWidgets('only the button is pinned: the notes scroll with the page', (
    tester,
  ) async {
    await _pumpOnSe(tester);

    for (final text in [
      AppStrings.paywallNotAvailable,
      AppStrings.paywallRestore,
    ]) {
      expect(
        find.ancestor(
          of: find.textContaining(text, findRichText: true),
          matching: find.byType(SingleChildScrollView),
        ),
        findsOneWidget,
        reason: '"$text" should be part of the scrolling content',
      );
    }
    expect(
      find.ancestor(
        of: find.widgetWithText(PrimaryButton, AppStrings.paywallCta),
        matching: find.byType(SingleChildScrollView),
      ),
      findsNothing,
      reason: 'the button stays pinned',
    );
  });

  testWidgets('at 1.5x text the prices are reachable and nothing overflows', (
    tester,
  ) async {
    await _pumpOnSe(tester, textScale: 1.5);

    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text(AppStrings.paywallOneTimeSubtitle),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byType(PaywallPlanCard), findsNWidgets(2));
  });
}
