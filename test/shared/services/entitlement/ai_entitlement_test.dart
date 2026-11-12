import 'package:careermatebd/shared/services/entitlement/ai_entitlement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses free, pro and a null resetsAt; the label shows the count', () {
    final free = AiEntitlement.fromJson({
      'plan': 'free',
      'proExpiresAt': null,
      'actionsLeft': 3,
      'resetsAt': null,
    })!;
    expect(free.isPro, isFalse);
    expect(free.resetsAt, isNull);
    expect(free.actionsLeftLabel, 'AI actions left: 3');

    final pro = AiEntitlement.fromJson({
      'plan': 'pro',
      'proExpiresAt': 1798761600000, // 2027-01-01 UTC
      'actionsLeft': 87,
      'resetsAt': 1796083200000, // 2026-12-01 UTC
    })!;
    expect(pro.isPro, isTrue);
    expect(pro.proExpiresAt, DateTime.utc(2027));
    expect(pro.resetsAt, DateTime.utc(2026, 12));
    expect(pro.actionsLeftLabel, 'AI actions left: 87');

    // remainingActions from an AI response; round-trips through the cache.
    final afterCall = AiEntitlement.fromJson(pro.withActionsLeft(86).toJson())!;
    expect(afterCall.actionsLeftLabel, 'AI actions left: 86');
    expect(afterCall.resetsAt, pro.resetsAt);
  });

  test('a body without actionsLeft is not an entitlement', () {
    expect(
      AiEntitlement.fromJson({
        'error': {'code': 'internal'},
      }),
      isNull,
    );
  });

  test('reads CV export unlocks, and tolerates a server without them', () {
    final withUnlocks = AiEntitlement.fromJson({
      'plan': 'free',
      'actionsLeft': 8,
      'cvExportUnlocks': 1,
      'unlockedCvIds': ['cv-a', 7],
    })!;
    expect(withUnlocks.cvExportUnlocks, 1);
    expect(withUnlocks.unlockedCvIds, ['cv-a']);
    expect(withUnlocks.hasUnlocked('cv-a'), isTrue);
    expect(AiEntitlement.fromJson(withUnlocks.toJson())!.unlockedCvIds, [
      'cv-a',
    ]);

    final older = AiEntitlement.fromJson({'plan': 'pro', 'actionsLeft': 3})!;
    expect(older.cvExportUnlocks, 0);
    expect(older.unlockedCvIds, isEmpty);
  });
}
