import 'package:careermatebd/features/onboarding/domain/repositories/onboarding_repository.dart';

/// In-memory [OnboardingRepository]. Flip [throwOnRead] / [throwOnWrite] to
/// simulate unavailable storage.
class FakeOnboardingRepository implements OnboardingRepository {
  FakeOnboardingRepository({
    this.seen = false,
    this.throwOnRead = false,
    this.throwOnWrite = false,
  });

  bool seen;
  bool throwOnRead;
  bool throwOnWrite;

  @override
  Future<bool> isOnboardingSeen() async {
    if (throwOnRead) {
      throw StateError('storage unavailable');
    }
    return seen;
  }

  @override
  Future<void> markOnboardingSeen() async {
    if (throwOnWrite) {
      throw StateError('storage unavailable');
    }
    seen = true;
  }
}
