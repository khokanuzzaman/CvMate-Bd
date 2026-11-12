import 'dart:developer' as developer;

import 'package:careermatebd/shared/services/billing/billing_models.dart';
import 'package:careermatebd/shared/services/billing/billing_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

abstract final class _Messages {
  static const String failed =
      "The purchase didn't go through. Nothing was charged. Please try again.";
  static const String offline = 'No connection. Please try again.';
  static const String notAllowed =
      'Purchases are turned off on this device (Screen Time or parental '
      'controls).';
  static const String alreadyOwned =
      'You already own this. Tap "Restore purchases".';
  static const String offering =
      "Couldn't load the plans. Please check your connection and try again.";
}

/// RevenueCat (`purchases_flutter`). Configured lazily, with the Firebase uid
/// as app user id when one is known, so a signed-in user never gets an
/// anonymous RevenueCat id. Never logs the API key or purchase details.
class RevenueCatBillingService implements BillingService {
  RevenueCatBillingService({required this.apiKey});

  /// The platform's public SDK key (from EnvConfig).
  final String apiKey;

  Future<void>? _configured;
  final Map<String, Package> _packages = {};

  @override
  bool get isAvailable => true;

  Future<void> _configure({String? appUserId}) {
    return _configured ??= Purchases.configure(
      PurchasesConfiguration(apiKey)..appUserID = appUserId,
    );
  }

  /// Configures with [uid], or switches the RevenueCat user to it.
  Future<void> _useUser(String uid) async {
    if (_configured == null) {
      await _configure(appUserId: uid);
      return;
    }
    await _configured;
    if (await Purchases.appUserID != uid) {
      await Purchases.logIn(uid);
    }
  }

  @override
  Future<void> logIn(String uid) => _useUser(uid);

  @override
  Future<void> logOut() async {
    if (_configured == null) {
      return;
    }
    await _configured;
    if (await Purchases.isAnonymous) {
      return; // logOut() throws for an anonymous user
    }
    await Purchases.logOut();
  }

  @override
  Future<BillingOffering> loadOffering() async {
    try {
      await _configure();
      final offerings = await Purchases.getOfferings();
      final offering =
          offerings.getOffering(BillingConstants.offeringId) ??
          offerings.current;
      if (offering == null) {
        throw const BillingException(_Messages.offering);
      }
      final yearly = offering.annual;
      final trialEligible = yearly == null
          ? false
          : await _trialEligible(yearly.storeProduct);
      final packages = <BillingPackage>[
        if (offering.monthly case final monthly?)
          _map(monthly, BillingPlan.monthly),
        if (yearly != null)
          _map(
            yearly,
            BillingPlan.yearly,
            trial: trialEligible ? _freeTrial(yearly.storeProduct) : null,
          ),
        if (offering.getPackage(BillingConstants.oneCvPackageId)
            case final oneCv?)
          _map(oneCv, BillingPlan.oneCv),
      ];
      return BillingOffering(packages);
    } on PlatformException catch (error) {
      _log('offerings', error);
      throw const BillingException(_Messages.offering);
    }
  }

  @override
  Future<PurchaseOutcome> purchase(
    BillingPackage package, {
    required String uid,
  }) async {
    final native = _packages[package.id];
    if (native == null) {
      return const PurchaseOutcome.failed(_Messages.failed);
    }
    try {
      await _useUser(uid);
      final result = await Purchases.purchase(PurchaseParams.package(native));
      return PurchaseOutcome.completed(hasPro: _hasPro(result.customerInfo));
    } on PlatformException catch (error) {
      return _failure(error);
    }
  }

  @override
  Future<PurchaseOutcome> restore({required String uid}) async {
    try {
      await _useUser(uid);
      final info = await Purchases.restorePurchases();
      return PurchaseOutcome.completed(hasPro: _hasPro(info));
    } on PlatformException catch (error) {
      return _failure(error);
    }
  }

  BillingPackage _map(Package native, BillingPlan plan, {BillingTrial? trial}) {
    _packages[native.identifier] = native;
    return BillingPackage(
      plan: plan,
      id: native.identifier,
      priceLabel: native.storeProduct.priceString,
      price: native.storeProduct.price,
      freeTrial: trial,
    );
  }

  /// iOS: only when StoreKit says this user is eligible (unknown = no, as
  /// RevenueCat advises). Google Play only offers eligible free phases.
  Future<bool> _trialEligible(StoreProduct product) async {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return true;
    }
    try {
      final eligibility =
          await Purchases.checkTrialOrIntroductoryPriceEligibility([
            product.identifier,
          ]);
      return eligibility[product.identifier]?.status ==
          IntroEligibilityStatus.introEligibilityStatusEligible;
    } on PlatformException catch (error) {
      _log('trial eligibility', error);
      return false;
    }
  }

  BillingTrial? _freeTrial(StoreProduct product) {
    final intro = product.introductoryPrice;
    if (intro != null && intro.price == 0) {
      return _trial(intro.periodUnit, intro.periodNumberOfUnits);
    }
    final period = product.defaultOption?.freePhase?.billingPeriod;
    return period == null ? null : _trial(period.unit, period.value);
  }

  BillingTrial? _trial(PeriodUnit unit, int count) {
    final mapped = switch (unit) {
      PeriodUnit.day => BillingPeriodUnit.day,
      PeriodUnit.week => BillingPeriodUnit.week,
      PeriodUnit.month => BillingPeriodUnit.month,
      PeriodUnit.year => BillingPeriodUnit.year,
      PeriodUnit.unknown => null,
    };
    return mapped == null || count <= 0
        ? null
        : BillingTrial(unit: mapped, count: count);
  }

  bool _hasPro(CustomerInfo info) =>
      info.entitlements.active.containsKey(BillingConstants.proEntitlementId);

  PurchaseOutcome _failure(PlatformException error) {
    final code = PurchasesErrorHelper.getErrorCode(error);
    switch (code) {
      case PurchasesErrorCode.purchaseCancelledError:
        return const PurchaseOutcome.cancelled();
      case PurchasesErrorCode.paymentPendingError:
        return const PurchaseOutcome.pending();
      case PurchasesErrorCode.networkError:
      case PurchasesErrorCode.offlineConnectionError:
        return const PurchaseOutcome.failed(_Messages.offline);
      case PurchasesErrorCode.purchaseNotAllowedError:
        return const PurchaseOutcome.failed(_Messages.notAllowed);
      case PurchasesErrorCode.productAlreadyPurchasedError:
        return const PurchaseOutcome.failed(_Messages.alreadyOwned);
      default:
        _log('purchase', error);
        return const PurchaseOutcome.failed(_Messages.failed);
    }
  }

  /// The error code only: never the message (it can contain user details).
  void _log(String what, PlatformException error) {
    developer.log(
      'RevenueCat $what failed (code ${error.code}).',
      name: 'cvmate.billing',
    );
  }
}
