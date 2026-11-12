import 'dart:async';

import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/features/subscription/presentation/controllers/paywall_controller.dart';
import 'package:careermatebd/shared/services/billing/billing_models.dart';
import 'package:careermatebd/shared/services/billing/billing_service.dart';
import 'package:careermatebd/shared/services/billing/fake_billing_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/core_flow_harness.dart';
import '../../../../helpers/fake_ai_entitlement.dart';
import '../../../../helpers/fake_cv_repository.dart';

Future<CoreFlowApp> _open(
  WidgetTester tester, {
  bool asRoot = false,
  FakeBillingService? billing,
  FakeAiEntitlementController? entitlement,
  String? uid = 'u1',
}) async {
  final app = await pumpCoreFlow(
    tester,
    repository: FakeCvRepository(),
    surface: const Size(390, 1400),
    overrides: [
      billingServiceProvider.overrideWithValue(billing ?? FakeBillingService()),
      purchaserUidProvider.overrideWithValue(uid),
      ...fakeEntitlementOverrides(
        entitlement ?? FakeAiEntitlementController(freeEntitlement),
      ),
    ],
  );
  if (asRoot) {
    app.router.go('${RouteNames.paywallPath}?source=cv_preview');
  } else {
    unawaited(app.router.push('${RouteNames.paywallPath}?source=cv_preview'));
  }
  await tester.pumpAndSettle();
  return app;
}

Finder _text(String text) => find.textContaining(text, findRichText: true);

PrimaryButton _cta(WidgetTester tester) =>
    tester.widget<PrimaryButton>(find.byType(PrimaryButton));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the benefits and the store packages, nothing selected', (
    tester,
  ) async {
    await _open(tester);

    expect(find.text(AppStrings.paywallTitle), findsOneWidget);
    for (final benefit in [
      AppStrings.paywallBenefitTailoring,
      AppStrings.paywallBenefitTemplates,
      AppStrings.paywallBenefitCloud,
    ]) {
      expect(find.text(benefit), findsOneWidget);
    }
    // Prices come from the store offering, never from code.
    for (final package in FakeBillingService.sampleOffering.packages) {
      expect(_text(package.priceLabel), findsOneWidget);
    }
    expect(find.text(AppStrings.paywallOneTimeTitle), findsOneWidget);
    // The yearly trial is shown on the yearly card.
    expect(find.text('7-DAY FREE TRIAL'), findsOneWidget);
    // No pre-selected plan: the button waits for a choice.
    expect(_cta(tester).label, AppStrings.paywallChoosePlan);
    expect(_cta(tester).onPressed, isNull);
    // Terms, Privacy and Restore are always there.
    for (final link in [
      AppStrings.paywallTerms,
      AppStrings.paywallPrivacy,
      AppStrings.paywallRestore,
    ]) {
      expect(find.text(link), findsOneWidget);
    }
  });

  testWidgets('choosing yearly shows the trial button and the auto-renew '
      'terms with the store price', (tester) async {
    await _open(tester);

    await _tap(tester, find.text(AppStrings.paywallYearly));

    expect(_cta(tester).label, AppStrings.paywallCtaTrial);
    expect(_cta(tester).onPressed, isNotNull);
    expect(
      _text('7-day free trial, then US\$29.99 (test) per year'),
      findsOneWidget,
    );
    expect(_text('renews automatically'), findsOneWidget);
    expect(_text('24 hours before'), findsOneWidget);

    await _tap(tester, find.text(AppStrings.paywallOneTimeTitle));
    expect(_cta(tester).label, AppStrings.paywallCtaBuy('US\$2.99 (test)'));
    expect(_text('No subscription, nothing renews'), findsOneWidget);
  });

  testWidgets('a store error shows a retry; retry loads the plans', (
    tester,
  ) async {
    final billing = FakeBillingService(
      offeringError: const BillingException('Store is down.'),
    );
    await _open(tester, billing: billing);

    expect(find.text(AppStrings.paywallLoadFailed), findsOneWidget);
    expect(find.text('Store is down.'), findsOneWidget);
    expect(_cta(tester).onPressed, isNull);

    billing.offeringError = null;
    await _tap(tester, find.text('Try again'));
    expect(find.text(AppStrings.paywallMonthly), findsOneWidget);
  });

  testWidgets('signed out: the button asks to sign in, nothing is bought', (
    tester,
  ) async {
    final billing = FakeBillingService();
    await _open(tester, billing: billing, uid: null);

    await _tap(tester, find.text(AppStrings.paywallMonthly));

    expect(_cta(tester).label, AppStrings.paywallCtaSignIn);
    expect(billing.purchases, isEmpty);
  });

  testWidgets('a cancelled purchase says so and stays on the paywall', (
    tester,
  ) async {
    final billing = FakeBillingService(
      purchaseOutcome: const PurchaseOutcome.cancelled(),
    );
    await _open(tester, billing: billing);

    await _tap(tester, find.text(AppStrings.paywallMonthly));
    await _tap(tester, find.byType(PrimaryButton));

    expect(billing.purchases.single.$2, 'u1');
    expect(find.text(AppStrings.paywallCancelled), findsOneWidget);
    expect(find.text(AppStrings.paywallTitle), findsOneWidget);
  });

  testWidgets('after a purchase it waits for the server to report Pro, then '
      'closes', (tester) async {
    final entitlement = FakeAiEntitlementController(
      freeEntitlement,
      // The webhook lands on the second refresh.
      afterRefresh: const [freeEntitlement, proEntitlement],
    );
    await _open(tester, entitlement: entitlement);

    await _tap(tester, find.text(AppStrings.paywallYearly));
    await _tap(tester, find.byType(PrimaryButton));

    expect(entitlement.refreshCount, 2);
    expect(find.text(AppStrings.paywallTitle), findsNothing);
    expect(find.text(homePlaceholder), findsOneWidget);
    expect(find.text(AppStrings.paywallProActive), findsOneWidget);
  });

  testWidgets('when the server has not caught up, it says activation takes '
      'a minute and stays', (tester) async {
    await _open(tester);

    await _tap(tester, find.text(AppStrings.paywallMonthly));
    await _tap(tester, find.byType(PrimaryButton));

    expect(find.text(AppStrings.paywallActivationSlow), findsOneWidget);
    expect(find.text(AppStrings.paywallTitle), findsOneWidget);
  });

  testWidgets('Restore with no active subscription says so', (tester) async {
    final billing = FakeBillingService(
      restoreOutcome: const PurchaseOutcome.completed(hasPro: false),
    );
    await _open(tester, billing: billing);

    await _tap(tester, find.text(AppStrings.paywallRestore));

    expect(billing.restoreCount, 1);
    expect(find.text(AppStrings.paywallRestoredNothing), findsOneWidget);
  });

  testWidgets('no countdowns or fake urgency', (tester) async {
    await _open(tester);
    await _tap(tester, find.text(AppStrings.paywallYearly));

    expect(find.textContaining(RegExp(r'\d+:\d{2}')), findsNothing);
    for (final phrase in [
      'limited time',
      'hurry',
      'only today',
      'expires',
      'last chance',
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
