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
