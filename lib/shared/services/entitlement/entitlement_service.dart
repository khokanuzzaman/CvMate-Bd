import 'package:careermatebd/shared/services/entitlement/entitlement_record.dart';
import 'package:careermatebd/shared/services/entitlement/entitlement_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Number of clean, unwatermarked exports every user gets before the paywall.
/// One free export is a fair, honest trial — no dark patterns.
const int kFreeExportLimit = 1;

/// Starting AI credit balance for a non-Pro user.
/// TODO(billing): move this budget server-side in Phase 2 (see EntitlementRecord).
const int kInitialAiCredits = 20;

final entitlementServiceProvider = Provider<EntitlementService>((ref) {
  return EntitlementService(ref.watch(entitlementStoreProvider));
});

/// The single source of truth for plan status and usage gates. Every gate in
/// the app (exports, and later AI actions) MUST go through this service rather
/// than checking plan state on its own, so the rules live in exactly one place.
class EntitlementService {
  EntitlementService(this._store, {this.freeExportLimit = kFreeExportLimit});

  final EntitlementStore _store;
  final int freeExportLimit;

  EntitlementRecord? _cache;

  Future<EntitlementRecord> _record() async {
    return _cache ??= await _store.load();
  }

  Future<bool> get isPro async => (await _record()).isPro;

  Future<int> get remainingFreeExports async {
    final record = await _record();
    return (freeExportLimit - record.freeExportsUsed).clamp(0, freeExportLimit);
  }

  Future<int> get aiCreditsLeft async => (await _record()).aiCreditsLeft;

  /// Whether the user may export right now: Pro is unlimited; everyone else gets
  /// [freeExportLimit] clean exports first.
  Future<bool> canExport() async {
    final record = await _record();
    return record.isPro || record.freeExportsUsed < freeExportLimit;
  }

  /// Records one export AFTER it succeeded. Call only on a real successful
  /// export — never merely because the user tapped the button. No-op for Pro.
  Future<void> recordSuccessfulExport() async {
    final record = await _record();
    if (record.isPro) {
      return;
    }
    await _update(record.copyWith(freeExportsUsed: record.freeExportsUsed + 1));
  }

  /// Reserves one AI credit if available. Returns false when the non-Pro user is
  /// out of credits. TODO(billing): enforce this server-side in Phase 2.
  Future<bool> consumeAiCredit() async {
    final record = await _record();
    if (record.isPro) {
      return true;
    }
    if (record.aiCreditsLeft <= 0) {
      return false;
    }
    await _update(record.copyWith(aiCreditsLeft: record.aiCreditsLeft - 1));
    return true;
  }

  /// Sets Pro status. In Phase 2 this is driven by verified billing state; for
  /// now it exists so the app has one place that flips the plan.
  Future<void> setPro({required bool isPro}) async {
    final record = await _record();
    await _update(record.copyWith(isPro: isPro));
  }

  Future<void> _update(EntitlementRecord record) async {
    _cache = record;
    await _store.save(record);
  }
}
