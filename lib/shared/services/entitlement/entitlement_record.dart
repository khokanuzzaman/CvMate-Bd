/// Immutable snapshot of the device's free-export counter.
///
/// Neither the plan nor the AI quota is here: the AI server is the only
/// source of truth for both (see AiEntitlement). TODO(billing): the counter
/// lives in Hive for the one free export; clearing app data resets it, so it
/// is best-effort.
class EntitlementRecord {
  const EntitlementRecord({required this.freeExportsUsed});

  const EntitlementRecord.initial() : freeExportsUsed = 0;

  final int freeExportsUsed;

  EntitlementRecord copyWith({int? freeExportsUsed}) {
    return EntitlementRecord(
      freeExportsUsed: freeExportsUsed ?? this.freeExportsUsed,
    );
  }

  Map<String, dynamic> toMap() => {'freeExportsUsed': freeExportsUsed};

  /// Older records also stored a local `isPro` flag; it is ignored.
  factory EntitlementRecord.fromMap(Map<String, dynamic> map) {
    return EntitlementRecord(
      freeExportsUsed: (map['freeExportsUsed'] as num?)?.toInt() ?? 0,
    );
  }
}
