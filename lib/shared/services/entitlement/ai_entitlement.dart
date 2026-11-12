import 'package:careermatebd/app/constants/app_strings.dart';

/// The user's plan and AI quota as the AI server reports it
/// (`GET /v1/me/entitlement`). The server is the source of truth; the app
/// only caches the last value for offline display.
class AiEntitlement {
  const AiEntitlement({
    required this.isPro,
    required this.actionsLeft,
    this.proExpiresAt,
    this.resetsAt,
  });

  final bool isPro;
  final int actionsLeft;

  /// When Pro ends; null when not Pro or Pro never expires.
  final DateTime? proExpiresAt;

  /// When the plan allowance refills; null on the free plan.
  final DateTime? resetsAt;

  /// "AI actions left: N".
  String get actionsLeftLabel => AppStrings.aiActionsLeft(actionsLeft);

  AiEntitlement withActionsLeft(int value) => AiEntitlement(
    isPro: isPro,
    actionsLeft: value < 0 ? 0 : value,
    proExpiresAt: proExpiresAt,
    resetsAt: resetsAt,
  );

  /// Parses the server body `{plan, proExpiresAt, actionsLeft, resetsAt}`
  /// (times in epoch milliseconds). Null when the body is not an entitlement.
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
    );
  }

  Map<String, dynamic> toJson() => {
    'plan': isPro ? 'pro' : 'free',
    'actionsLeft': actionsLeft,
    'proExpiresAt': proExpiresAt?.millisecondsSinceEpoch,
    'resetsAt': resetsAt?.millisecondsSinceEpoch,
  };

  static DateTime? _time(Object? value) => value is num
      ? DateTime.fromMillisecondsSinceEpoch(value.toInt(), isUtc: true)
      : null;
}
