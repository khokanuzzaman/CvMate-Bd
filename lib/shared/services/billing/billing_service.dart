import 'package:careermatebd/core/config/env_config.dart';
import 'package:careermatebd/shared/services/billing/billing_models.dart';
import 'package:careermatebd/shared/services/billing/fake_billing_service.dart';
import 'package:careermatebd/shared/services/billing/revenuecat_billing_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The store, behind one seam: RevenueCat in real builds, a fake in debug
/// builds with `USE_FAKE_BILLING=true` (and in tests). The RevenueCat app
/// user id is always the Firebase uid ([logIn]); purchases need one.
///
/// It never decides what the user is entitled to: after a purchase the app
/// asks the AI server (`GET /v1/me/entitlement`), the only source of truth.
abstract class BillingService {
  /// Whether this build can sell anything at all (a store key, or the fake).
  bool get isAvailable;

  /// Makes [uid] (the Firebase uid) the RevenueCat app user id.
  Future<void> logIn(String uid);

  /// Back to no user (after Firebase sign-out).
  Future<void> logOut();

  /// The paywall's packages. Throws [BillingException].
  Future<BillingOffering> loadOffering();

  /// Buys [package] for [uid]. Never throws.
  Future<PurchaseOutcome> purchase(
    BillingPackage package, {
    required String uid,
  });

  /// Restores the store account's purchases onto [uid]. Never throws.
  Future<PurchaseOutcome> restore({required String uid});
}

final billingServiceProvider = Provider<BillingService>((ref) {
  if (EnvConfig.isFakeBillingActive) {
    return FakeBillingService();
  }
  final apiKey = EnvConfig.revenueCatApiKeyFor(defaultTargetPlatform);
  if (kIsWeb || apiKey.isEmpty) {
    return const UnavailableBillingService();
  }
  return RevenueCatBillingService(apiKey: apiKey);
});

/// A build with no store key (e.g. Android before Play billing is set up):
/// the paywall says purchases are not available.
class UnavailableBillingService implements BillingService {
  const UnavailableBillingService();

  static const String message = "Purchases aren't available on this device.";

  @override
  bool get isAvailable => false;

  @override
  Future<void> logIn(String uid) async {}

  @override
  Future<void> logOut() async {}

  @override
  Future<BillingOffering> loadOffering() async =>
      throw const BillingException(message);

  @override
  Future<PurchaseOutcome> purchase(
    BillingPackage package, {
    required String uid,
  }) async => const PurchaseOutcome.failed(message);

  @override
  Future<PurchaseOutcome> restore({required String uid}) async =>
      const PurchaseOutcome.failed(message);
}
