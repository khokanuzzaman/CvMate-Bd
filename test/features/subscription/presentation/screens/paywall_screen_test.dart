import 'dart:async';

import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/constants/pricing_constants.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/core_flow_harness.dart';
import '../../../../helpers/fake_cv_repository.dart';

Future<CoreFlowApp> _open(WidgetTester tester, {bool asRoot = false}) async {
  final app = await pumpCoreFlow(tester, repository: FakeCvRepository());
  if (asRoot) {
    app.router.go('${RouteNames.paywallPath}?source=cv_preview');
  } else {
    unawaited(app.router.push('${RouteNames.paywallPath}?source=cv_preview'));
  }
  await tester.pumpAndSettle();
  return app;
}

Finder _text(String text) => find.textContaining(text, findRichText: true);

void main() {
  testWidgets('shows the message, benefits and the three options', (
    tester,
  ) async {
    await _open(tester);

    expect(find.text(AppStrings.paywallTitle), findsOneWidget);
    expect(_text(AppStrings.paywallBodyEmphasis), findsOneWidget);
    for (final benefit in [
      AppStrings.paywallBenefitTailoring,
      AppStrings.paywallBenefitTemplates,
      AppStrings.paywallBenefitCloud,
    ]) {
      expect(find.text(benefit), findsOneWidget);
    }
    expect(find.text(AppStrings.paywallMonthly), findsOneWidget);
    expect(find.text(AppStrings.paywallYearly), findsOneWidget);
    expect(find.text(AppStrings.paywallOneTimeTitle), findsOneWidget);
    expect(find.text(AppStrings.paywallOneTimeSubtitle), findsOneWidget);
  });

  testWidgets('prices and the saving come from the constants file', (
    tester,
  ) async {
    await _open(tester);

    expect(
      _text(PricingConstants.format(PricingConstants.monthlyPrice)),
      findsOneWidget,
    );
    expect(
      _text(PricingConstants.format(PricingConstants.yearlyPrice)),
      findsOneWidget,
    );
    expect(
      find.text(PricingConstants.format(PricingConstants.singleCvPrice)),
      findsOneWidget,
    );
    expect(
      find.text(AppStrings.paywallSave(PricingConstants.yearlySavingsPercent)),
      findsOneWidget,
    );
  });

  testWidgets('billing is not wired: the CTA and Restore are disabled', (
    tester,
  ) async {
    await _open(tester);

    final cta = tester.widget<PrimaryButton>(
      find.widgetWithText(PrimaryButton, AppStrings.paywallCta),
    );
    expect(cta.onPressed, isNull);
    expect(find.text(AppStrings.paywallNotAvailable), findsOneWidget);

    final restore = find.text(AppStrings.paywallRestore);
    expect(restore, findsOneWidget);
    for (final tappable in [InkWell, GestureDetector, TextButton]) {
      expect(
        find.ancestor(of: restore, matching: find.byType(tappable)),
        findsNothing,
        reason: 'Restore purchase must not be tappable',
      );
    }
    expect(_text(AppStrings.paywallFooter), findsOneWidget);
  });

  testWidgets('no countdowns or fake urgency', (tester) async {
    await _open(tester);

    expect(find.textContaining(RegExp(r'\d+:\d{2}')), findsNothing);
    for (final phrase in [
      'limited time',
      'hurry',
      'only today',
      'expires',
      'last chance',
      'left',
    ]) {
      expect(
        find.textContaining(phrase, findRichText: true, skipOffstage: false),
        findsNothing,
        reason: phrase,
      );
    }
  });

  testWidgets('logs paywall_viewed with where it came from', (tester) async {
    final app = await _open(tester);

    expect(app.analytics.paramsFor('paywall_viewed').single, {
      'source': 'cv_preview',
    });
  });

  testWidgets('Close goes back to where the user came from', (tester) async {
    await _open(tester);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.text(homePlaceholder), findsOneWidget);
    expect(find.text(AppStrings.paywallTitle), findsNothing);
  });

  testWidgets('Close goes home when there is nothing to go back to', (
    tester,
  ) async {
    await _open(tester, asRoot: true);
    expect(find.text(AppStrings.paywallTitle), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.text(homePlaceholder), findsOneWidget);
  });
}
