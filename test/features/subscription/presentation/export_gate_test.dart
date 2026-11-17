import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/features/subscription/presentation/controllers/paywall_controller.dart';
import 'package:careermatebd/features/subscription/presentation/export_gate.dart';
import 'package:careermatebd/features/subscription/presentation/screens/paywall_screen.dart';
import 'package:careermatebd/shared/services/analytics/analytics_service.dart';
import 'package:careermatebd/shared/services/billing/billing_service.dart';
import 'package:careermatebd/shared/services/billing/fake_billing_service.dart';
import 'package:careermatebd/shared/services/entitlement/ai_entitlement.dart';
import 'package:careermatebd/shared/services/entitlement/entitlement_record.dart';
import 'package:careermatebd/shared/services/entitlement/entitlement_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../helpers/builder_harness.dart';
import '../../../helpers/core_flow_harness.dart';
import '../../../helpers/fake_ai_entitlement.dart';

void main() {
  testWidgets('free export used → paywall → one-CV purchase → the export '
      'continues on the unlocked CV', (tester) async {
    var exports = 0;
    final store = FakeEntitlementStore(
      const EntitlementRecord(freeExportsUsed: 1),
    );
    final entitlement = FakeAiEntitlementController(
      freeEntitlement,
      afterRefresh: const [
        AiEntitlement(isPro: false, actionsLeft: 8, cvExportUnlocks: 1),
      ],
      claimable: true,
    );
    final router = GoRouter(
      initialLocation: RouteNames.homePath,
      routes: [
        GoRoute(
          path: RouteNames.homePath,
          builder: (context, state) => Consumer(
            builder: (context, ref, _) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => runGatedExport(
                    ref: ref,
                    context: context,
                    source: 'test',
                    exportType: 'share',
                    cvId: 'cv-1',
                    export: () async => exports++,
                  ),
                  child: const Text('Export'),
                ),
              ),
            ),
          ),
        ),
        GoRoute(
          path: RouteNames.paywallPath,
          builder: (context, state) => const PaywallScreen(source: 'test'),
        ),
      ],
    );
    addTearDown(router.dispose);
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          entitlementStoreProvider.overrideWithValue(store),
          billingServiceProvider.overrideWithValue(FakeBillingService()),
          purchaserUidProvider.overrideWithValue('u1'),
          analyticsServiceProvider.overrideWithValue(RecordingAnalytics()),
          ...fakeEntitlementOverrides(entitlement),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Export'));
    await tester.pumpAndSettle();
    expect(find.byType(PaywallScreen), findsOneWidget);
    expect(exports, 0);

    await tester.tap(find.text(AppStrings.paywallOneTimeTitle));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PrimaryButton));
    await tester.pumpAndSettle();

    expect(find.byType(PaywallScreen), findsNothing);
    expect(entitlement.claims, ['cv-1']);
    expect(exports, 1);
    expect(store.saveCount, 0, reason: 'an unlocked CV does not count');
  });
}
