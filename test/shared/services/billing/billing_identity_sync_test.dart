import 'package:careermatebd/features/auth/data/repositories/firebase_auth_repository_impl.dart';
import 'package:careermatebd/shared/services/billing/billing_identity_sync.dart';
import 'package:careermatebd/shared/services/billing/billing_service.dart';
import 'package:careermatebd/shared/services/billing/fake_billing_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_auth_repository.dart';

void main() {
  test(
    'logIn(uid) follows Firebase sign-in and logOut() follows sign-out',
    () async {
      final auth = FakeAuthRepository();
      addTearDown(auth.dispose);
      final billing = FakeBillingService();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          billingServiceProvider.overrideWithValue(billing),
        ],
      );
      addTearDown(container.dispose);

      container.listen(billingIdentitySyncProvider, (_, _) {});
      await pumpEventQueue();
      expect(billing.identityCalls, isEmpty, reason: 'signed out at start');

      await auth.signInWithEmailAndPassword(email: 'a@b.c', password: 'pw');
      await pumpEventQueue();
      expect(billing.identityCalls, ['signed-in-user']);

      await auth.signOut();
      await pumpEventQueue();
      expect(billing.identityCalls, ['signed-in-user', null]);
    },
  );

  test('an already signed-in user is logged in at start; a store error '
      'does not escape', () async {
    final billing = _ThrowingBilling();
    await syncBillingIdentity(billing, previous: null, next: 'u1');
    expect(billing.calls, ['u1']);

    final fake = FakeBillingService();
    await syncBillingIdentity(fake, previous: 'u1', next: 'u1');
    expect(fake.identityCalls, isEmpty, reason: 'no change, no call');
  });
}

class _ThrowingBilling extends FakeBillingService {
  final List<String> calls = [];

  @override
  Future<void> logIn(String uid) async {
    calls.add(uid);
    throw StateError('store down');
  }
}
