import 'package:careermatebd/features/auth/data/repositories/firebase_auth_repository_impl.dart';
import 'package:careermatebd/features/auth/presentation/controllers/new_account_session_provider.dart';
import 'package:careermatebd/features/auth/presentation/controllers/register_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_auth_repository.dart';

void main() {
  test('a sign-up makes this a new account session (Home says "Welcome"); '
      'signing in to another account does not', () async {
    final auth = FakeAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(auth)],
    );
    addTearDown(() async {
      container.dispose();
      await auth.dispose();
    });
    container.listen(isNewAccountSessionProvider, (_, _) {});
    expect(container.read(isNewAccountSessionProvider), isFalse);

    final created = await container
        .read(registerControllerProvider.notifier)
        .register(
          email: 'new@example.com',
          password: 'secret123',
          confirmPassword: 'secret123',
        );
    expect(created, isTrue);
    expect(container.read(isNewAccountSessionProvider), isTrue);

    await auth.signOut();
    await auth.signInWithEmailAndPassword(
      email: 'old@example.com',
      password: 'secret123',
    );
    await Future<void>.delayed(Duration.zero);
    expect(container.read(isNewAccountSessionProvider), isFalse);
  });
}
