import 'dart:async';
import 'dart:developer' as developer;

import 'package:careermatebd/features/auth/presentation/controllers/auth_session_provider.dart';
import 'package:careermatebd/shared/services/billing/billing_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Keeps the RevenueCat app user id equal to the Firebase uid: `logIn(uid)`
/// after sign-in (and at start when already signed in), `logOut()` after
/// sign-out. Watched once by the app root.
final billingIdentitySyncProvider = Provider<void>((ref) {
  final billing = ref.watch(billingServiceProvider);
  ref.listen<String?>(
    currentAuthUserProvider.select((user) => user?.uid),
    (previous, next) =>
        unawaited(syncBillingIdentity(billing, previous: previous, next: next)),
    fireImmediately: true,
  );
});

/// One auth change applied to [billing]. Never throws: a store hiccup must
/// not break sign-in (purchases re-check the user anyway).
Future<void> syncBillingIdentity(
  BillingService billing, {
  required String? previous,
  required String? next,
}) async {
  if (next == previous) {
    return;
  }
  try {
    if (next != null) {
      await billing.logIn(next);
    } else if (previous != null) {
      await billing.logOut();
    }
  } catch (error) {
    developer.log(
      'Billing identity sync failed (${error.runtimeType}).',
      name: 'cvmate.billing',
    );
  }
}
