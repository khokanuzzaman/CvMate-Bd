import 'package:careermatebd/core/errors/app_exception.dart';
import 'package:careermatebd/features/account_deletion/data/account_deletion_service.dart';
import 'package:careermatebd/shared/services/ai/ai_server_client.dart';
import 'package:careermatebd/shared/services/billing/fake_billing_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_auth_repository.dart';

const _reauthRequired = AppException(
  AiFailureMessages.reauth,
  code: AiFailureCodes.reauthRequired,
);

/// Records the steps in the order they ran. Each server call throws the
/// next error in [serverErrors] (none left = success).
class _Steps {
  final List<String> log = [];
  final List<Exception> serverErrors = [];

  AccountDeletionService service(
    FakeAuthRepository auth, {
    FakeBillingService? billing,
  }) {
    return AccountDeletionService(
      auth: auth,
      deleteAccountOnServer: () async {
        log.add('server');
        if (serverErrors.isNotEmpty) {
          throw serverErrors.removeAt(0);
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
  test('one server call, then sign-out, RevenueCat and this device', () async {
    final auth = await _signedIn();
    final billing = FakeBillingService();
    final steps = _Steps();

    final result = await steps.service(auth, billing: billing).delete();

    expect(result.outcome, AccountDeletionOutcome.deleted);
    expect(steps.log, ['server', 'local']);
    expect(auth.reauthPasswords, isEmpty);
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

  test('reauth_required asks for the password; a wrong one stops before the '
      'server, the right one re-authenticates and retries once', () async {
    final auth = await _signedIn();
    final steps = _Steps()..serverErrors.add(_reauthRequired);
    final service = steps.service(auth);

    expect(
      (await service.delete()).outcome,
      AccountDeletionOutcome.needsPassword,
    );
    expect(steps.log, ['server']);
    expect(auth.currentUser, isNotNull);

    final wrong = await service.delete(password: 'nope');
    expect(wrong.outcome, AccountDeletionOutcome.failed);
    expect(wrong.message, contains('Incorrect password'));
    expect(steps.log, ['server'], reason: 'no server call after a bad reauth');

    expect(
      (await service.delete(password: 'secret12')).outcome,
      AccountDeletionOutcome.deleted,
    );
    expect(auth.reauthPasswords, ['nope', 'secret12']);
    expect(steps.log, ['server', 'server', 'local']);
  });

  test(
    'reauth_required again after the password fails instead of looping',
    () async {
      final auth = await _signedIn();
      final steps = _Steps()..serverErrors.add(_reauthRequired);

      final result = await steps.service(auth).delete(password: 'secret12');

      expect(result.outcome, AccountDeletionOutcome.failed);
      expect(result.message, AccountDeletionMessages.reauthFailed);
      expect(steps.log, ['server']);
      expect(auth.currentUser, isNotNull);
    },
  );

  test('a failed server call keeps the user signed in and the device data; '
      'a retry finishes', () async {
    final auth = await _signedIn();
    final steps = _Steps()..serverErrors.add(Exception('offline'));
    final service = steps.service(auth);

    final result = await service.delete();
    expect(result.outcome, AccountDeletionOutcome.failed);
    expect(result.message, AccountDeletionMessages.failed);
    expect(auth.currentUser, isNotNull);

    expect((await service.delete()).outcome, AccountDeletionOutcome.deleted);
    expect(steps.log, ['server', 'server', 'local']);
    expect(auth.currentUser, isNull);
  });
}
