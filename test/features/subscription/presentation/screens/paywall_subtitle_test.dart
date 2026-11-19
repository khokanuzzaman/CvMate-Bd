import 'dart:async';

import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/features/subscription/presentation/controllers/paywall_controller.dart';
import 'package:careermatebd/shared/services/billing/billing_service.dart';
import 'package:careermatebd/shared/services/billing/fake_billing_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/core_flow_harness.dart';
import '../../../../helpers/fake_ai_entitlement.dart';
import '../../../../helpers/fake_cv_repository.dart';

void main() {
  // The export gate passes the export's own source (cv_preview, tailoring).
  const exportGate = ['cv_preview', 'tailoring'];
  const elsewhere = ['profile', 'restore', 'ai_quota', 'other', null];

  for (final source in [...exportGate, ...elsewhere]) {
    testWidgets('paywall subtitle, source=$source', (tester) async {
      final app = await pumpCoreFlow(
        tester,
        repository: FakeCvRepository(),
        surface: const Size(390, 1400),
        overrides: [
          billingServiceProvider.overrideWithValue(FakeBillingService()),
          purchaserUidProvider.overrideWithValue('u1'),
          ...fakeEntitlementOverrides(
            FakeAiEntitlementController(freeEntitlement),
          ),
        ],
      );
      unawaited(
        app.router.push(
          source == null
              ? RouteNames.paywallPath
              : '${RouteNames.paywallPath}?source=$source',
        ),
      );
      await tester.pumpAndSettle();

      final usedFreeExport = find.textContaining(
        AppStrings.paywallBodyEmphasis,
        findRichText: true,
      );
      if (exportGate.contains(source)) {
        expect(usedFreeExport, findsOneWidget);
        expect(find.text(AppStrings.paywallBodyNeutral), findsNothing);
      } else {
        expect(usedFreeExport, findsNothing);
        expect(find.text(AppStrings.paywallBodyNeutral), findsOneWidget);
      }
    });
  }
}
