/// Immutable snapshot of a user's plan + usage counters.
///
/// TODO(billing): `aiCreditsLeft` (and ultimately `freeExportsUsed`) are
/// money-cost counters. They live in Hive today for a client-only MVP, but a
/// device-local counter can be reset by clearing app data, so these MUST move
/// server-side (entitlements API / Firestore with security rules) in Phase 2
/// when real billing is integrated. Treat the local values as best-effort.
class EntitlementRecord {
  const EntitlementRecord({
    required this.isPro,
    required this.freeExportsUsed,
    required this.aiCreditsLeft,
  });

  const EntitlementRecord.initial({int initialAiCredits = 20})
    : isPro = false,
      freeExportsUsed = 0,
      aiCreditsLeft = initialAiCredits;

  final bool isPro;
  final int freeExportsUsed;
  final int aiCreditsLeft;

  EntitlementRecord copyWith({
    bool? isPro,
    int? freeExportsUsed,
    int? aiCreditsLeft,
  }) {
    return EntitlementRecord(
      isPro: isPro ?? this.isPro,
      freeExportsUsed: freeExportsUsed ?? this.freeExportsUsed,
      aiCreditsLeft: aiCreditsLeft ?? this.aiCreditsLeft,
    );
  }

  Map<String, dynamic> toMap() => {
    'isPro': isPro,
    'freeExportsUsed': freeExportsUsed,
    'aiCreditsLeft': aiCreditsLeft,
  };

  factory EntitlementRecord.fromMap(Map<String, dynamic> map) {
    return EntitlementRecord(
      isPro: map['isPro'] as bool? ?? false,
      freeExportsUsed: (map['freeExportsUsed'] as num?)?.toInt() ?? 0,
      aiCreditsLeft: (map['aiCreditsLeft'] as num?)?.toInt() ?? 20,
    );
  }
}
