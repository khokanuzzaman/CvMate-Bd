import 'package:careermatebd/shared/services/entitlement/ai_entitlement.dart';
import 'package:careermatebd/shared/services/entitlement/ai_entitlement_controller.dart';
import 'package:careermatebd/shared/services/entitlement/entitlement_record.dart';
import 'package:careermatebd/shared/services/entitlement/entitlement_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Number of clean, unwatermarked exports every user gets before the paywall.
/// One free export is a fair, honest trial — no dark patterns.
const int kFreeExportLimit = 1;

/// Why an export may go ahead, or [blocked] (open the paywall).
enum ExportAccess { pro, unlockedCv, freeExport, blocked }

/// The server's view of the user, as the export gate needs it.
abstract class ServerPlan {
  /// The last known entitlement; null when unknown (signed out, offline with
  /// no cache).
  Future<AiEntitlement?> current();

  /// Binds one purchased unlock to [cvId]; true when the CV is unlocked.
  Future<bool> claimExportUnlock(String cvId);
}

final entitlementServiceProvider = Provider<EntitlementService>((ref) {
  return EntitlementService(
    ref.watch(entitlementStoreProvider),
    server: _ControllerServerPlan(ref),
  );
});

class _ControllerServerPlan implements ServerPlan {
  const _ControllerServerPlan(this._ref);

  final Ref _ref;

  @override
  Future<AiEntitlement?> current() =>
      _ref.read(aiEntitlementProvider.notifier).current();

  @override
  Future<bool> claimExportUnlock(String cvId) =>
      _ref.read(aiEntitlementProvider.notifier).claimExportUnlock(cvId);
}

/// The single export gate. Every export MUST go through [checkExport] rather
/// than checking plan state on its own. Pro and CV unlocks come only from the
/// AI server; the device keeps just the one-free-export counter.
class EntitlementService {
  EntitlementService(
    this._store, {
    ServerPlan? server,
    this.freeExportLimit = kFreeExportLimit,
    DateTime Function()? now,
  }) : _server = server,
       _now = now ?? DateTime.now;

  final EntitlementStore _store;
  final ServerPlan? _server;
  final int freeExportLimit;
  final DateTime Function() _now;

  EntitlementRecord? _cache;

  Future<EntitlementRecord> _record() async {
    return _cache ??= await _store.load();
  }

  Future<int> get remainingFreeExports async {
    final record = await _record();
    return (freeExportLimit - record.freeExportsUsed).clamp(0, freeExportLimit);
  }

  /// Whether [cvId] may be exported now, in this order: Pro; a CV already
  /// unlocked; the one free export; else a purchased unlock is claimed for
  /// this CV (the only step that writes, and only on the server).
  Future<ExportAccess> checkExport({String? cvId}) async {
    final server = await _serverPlan();
    if (server != null && server.isProAt(_now())) {
      return ExportAccess.pro;
    }
    if (cvId != null && server != null && server.hasUnlocked(cvId)) {
      return ExportAccess.unlockedCv;
    }
    final record = await _record();
    if (record.freeExportsUsed < freeExportLimit) {
      return ExportAccess.freeExport;
    }
    if (cvId != null &&
        server != null &&
        server.cvExportUnlocks > 0 &&
        await _server!.claimExportUnlock(cvId)) {
      return ExportAccess.unlockedCv;
    }
    return ExportAccess.blocked;
  }

  /// Records one export AFTER it succeeded. Only the free export counts;
  /// Pro and unlocked CVs never use it up.
  Future<void> recordSuccessfulExport(ExportAccess access) async {
    if (access != ExportAccess.freeExport) {
      return;
    }
    final record = await _record();
    _cache = record.copyWith(freeExportsUsed: record.freeExportsUsed + 1);
    await _store.save(_cache!);
  }

  Future<AiEntitlement?> _serverPlan() async {
    try {
      return await _server?.current();
    } catch (_) {
      return null;
    }
  }
}
