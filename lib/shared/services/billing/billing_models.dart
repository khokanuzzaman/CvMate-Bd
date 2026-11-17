/// RevenueCat setup this app expects (RevenueCat dashboard + App Store
/// Connect). Prices are set in the stores, never in code.
abstract final class BillingConstants {
  /// The entitlement that means Pro.
  static const String proEntitlementId = 'pro';

  /// The offering the paywall shows (falls back to the current offering).
  static const String offeringId = 'default';

  /// Custom package for the one-CV unlock (product `cvmate_one_cv`).
  static const String oneCvPackageId = 'one_cv';
}

/// What the paywall sells.
enum BillingPlan { monthly, yearly, oneCv }

enum BillingPeriodUnit { day, week, month, year }

/// A free trial the store offers this user on a subscription.
class BillingTrial {
  const BillingTrial({required this.unit, required this.count});

  final BillingPeriodUnit unit;
  final int count;
}

/// One package of the offering, with the store's localized price.
class BillingPackage {
  const BillingPackage({
    required this.plan,
    required this.id,
    required this.priceLabel,
    this.price,
    this.freeTrial,
  });

  final BillingPlan plan;

  /// RevenueCat package identifier (e.g. `$rc_annual`).
  final String id;

  /// Formatted by the store in the user's currency (e.g. "৳799.00").
  final String priceLabel;

  /// The same price as a number, for comparing plans; null when unknown.
  final double? price;

  /// Only when this user is eligible for it.
  final BillingTrial? freeTrial;

  bool get isSubscription => plan != BillingPlan.oneCv;
}

/// The packages the paywall can show; any of them may be missing.
class BillingOffering {
  const BillingOffering(this.packages);

  final List<BillingPackage> packages;

  BillingPackage? package(BillingPlan plan) {
    for (final package in packages) {
      if (package.plan == plan) {
        return package;
      }
    }
    return null;
  }

  bool get isEmpty => packages.isEmpty;

  /// Whole percent the yearly plan saves over twelve monthly payments, or
  /// null when either price is unknown or the saving is negligible.
  int? get yearlySavingsPercent {
    final monthly = package(BillingPlan.monthly)?.price;
    final yearly = package(BillingPlan.yearly)?.price;
    if (monthly == null || yearly == null || monthly <= 0) {
      return null;
    }
    final percent = ((1 - yearly / (monthly * 12)) * 100).round();
    return percent >= 5 ? percent : null;
  }
}

enum PurchaseStatus { completed, cancelled, pending, failed }

/// How a purchase or restore ended on the device. The server decides what
/// the user is entitled to; this only says whether the store took payment.
class PurchaseOutcome {
  const PurchaseOutcome(this.status, {this.message, this.hasPro = false});

  const PurchaseOutcome.completed({bool hasPro = false})
    : this(PurchaseStatus.completed, hasPro: hasPro);
  const PurchaseOutcome.cancelled() : this(PurchaseStatus.cancelled);
  const PurchaseOutcome.pending() : this(PurchaseStatus.pending);
  const PurchaseOutcome.failed(String message)
    : this(PurchaseStatus.failed, message: message);

  final PurchaseStatus status;

  /// Safe to show; set for [PurchaseStatus.failed].
  final String? message;

  /// Whether the store reports the Pro entitlement active afterwards (used
  /// only to decide whether waiting for the server is worthwhile).
  final bool hasPro;
}

/// A billing failure with a message that is safe to show.
class BillingException implements Exception {
  const BillingException(this.message);

  final String message;

  @override
  String toString() => 'BillingException: $message';
}
