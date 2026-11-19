import 'package:careermatebd/core/config/env_config.dart';
import 'package:careermatebd/features/auth/presentation/controllers/auth_session_provider.dart';
import 'package:careermatebd/shared/services/ai/mock_ai_career_service.dart';
import 'package:careermatebd/shared/services/ai/pending_ai_request.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The answer to an AI request the app sent but never showed because it was
/// closed or killed first. Fetched once per sign-in with the request's
/// original idempotency key, so the server replays it without a second charge.
/// Null when there is nothing to show. Watched by the app root.
final pendingAiResultProvider =
    AsyncNotifierProvider<PendingAiResultController, PendingAiRequest?>(
      PendingAiResultController.new,
    );

class PendingAiResultController extends AsyncNotifier<PendingAiRequest?> {
  @override
  Future<PendingAiRequest?> build() async {
    if (EnvConfig.isMockAiActive || Firebase.apps.isEmpty) {
      return null;
    }
    final uid = ref.watch(currentAuthUserProvider.select((user) => user?.uid));
    if (uid == null) {
      return null;
    }
    return ref.read(serverAiCareerServiceProvider).recoverPending();
  }

  /// The user has seen the result: forget it.
  Future<void> dismiss() async {
    final shown = state.asData?.value;
    state = const AsyncData(null);
    if (shown != null) {
      await ref.read(serverAiCareerServiceProvider).dismissPending(shown.key);
    }
  }
}
