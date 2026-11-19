import 'dart:async';

import 'package:careermatebd/features/auth/presentation/controllers/auth_session_provider.dart';
import 'package:careermatebd/shared/services/entitlement/ai_entitlement.dart';
import 'package:careermatebd/shared/services/entitlement/ai_entitlement_repository.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The signed-in user's AI quota, or null when unknown (signed out, or the
/// server was never reached on this device). Shows the cached value first,
/// then refreshes from the server.
final aiEntitlementProvider =
    AsyncNotifierProvider<AiEntitlementController, AiEntitlement?>(
      AiEntitlementController.new,
    );

/// How long to wait between entitlement checks after a purchase: the store
/// confirms on the device before RevenueCat's webhook reaches the server, so
/// the new plan shows up a few seconds later (about 15 s in total here).
final entitlementPollDelaysProvider = Provider<List<Duration>>((ref) {
  return const [
    Duration.zero,
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 3),
    Duration(seconds: 4),
    Duration(seconds: 5),
  ];
});

/// Refreshes the AI quota whenever the app comes back to the foreground.
/// Watched once by the app root.
final aiEntitlementResumeRefreshProvider = Provider<void>((ref) {
  final listener = AppLifecycleListener(
    onResume: () =>
        unawaited(ref.read(aiEntitlementProvider.notifier).refresh()),
  );
  ref.onDispose(listener.dispose);
});

class AiEntitlementController extends AsyncNotifier<AiEntitlement?> {
  String? _uid;

  @override
  Future<AiEntitlement?> build() async {
    if (Firebase.apps.isEmpty) {
      return null; // No Firebase (widget tests): nobody is signed in.
    }
    final uid = ref.watch(currentAuthUserProvider.select((user) => user?.uid));
    _uid = uid;
    if (uid == null) {
      return null;
    }
    final repository = ref.read(aiEntitlementRepositoryProvider);
    AiEntitlement? cached;
    try {
      cached = await repository.cached(uid);
    } catch (_) {
      cached = null;
    }
    if (cached != null) {
      // Show the cached value now; the server value replaces it shortly.
      Future.microtask(refresh);
      return cached;
    }
    try {
      return await repository.fetch(uid);
    } catch (_) {
      return null;
    }
  }

  /// Fetches the current value. Keeps the old one when the server is
  /// unreachable.
  Future<void> refresh() async {
    final uid = _uid;
    if (uid == null) {
      return;
    }
    try {
      final fresh = await ref.read(aiEntitlementRepositoryProvider).fetch(uid);
      if (ref.mounted && _uid == uid) {
        state = AsyncData(fresh);
      }
    } catch (_) {
      // Offline or server error: the cached value stays on screen.
    }
  }

  /// Right after a purchase or restore: asks the server to sync the purchase
  /// from RevenueCat and shows the result, so Pro appears at once instead of
  /// after the store webhook. Falls back to a plain [refresh] when the
  /// server cannot (offline, or a server without purchase sync).
  Future<void> syncPurchase() async {
    final uid = _uid;
    if (uid == null) {
      return;
    }
    try {
      final fresh = await ref.read(aiEntitlementRepositoryProvider).sync(uid);
      if (ref.mounted && _uid == uid) {
        state = AsyncData(fresh);
      }
    } catch (_) {
      await refresh();
    }
  }

  /// The current value, waiting for the first load. Null when unknown.
  Future<AiEntitlement?> current() async {
    try {
      return await future;
    } catch (_) {
      return null;
    }
  }

  /// Refreshes until [done] holds for the server's value, waiting
  /// [entitlementPollDelaysProvider] between tries. The first try is a
  /// purchase sync ([syncPurchase]); later ones poll, for when the server
  /// could not sync and the webhook has to arrive. Returns whether it did.
  Future<bool> refreshUntil(bool Function(AiEntitlement value) done) async {
    var first = true;
    for (final delay in ref.read(entitlementPollDelaysProvider)) {
      if (delay > Duration.zero) {
        await Future<void>.delayed(delay);
      }
      if (!ref.mounted) {
        return false;
      }
      if (first) {
        first = false;
        await syncPurchase();
      } else {
        await refresh();
      }
      final value = state.asData?.value;
      if (value != null && done(value)) {
        return true;
      }
    }
    return false;
  }

  /// Binds one purchased export unlock to [cvId]. True when the CV is (now)
  /// unlocked; false when no unlock is left, offline or signed out.
  Future<bool> claimExportUnlock(String cvId) async {
    final uid = _uid;
    final current = await this.current();
    if (uid == null || current == null) {
      return false;
    }
    if (current.hasUnlocked(cvId)) {
      return true;
    }
    try {
      final updated = await ref
          .read(aiEntitlementRepositoryProvider)
          .claimExportUnlock(uid, cvId, current);
      if (updated == null) {
        return false;
      }
      if (ref.mounted && _uid == uid) {
        state = AsyncData(updated);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Applies `remainingActions` from an AI response without another request.
  Future<void> applyRemaining(int remaining) async {
    final uid = _uid;
    final current = state.asData?.value;
    if (uid == null) {
      return;
    }
    if (current == null) {
      await refresh();
      return;
    }
    final updated = current.withActionsLeft(remaining);
    state = AsyncData(updated);
    try {
      await ref.read(aiEntitlementRepositoryProvider).saveCached(uid, updated);
    } catch (_) {
      // The cache is best-effort.
    }
  }
}
