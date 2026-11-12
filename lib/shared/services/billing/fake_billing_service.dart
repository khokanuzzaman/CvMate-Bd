import 'package:careermatebd/shared/services/billing/billing_models.dart';
import 'package:careermatebd/shared/services/billing/billing_service.dart';

/// Debug and test stand-in for the store (like the mock AI): canned packages,
/// nothing charged. A "purchase" here never reaches the server, so it never
/// makes anyone Pro; tests script the server side separately.
class FakeBillingService implements BillingService {
  FakeBillingService({
    BillingOffering? offering,
    this.purchaseOutcome = const PurchaseOutcome.completed(),
    this.restoreOutcome = const PurchaseOutcome.completed(),
    this.offeringError,
  }) : offering = offering ?? sampleOffering;

  /// Labelled as test prices so they can never be mistaken for real ones.
  static const BillingOffering sampleOffering = BillingOffering([
    BillingPackage(
      plan: BillingPlan.monthly,
      id: r'$rc_monthly',
      priceLabel: 'US\$4.99 (test)',
      price: 4.99,
    ),
    BillingPackage(
      plan: BillingPlan.yearly,
      id: r'$rc_annual',
      priceLabel: 'US\$29.99 (test)',
      price: 29.99,
      freeTrial: BillingTrial(unit: BillingPeriodUnit.day, count: 7),
    ),
    BillingPackage(
      plan: BillingPlan.oneCv,
      id: BillingConstants.oneCvPackageId,
      priceLabel: 'US\$2.99 (test)',
      price: 2.99,
    ),
  ]);

  BillingOffering offering;
  PurchaseOutcome purchaseOutcome;
  PurchaseOutcome restoreOutcome;

  /// When set, [loadOffering] throws it.
  BillingException? offeringError;

  /// Every logIn uid / logOut (as null), in order.
  final List<String?> identityCalls = [];
  final List<(BillingPackage, String)> purchases = [];
  int restoreCount = 0;

  @override
  bool get isAvailable => true;

  @override
  Future<void> logIn(String uid) async => identityCalls.add(uid);

  @override
  Future<void> logOut() async => identityCalls.add(null);

  @override
  Future<BillingOffering> loadOffering() async {
    final error = offeringError;
    if (error != null) {
      throw error;
    }
    return offering;
  }

  @override
  Future<PurchaseOutcome> purchase(
    BillingPackage package, {
    required String uid,
  }) async {
    purchases.add((package, uid));
    return purchaseOutcome;
  }

  @override
  Future<PurchaseOutcome> restore({required String uid}) async {
    restoreCount++;
    return restoreOutcome;
  }
}
