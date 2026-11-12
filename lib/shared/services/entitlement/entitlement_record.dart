/// Immutable snapshot of a user's plan + export counter.
///
/// The AI quota is NOT here: the AI server is its source of truth
/// (see AiEntitlement). TODO(billing): `freeExportsUsed` lives in Hive for a
/// client-only MVP; a device-local counter can be reset by clearing app data,
/// so treat it as best-effort until real billing moves it server-side.
class EntitlementRecord {
  const EntitlementRecord({required this.isPro, required this.freeExportsUsed});

  const EntitlementRecord.initial() : isPro = false, freeExportsUsed = 0;

  final bool isPro;
  final int freeExportsUsed;

  EntitlementRecord copyWith({bool? isPro, int? freeExportsUsed}) {
    return EntitlementRecord(
      isPro: isPro ?? this.isPro,
      freeExportsUsed: freeExportsUsed ?? this.freeExportsUsed,
    );
  }

  Map<String, dynamic> toMap() => {
    'isPro': isPro,
    'freeExportsUsed': freeExportsUsed,
  };

  factory EntitlementRecord.fromMap(Map<String, dynamic> map) {
    return EntitlementRecord(
      isPro: map['isPro'] as bool? ?? false,
      freeExportsUsed: (map['freeExportsUsed'] as num?)?.toInt() ?? 0,
    );
  }
}
