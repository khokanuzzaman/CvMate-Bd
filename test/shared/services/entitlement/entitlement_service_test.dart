import 'package:careermatebd/shared/services/entitlement/ai_entitlement.dart';
import 'package:careermatebd/shared/services/entitlement/entitlement_record.dart';
import 'package:careermatebd/shared/services/entitlement/entitlement_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/builder_harness.dart';

void main() {
  test(
    'first export is allowed and the second is blocked (fair 1 free)',
    () async {
      final store = FakeEntitlementStore();
      final service = EntitlementService(store);

      final first = await service.checkExport(cvId: 'cv-a');
      expect(first, ExportAccess.freeExport);
      expect(await service.remainingFreeExports, 1);

      await service.recordSuccessfulExport(first);

      expect(await service.checkExport(cvId: 'cv-a'), ExportAccess.blocked);
      expect(await service.remainingFreeExports, 0);
      expect(
        store.saveCount,
        1,
        reason: 'exactly one successful export persisted',
      );
    },
  );

  test(
    'the counter only moves on a successful export, not on checkExport()',
    () async {
      final store = FakeEntitlementStore();
      final service = EntitlementService(store);

      await service.checkExport(cvId: 'cv-a');
      await service.checkExport(cvId: 'cv-a');

      expect(
        await service.remainingFreeExports,
        1,
        reason: 'checks do not consume',
      );
      expect(
        store.saveCount,
        0,
        reason: 'checkExport() must never write locally',
      );
    },
  );

  test('server Pro bypasses the gate and never uses the free export', () async {
    final store = FakeEntitlementStore();
    final service = EntitlementService(
      store,
      server: _Server(const AiEntitlement(isPro: true, actionsLeft: 100)),
    );

    final access = await service.checkExport(cvId: 'cv-a');
    expect(access, ExportAccess.pro);
    await service.recordSuccessfulExport(access);
    expect(store.saveCount, 0, reason: 'Pro does not use the free export');
  });

  test('an expired cached Pro is not Pro', () async {
    final service = EntitlementService(
      FakeEntitlementStore(const EntitlementRecord(freeExportsUsed: 1)),
      server: _Server(
        AiEntitlement(
          isPro: true,
          actionsLeft: 100,
          proExpiresAt: DateTime.utc(2026, 1, 1),
        ),
      ),
      now: () => DateTime.utc(2026, 11, 12),
    );

    expect(await service.checkExport(cvId: 'cv-a'), ExportAccess.blocked);
  });

  test('an unlocked CV exports; a purchased unlock is claimed only for a new '
      'CV after the free export', () async {
    final server = _Server(
      const AiEntitlement(
        isPro: false,
        actionsLeft: 8,
        cvExportUnlocks: 1,
        unlockedCvIds: ['cv-old'],
      ),
      claimable: true,
    );
    final store = FakeEntitlementStore();
    final service = EntitlementService(store, server: server);

    expect(await service.checkExport(cvId: 'cv-old'), ExportAccess.unlockedCv);
    // The free export comes first; the purchased unlock is kept.
    expect(await service.checkExport(cvId: 'cv-new'), ExportAccess.freeExport);
    expect(server.claims, isEmpty);

    await service.recordSuccessfulExport(ExportAccess.freeExport);
    expect(await service.checkExport(cvId: 'cv-new'), ExportAccess.unlockedCv);
    expect(server.claims, ['cv-new']);
  });

  test('blocked when no unlock is left or the claim fails', () async {
    final server = _Server(
      const AiEntitlement(isPro: false, actionsLeft: 0, cvExportUnlocks: 1),
    );
    final service = EntitlementService(
      FakeEntitlementStore(const EntitlementRecord(freeExportsUsed: 1)),
      server: server,
    );

    expect(await service.checkExport(cvId: 'cv-a'), ExportAccess.blocked);
    expect(server.claims, ['cv-a']);
  });
}

class _Server implements ServerPlan {
  _Server(this.value, {this.claimable = false});

  final AiEntitlement? value;
  final bool claimable;
  final List<String> claims = [];

  @override
  Future<AiEntitlement?> current() async => value;

  @override
  Future<bool> claimExportUnlock(String cvId) async {
    claims.add(cvId);
    return claimable;
  }
}
