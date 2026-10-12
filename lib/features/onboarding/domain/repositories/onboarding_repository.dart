/// Persists whether the first-run onboarding has been shown on this device.
abstract class OnboardingRepository {
  Future<bool> isOnboardingSeen();

  Future<void> markOnboardingSeen();
}
