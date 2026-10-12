import 'package:careermatebd/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:careermatebd/features/onboarding/presentation/controllers/onboarding_seen_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_onboarding_repository.dart';

ProviderContainer _container(FakeOnboardingRepository repository) {
  final container = ProviderContainer(
    overrides: [onboardingRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('is not seen on a fresh install', () async {
    final container = _container(FakeOnboardingRepository());

    final seen = await container.read(onboardingSeenControllerProvider.future);

    expect(seen, isFalse);
  });

  test('restores a previously saved seen flag', () async {
    final container = _container(FakeOnboardingRepository(seen: true));

    final seen = await container.read(onboardingSeenControllerProvider.future);

    expect(seen, isTrue);
  });

  test('markSeen updates state and persists the flag', () async {
    final repository = FakeOnboardingRepository();
    final container = _container(repository);
    await container.read(onboardingSeenControllerProvider.future);

    await container.read(onboardingSeenControllerProvider.notifier).markSeen();

    expect(container.read(onboardingSeenControllerProvider).value, isTrue);
    expect(repository.seen, isTrue);
  });

  test('falls back to not seen when storage cannot be read', () async {
    final container = _container(FakeOnboardingRepository(throwOnRead: true));

    final seen = await container.read(onboardingSeenControllerProvider.future);

    expect(seen, isFalse);
  });

  test('markSeen still flips state when persisting fails', () async {
    final repository = FakeOnboardingRepository(throwOnWrite: true);
    final container = _container(repository);
    await container.read(onboardingSeenControllerProvider.future);

    await container.read(onboardingSeenControllerProvider.notifier).markSeen();

    expect(container.read(onboardingSeenControllerProvider).value, isTrue);
    expect(repository.seen, isFalse);
  });
}
