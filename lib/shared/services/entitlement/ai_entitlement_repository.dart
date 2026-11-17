import 'dart:convert';

import 'package:careermatebd/core/errors/app_exception.dart';
import 'package:careermatebd/shared/services/ai/ai_server_client.dart';
import 'package:careermatebd/shared/services/entitlement/ai_entitlement.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final aiEntitlementCacheProvider = Provider<AiEntitlementCache>((ref) {
  return const HiveAiEntitlementCache();
});

final aiEntitlementRepositoryProvider = Provider<AiEntitlementRepository>((
  ref,
) {
  return AiEntitlementRepository(
    client: ref.watch(aiServerClientProvider),
    cache: ref.watch(aiEntitlementCacheProvider),
  );
});

/// Reads the plan + AI quota from the AI server and keeps the last value per
/// user in Hive, so the counter still shows offline.
class AiEntitlementRepository {
  const AiEntitlementRepository({required this.client, required this.cache});

  static const String entitlementPath = '/v1/me/entitlement';
  static const String exportUnlocksPath = '/v1/me/cv-export-unlocks';

  final AiServerClient client;
  final AiEntitlementCache cache;

  Future<AiEntitlement?> cached(String uid) => cache.read(uid);

  Future<void> saveCached(String uid, AiEntitlement entitlement) =>
      cache.write(uid, entitlement);

  /// The current value from the server (also cached). Throws [AppException].
  Future<AiEntitlement> fetch(String uid) async {
    final entitlement = AiEntitlement.fromJson(
      await client.getJson(entitlementPath),
    );
    if (entitlement == null) {
      throw const AppException(
        AiFailureMessages.generic,
        code: AiFailureCodes.failed,
      );
    }
    await cache.write(uid, entitlement);
    return entitlement;
  }

  /// Binds one purchased export unlock to [cvId] on the server (idempotent
  /// per CV) and returns [current] with the server's unlock counts, or null
  /// when no unlock is left. Throws [AppException] for other failures.
  Future<AiEntitlement?> claimExportUnlock(
    String uid,
    String cvId,
    AiEntitlement current,
  ) async {
    final Map<String, dynamic> body;
    try {
      body = await client.postJson(exportUnlocksPath, {'cvId': cvId});
    } on AppException catch (error) {
      if (error.code == AiFailureCodes.quotaExceeded) {
        return null; // 402 no_export_unlock
      }
      rethrow;
    }
    final updated = current.withUnlocks(
      available: AiEntitlement.unlockCount(body['cvExportUnlocks']),
      unlockedCvIds: AiEntitlement.cvIds(body['unlockedCvIds']),
    );
    if (!updated.hasUnlocked(cvId)) {
      return null;
    }
    await cache.write(uid, updated);
    return updated;
  }
}

abstract class AiEntitlementCache {
  Future<AiEntitlement?> read(String uid);
  Future<void> write(String uid, AiEntitlement entitlement);
}

/// Hive cache of the last entitlement per uid. The box is opened in `main()`
/// ([openBox]); where it is not open (widget tests) the cache is a no-op.
class HiveAiEntitlementCache implements AiEntitlementCache {
  const HiveAiEntitlementCache();

  static const String boxName = 'ai_entitlement_box';

  static Future<void> openBox() => Hive.openBox<String>(boxName);

  @override
  Future<AiEntitlement?> read(String uid) async {
    final raw = _box?.get(uid);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    try {
      return AiEntitlement.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String uid, AiEntitlement entitlement) async {
    await _box?.put(uid, jsonEncode(entitlement.toJson()));
  }

  Box<String>? get _box =>
      Hive.isBoxOpen(boxName) ? Hive.box<String>(boxName) : null;
}
