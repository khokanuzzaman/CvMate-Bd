import 'package:careermatebd/app/constants/app_strings.dart';

/// The user's plan, AI quota and CV export unlocks as the AI server reports
/// them (`GET /v1/me/entitlement`). The server is the only source of truth
/// for Pro; the app only caches the last value for offline display.
class AiEntitlement {
  const AiEntitlement({
    required this.isPro,
    required this.actionsLeft,
    this.proExpiresAt,
    this.resetsAt,
    this.cvExportUnlocks = 0,
    this.unlockedCvIds = const [],
  });

  final bool isPro;
  final int actionsLeft;

  /// When Pro ends; null when not Pro or Pro never expires.
  final DateTime? proExpiresAt;

  /// When the plan allowance refills; null on the free plan.
  final DateTime? resetsAt;

  /// Purchased one-CV unlocks not yet bound to a CV.
  final int cvExportUnlocks;

  /// CVs this user has unlocked (exportable without Pro).
  final List<String> unlockedCvIds;

  /// "AI actions left: N".
  String get actionsLeftLabel => AppStrings.aiActionsLeft(actionsLeft);

  /// Pro, and (for a cached value) not past its expiry.
  bool isProAt(DateTime now) {
    final expires = proExpiresAt;
    return isPro && (expires == null || expires.isAfter(now));
  }

  bool hasUnlocked(String cvId) => unlockedCvIds.contains(cvId);

  AiEntitlement withActionsLeft(int value) => AiEntitlement(
    isPro: isPro,
    actionsLeft: value < 0 ? 0 : value,
    proExpiresAt: proExpiresAt,
    resetsAt: resetsAt,
    cvExportUnlocks: cvExportUnlocks,
    unlockedCvIds: unlockedCvIds,
  );

  AiEntitlement withUnlocks({
    required int available,
    required List<String> unlockedCvIds,
  }) => AiEntitlement(
    isPro: isPro,
    actionsLeft: actionsLeft,
    proExpiresAt: proExpiresAt,
    resetsAt: resetsAt,
    cvExportUnlocks: available < 0 ? 0 : available,
    unlockedCvIds: unlockedCvIds,
  );

  /// Parses the server body `{plan, proExpiresAt, actionsLeft, resetsAt,
  /// cvExportUnlocks, unlockedCvIds}` (times in epoch milliseconds; the
  /// unlock fields may be missing). Null when the body is not an entitlement.
  static AiEntitlement? fromJson(Map<String, dynamic> json) {
    final actionsLeft = json['actionsLeft'];
    if (actionsLeft is! num) {
      return null;
    }
    return AiEntitlement(
      isPro: json['plan'] == 'pro',
      actionsLeft: actionsLeft.toInt() < 0 ? 0 : actionsLeft.toInt(),
      proExpiresAt: _time(json['proExpiresAt']),
      resetsAt: _time(json['resetsAt']),
      cvExportUnlocks: unlockCount(json['cvExportUnlocks']),
      unlockedCvIds: cvIds(json['unlockedCvIds']),
    );
  }

  Map<String, dynamic> toJson() => {
    'plan': isPro ? 'pro' : 'free',
    'actionsLeft': actionsLeft,
    'proExpiresAt': proExpiresAt?.millisecondsSinceEpoch,
    'resetsAt': resetsAt?.millisecondsSinceEpoch,
    'cvExportUnlocks': cvExportUnlocks,
    'unlockedCvIds': unlockedCvIds,
  };

  static int unlockCount(Object? value) =>
      value is num && value > 0 ? value.toInt() : 0;

  static List<String> cvIds(Object? value) =>
      value is List ? List.unmodifiable(value.whereType<String>()) : const [];

  static DateTime? _time(Object? value) => value is num
      ? DateTime.fromMillisecondsSinceEpoch(value.toInt(), isUtc: true)
      : null;
}
