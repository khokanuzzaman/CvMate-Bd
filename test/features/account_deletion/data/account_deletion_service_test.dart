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
    final store = billing ?? FakeBillingService();
    return AccountDeletionService(
      auth: auth,
      deleteServerData: () async {
        log.add('server');
        if (serverFails) {
          throw Exception('offline');
        }
      },
      deleteCloudData: (uid) async => log.add('firestore:$uid'),
      billing: store,
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
  test('deletes in order: server, Firestore, Auth user, RevenueCat, device',
      () async {
    final auth = await _signedIn();
    final billing = FakeBillingService();
    final steps = _Steps();

    final result = await steps.service(auth, billing: billing).delete();

    expect(result.outcome, AccountDeletionOutcome.deleted);
    expect(steps.log, ['server', 'firestore:signed-in-user', 'local']);
    expect(auth.deleteCount, 1);
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
    expect(auth.deleteCount, 0);
  });

  test('an old sign-in asks for the password before deleting anything; '
      'the right password then deletes', () async {
    final auth = await _signedIn();
    auth.recentLoginRequired = true;
    final steps = _Steps();
    final service = steps.service(auth);

    expect((await service.delete()).outcome,
        AccountDeletionOutcome.needsPassword);
    expect(steps.log, isEmpty);

    final wrong = await service.delete(password: 'nope');
    expect(wrong.outcome, AccountDeletionOutcome.failed);
    expect(wrong.message, contains('Incorrect password'));
    expect(steps.log, isEmpty);

    expect((await service.delete(password: 'secret12')).outcome,
        AccountDeletionOutcome.deleted);
    expect(steps.log, ['server', 'firestore:signed-in-user', 'local']);
  });

  test('when the server cannot be reached nothing else is deleted', () async {
    final auth = await _signedIn();
    final steps = _Steps()..serverFails = true;

    final result = await steps.service(auth).delete();

    expect(result.outcome, AccountDeletionOutcome.failed);
    expect(result.message, AccountDeletionMessages.server);
    expect(steps.log, ['server']);
    expect(auth.currentUser, isNotNull);
  });
}
