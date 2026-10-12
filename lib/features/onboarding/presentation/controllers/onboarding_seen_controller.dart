import 'package:careermatebd/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether first-run onboarding has already been shown. Resolved during the
/// splash so the router can decide between onboarding and login synchronously.
final onboardingSeenControllerProvider =
    AsyncNotifierProvider<OnboardingSeenController, bool>(
      OnboardingSeenController.new,
    );

class OnboardingSeenController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    try {
      return await ref.read(onboardingRepositoryProvider).isOnboardingSeen();
    } catch (_) {
      // Storage unavailable: fall back to showing onboarding rather than
      // blocking startup.
      return false;
    }
  }

  /// Marks onboarding as seen. State flips immediately; persistence is
  /// best-effort (worst case onboarding appears once more on the next launch).
  Future<void> markSeen() async {
    state = const AsyncData(true);
    try {
      await ref.read(onboardingRepositoryProvider).markOnboardingSeen();
    } catch (_) {
      // Intentionally ignored — see above.
    }
  }
}
