import 'dart:async';

import 'package:careermatebd/app/router/router_ai_interaction_port.dart';
import 'package:careermatebd/features/settings/presentation/controllers/app_preferences_controller.dart';
import 'package:careermatebd/shared/services/analytics/analytics_events.dart';
import 'package:careermatebd/shared/services/analytics/analytics_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The UI the AI service layer needs without holding a [BuildContext]:
/// the one-time consent sheet and the paywall.
abstract class AiInteractionPort {
  /// Shows the AI consent sheet. True when the user tapped "Allow AI".
  Future<bool> requestAiConsent();

  /// Opens the paywall, e.g. with source `ai_quota`.
  void openPaywall(String source);
}

final aiConsentGuardProvider = Provider<AiConsentGuard>((ref) {
  return AiConsentGuard(
    hasConsent: () async =>
        (await ref.read(appPreferencesControllerProvider.future)).aiConsent,
    grantConsent: () => ref
        .read(appPreferencesControllerProvider.notifier)
        .updateAiConsent(enabled: true),
    askForConsent: () => ref.read(aiInteractionPortProvider).requestAiConsent(),
    onAsked: () => unawaited(
      ref.read(analyticsServiceProvider).log(AnalyticsEvent.aiConsentShown),
    ),
    onAnswered: (allowed) => unawaited(
      ref
          .read(analyticsServiceProvider)
          .log(
            AnalyticsEvent.aiConsentResult(
              allowed ? ConsentResult.allowed : ConsentResult.notNow,
            ),
          ),
    ),
  );
});

/// The single AI consent check (App Store guideline 5.1.2). Every AI call goes
/// through [GuardedAiCareerService], which asks this guard first: without
/// consent the sheet is shown, and if the user says "Not now" no request is
/// sent.
class AiConsentGuard {
  AiConsentGuard({
    required this.hasConsent,
    required this.grantConsent,
    required this.askForConsent,
    this.onAsked,
    this.onAnswered,
  });

  final Future<bool> Function() hasConsent;
  final Future<void> Function() grantConsent;
  final Future<bool> Function() askForConsent;

  /// Analytics: the sheet was shown, and what the user chose.
  final void Function()? onAsked;
  final void Function(bool allowed)? onAnswered;

  Future<bool>? _pending;

  /// True when AI may run. Two AI actions started together share one sheet.
  Future<bool> ensureConsent() async {
    if (await _safely(hasConsent)) {
      return true;
    }
    final pending = _pending ??= _ask();
    try {
      return await pending;
    } finally {
      if (identical(_pending, pending)) {
        _pending = null;
      }
    }
  }

  Future<bool> _ask() async {
    onAsked?.call();
    final allowed = await _safely(askForConsent);
    onAnswered?.call(allowed);
    if (allowed) {
      await grantConsent();
    }
    return allowed;
  }

  Future<bool> _safely(Future<bool> Function() read) async {
    try {
      return await read();
    } catch (_) {
      return false;
    }
  }
}
