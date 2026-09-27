import 'package:careermatebd/shared/services/entitlement/entitlement_record.dart';
import 'package:careermatebd/shared/services/entitlement/entitlement_service.dart';
import 'package:careermatebd/shared/services/entitlement/entitlement_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('first export is allowed and the second is blocked (fair 1 free)', () async {
    final store = _FakeStore(const EntitlementRecord.initial());
    final service = EntitlementService(store);

    expect(await service.canExport(), isTrue);
    expect(await service.remainingFreeExports, 1);

    await service.recordSuccessfulExport();

    expect(await service.canExport(), isFalse);
    expect(await service.remainingFreeExports, 0);
    expect(store.saveCount, 1, reason: 'exactly one successful export persisted');
  });

  test('Pro bypasses the export gate and never consumes the free counter', () async {
    final store = _FakeStore(
      const EntitlementRecord(isPro: true, freeExportsUsed: 0, aiCreditsLeft: 20),
    );
    final service = EntitlementService(store);

    expect(await service.canExport(), isTrue);
    await service.recordSuccessfulExport();
    await service.recordSuccessfulExport();

    expect(await service.canExport(), isTrue, reason: 'Pro is unlimited');
    expect(await service.remainingFreeExports, 1, reason: 'free counter untouched');
    expect(store.record.freeExportsUsed, 0);
  });

  test('the counter only moves on a successful export, not on canExport()', () async {
    final store = _FakeStore(const EntitlementRecord.initial());
    final service = EntitlementService(store);

    await service.canExport();
    await service.canExport();
    await service.canExport();

    expect(await service.remainingFreeExports, 1, reason: 'checks do not consume');
    expect(store.saveCount, 0, reason: 'canExport() must never write');
  });

  test('setPro unblocks exporting after the free export is used', () async {
    final store = _FakeStore(const EntitlementRecord.initial());
    final service = EntitlementService(store);

    await service.recordSuccessfulExport();
    expect(await service.canExport(), isFalse);

    await service.setPro(isPro: true);
    expect(await service.canExport(), isTrue);
  });

  test('AI credits decrement on use and stop at zero for non-Pro', () async {
    final store = _FakeStore(
      const EntitlementRecord(isPro: false, freeExportsUsed: 0, aiCreditsLeft: 1),
    );
    final service = EntitlementService(store);

    expect(await service.aiCreditsLeft, 1);
    expect(await service.consumeAiCredit(), isTrue);
    expect(await service.aiCreditsLeft, 0);
    expect(await service.consumeAiCredit(), isFalse, reason: 'out of credits');
  });
}

class _FakeStore implements EntitlementStore {
  _FakeStore(this.record);

  EntitlementRecord record;
  int saveCount = 0;

  @override
  Future<EntitlementRecord> load() async => record;

  @override
  Future<void> save(EntitlementRecord value) async {
    record = value;
    saveCount++;
  }
}
