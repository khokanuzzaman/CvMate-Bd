import 'package:careermatebd/features/account_deletion/data/account_deletion_service.dart';
import 'package:careermatebd/shared/services/billing/fake_billing_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_auth_repository.dart';

/// Records the steps in the order they ran.
class _Steps {
  final List<String> log = [];
  bool serverFails = false;

  AccountDeletionService service(
    FakeAuthRepository auth, {
    FakeBillingService? billing,
  }) {
    return AccountDeletionService(
      auth: auth,
      deleteAccountOnServer: () async {
        log.add('server');
        if (serverFails) {
          throw Exception('offline');
        }
      },
      billing: billing ?? FakeBillingService(),
      wipeLocalData: () async => log.add('local'),
    );
  }
}

Future<FakeAuthRepository> _signedIn() async {
  final auth = FakeAuthRepository();
  addTearDown(auth.dispose);
  await auth.signInWithEmailAndPassword(email: 'a@b.c', password: 'secret12');
  return auth;
}

void main() {
  test('one server call, then sign-out, RevenueCat and this device; no '
      'Firestore or client-side Auth delete, even for an old sign-in',
      () async {
    final auth = await _signedIn();
    auth.recentLoginRequired = true;
    final billing = FakeBillingService();
    final steps = _Steps();

    final result = await steps.service(auth, billing: billing).delete();

    expect(result.outcome, AccountDeletionOutcome.deleted);
    expect(steps.log, ['server', 'local']);
    expect(auth.deleteCount, 0, reason: 'the server deletes the Auth user');
    expect(auth.currentUser, isNull);
    expect(billing.identityCalls, [null], reason: 'Purchases.logOut()');
  });

  test('a guest with no account only wipes this device', () async {
    final auth = FakeAuthRepository();
    addTearDown(auth.dispose);
    final steps = _Steps();

    final result = await steps.service(auth).delete();

    expect(result.outcome, AccountDeletionOutcome.deleted);
    expect(steps.log, ['local']);
  });

  test('a failed server call keeps the user signed in and the device data; '
      'a retry finishes', () async {
    final auth = await _signedIn();
    final steps = _Steps()..serverFails = true;
    final service = steps.service(auth);

    final result = await service.delete();
    expect(result.outcome, AccountDeletionOutcome.failed);
    expect(result.message, AccountDeletionMessages.failed);
    expect(steps.log, ['server']);
    expect(auth.currentUser, isNotNull);

    steps.serverFails = false;
    expect((await service.delete()).outcome, AccountDeletionOutcome.deleted);
    expect(steps.log, ['server', 'server', 'local']);
    expect(auth.currentUser, isNull);
  });
}
