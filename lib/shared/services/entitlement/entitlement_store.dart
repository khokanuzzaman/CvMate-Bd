import 'dart:convert';

import 'package:careermatebd/shared/services/entitlement/entitlement_record.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Persistence seam for entitlement counters. An interface so the service can
/// be unit-tested with an in-memory fake, and so Phase 2 can swap the Hive
/// implementation for a server-backed one without touching callers.
abstract class EntitlementStore {
  Future<EntitlementRecord> load();
  Future<void> save(EntitlementRecord record);
}

final entitlementStoreProvider = Provider<EntitlementStore>((ref) {
  return const HiveEntitlementStore();
});

class HiveEntitlementStore implements EntitlementStore {
  const HiveEntitlementStore();

  static const String _boxName = 'entitlements_box';
  static const String _recordKey = 'entitlement';

  @override
  Future<EntitlementRecord> load() async {
    final box = await _openBox();
    final raw = box.get(_recordKey);
    if (raw == null || raw.trim().isEmpty) {
      return const EntitlementRecord.initial();
    }

    try {
      return EntitlementRecord.fromMap(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const EntitlementRecord.initial();
    }
  }

  @override
  Future<void> save(EntitlementRecord record) async {
    final box = await _openBox();
    await box.put(_recordKey, jsonEncode(record.toMap()));
  }

  Future<Box<String>> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<String>(_boxName);
    }
    return Hive.openBox<String>(_boxName);
  }
}
