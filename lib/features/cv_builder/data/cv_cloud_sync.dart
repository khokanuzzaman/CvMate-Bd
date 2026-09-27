import 'dart:async';

import 'package:careermatebd/features/auth/domain/entities/auth_user.dart';
import 'package:careermatebd/features/auth/presentation/controllers/auth_session_provider.dart';
import 'package:careermatebd/features/cv_builder/data/repositories/cv_repository_impl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Activates CV cloud restore. Keep it alive by `ref.watch`-ing it once near the
/// app root.
///
/// Whenever a user is available — a guest (anonymous) or a real account,
/// including after an anonymous → account upgrade, which keeps the same uid —
/// it reconciles that user's Firestore CVs into local Hive. It is best-effort:
/// signed-out users are a no-op, and it never blocks or throws into the UI, so
/// the local-only/guest flow keeps working exactly as before.
///
/// Note: this intentionally does NOT force an anonymous sign-in on launch, so
/// the existing signed-out "Explore as guest" onboarding flow is preserved.
/// [AuthRepository.signInAnonymously] is available to wire a "guest with cloud
/// backup" entry point later without changing that flow here.
final cvCloudSyncProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<AuthUser?>>(authSessionProvider, (previous, next) {
    final user = next.asData?.value;
    if (user == null) {
      return;
    }
    unawaited(ref.read(cvRepositoryImplProvider).pullAndReconcile());
  }, fireImmediately: true);
});
