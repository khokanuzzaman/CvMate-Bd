import 'package:careermatebd/app/router/app_router.dart';
import 'package:careermatebd/features/auth/data/repositories/firebase_auth_repository_impl.dart';
import 'package:careermatebd/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_onboarding_repository.dart';

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  // Regression: the router used to be rebuilt on every auth change, which
  // reset navigation to the splash mid-flow. Settings > Delete account then
  // lost its screen and ended on login or Home without a word.
  test('sign-in and sign-out keep the same router', () async {
    final auth = FakeAuthRepository();
    addTearDown(auth.dispose);
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        onboardingRepositoryProvider.overrideWithValue(
          FakeOnboardingRepository(seen: true),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(appRouterProvider, (_, _) {});
    final router = container.read(appRouterProvider);

    await auth.signInWithEmailAndPassword(email: 'a@b.c', password: 'secret12');
    await _settle();
    expect(container.read(appRouterProvider), same(router));

    await auth.signOut();
    await _settle();
    expect(container.read(appRouterProvider), same(router));
  });
}
