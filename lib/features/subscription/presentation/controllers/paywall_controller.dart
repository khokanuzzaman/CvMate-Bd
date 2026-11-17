import 'dart:async';

import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/features/auth/presentation/controllers/auth_session_provider.dart';
import 'package:careermatebd/shared/services/billing/billing_models.dart';
import 'package:careermatebd/shared/services/billing/billing_service.dart';
import 'package:careermatebd/shared/services/entitlement/ai_entitlement.dart';
import 'package:careermatebd/shared/services/entitlement/ai_entitlement_controller.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Firebase uid purchases are made for; null when signed out (or when
/// Firebase is not set up, as in widget tests).
final purchaserUidProvider = Provider<String?>((ref) {
  if (Firebase.apps.isEmpty) {
    return null;
  }
  return ref.watch(currentAuthUserProvider)?.uid;
});

enum PaywallPhase { idle, purchasing, restoring, activating, done }

class PaywallState {
  const PaywallState({
    required this.offering,
    this.selected,
    this.phase = PaywallPhase.idle,
    this.notice,
    this.noticeIsError = false,
  });

  final AsyncValue<BillingOffering> offering;

  /// Nothing is pre-selected: the user picks a plan (no pre-selected
  /// auto-renew).
  final BillingPlan? selected;
  final PaywallPhase phase;

  /// One line for the user (cancelled, pending, failed, …).
  final String? notice;
  final bool noticeIsError;

  bool get isBusy =>
      phase == PaywallPhase.purchasing ||
      phase == PaywallPhase.restoring ||
      phase == PaywallPhase.activating;

  BillingPackage? get selectedPackage {
    final plan = selected;
    return plan == null ? null : offering.asData?.value.package(plan);
  }

  PaywallState copyWith({
    AsyncValue<BillingOffering>? offering,
    BillingPlan? selected,
    PaywallPhase? phase,
    String? notice,
    bool noticeIsError = false,
    bool keepNotice = false,
  }) {
    return PaywallState(
      offering: offering ?? this.offering,
      selected: selected ?? this.selected,
      phase: phase ?? this.phase,
      notice: keepNotice ? this.notice : notice,
      noticeIsError: keepNotice ? this.noticeIsError : noticeIsError,
    );
  }
}

final paywallControllerProvider =
    NotifierProvider.autoDispose<PaywallController, PaywallState>(
      PaywallController.new,
    );

/// Loads the offering, buys and restores. Never decides the plan: after the
/// store confirms, it waits for the AI server's entitlement to change (the
/// webhook lands a few seconds later) and only then reports [PaywallPhase.done].
class PaywallController extends Notifier<PaywallState> {
  @override
  PaywallState build() {
    unawaited(Future.microtask(load));
    return const PaywallState(offering: AsyncLoading());
  }

  BillingService get _billing => ref.read(billingServiceProvider);
  AiEntitlementController get _entitlement =>
      ref.read(aiEntitlementProvider.notifier);

  Future<void> load() async {
    state = state.copyWith(offering: const AsyncLoading());
    try {
      final offering = await _billing.loadOffering();
      if (!ref.mounted) {
        return;
      }
      state = offering.isEmpty
          ? state.copyWith(
              offering: AsyncError(
                const BillingException(AppStrings.paywallUnavailable),
                StackTrace.current,
              ),
            )
          : state.copyWith(offering: AsyncData(offering));
    } on BillingException catch (error, stack) {
      if (ref.mounted) {
        state = state.copyWith(offering: AsyncError(error, stack));
      }
    }
  }

  void select(BillingPlan plan) {
    if (!state.isBusy) {
      state = state.copyWith(selected: plan);
    }
  }

  Future<void> buy() async {
    final package = state.selectedPackage;
    final uid = _uidOrNotice();
    if (package == null || uid == null || state.isBusy) {
      return;
    }
    final before = await _entitlement.current();
    state = state.copyWith(phase: PaywallPhase.purchasing);
    final outcome = await _billing.purchase(package, uid: uid);
    if (!ref.mounted) {
      return;
    }
    if (outcome.status != PurchaseStatus.completed) {
      _settle(outcome);
      return;
    }
    final now = DateTime.now();
    final previousUnlocks = _unlockTotal(before);
    await _activate(
      package.isSubscription
          ? (value) => value.isProAt(now)
          : (value) => _unlockTotal(value) > previousUnlocks,
      success: package.isSubscription
          ? AppStrings.paywallProActive
          : AppStrings.paywallPurchaseDone,
    );
  }

  Future<void> restore() async {
    final uid = _uidOrNotice();
    if (uid == null || state.isBusy) {
      return;
    }
    state = state.copyWith(phase: PaywallPhase.restoring);
    final outcome = await _billing.restore(uid: uid);
    if (!ref.mounted) {
      return;
    }
    if (outcome.status != PurchaseStatus.completed) {
      _settle(outcome);
      return;
    }
    if (!outcome.hasPro) {
      state = state.copyWith(
        phase: PaywallPhase.idle,
        notice: AppStrings.paywallRestoredNothing,
      );
      return;
    }
    final now = DateTime.now();
    await _activate(
      (value) => value.isProAt(now),
      success: AppStrings.paywallProActive,
    );
  }

  Future<void> _activate(
    bool Function(AiEntitlement value) done, {
    required String success,
  }) async {
    state = state.copyWith(phase: PaywallPhase.activating);
    final active = await _entitlement.refreshUntil(done);
    if (!ref.mounted) {
      return;
    }
    state = active
        ? state.copyWith(phase: PaywallPhase.done, notice: success)
        : state.copyWith(
            phase: PaywallPhase.idle,
            notice: AppStrings.paywallActivationSlow,
          );
  }

  void _settle(PurchaseOutcome outcome) {
    state = switch (outcome.status) {
      PurchaseStatus.cancelled => state.copyWith(
        phase: PaywallPhase.idle,
        notice: AppStrings.paywallCancelled,
      ),
      PurchaseStatus.pending => state.copyWith(
        phase: PaywallPhase.idle,
        notice: AppStrings.paywallPending,
      ),
      _ => state.copyWith(
        phase: PaywallPhase.idle,
        notice: outcome.message ?? AppStrings.paywallUnavailable,
        noticeIsError: true,
      ),
    };
  }

  String? _uidOrNotice() {
    final uid = ref.read(purchaserUidProvider);
    if (uid == null) {
      state = state.copyWith(notice: AppStrings.paywallSignInNeeded);
    }
    return uid;
  }

  static int _unlockTotal(AiEntitlement? value) =>
      value == null ? 0 : value.cvExportUnlocks + value.unlockedCvIds.length;
}
