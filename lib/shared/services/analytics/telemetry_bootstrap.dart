import 'dart:async';

import 'package:careermatebd/core/config/env_config.dart';
import 'package:careermatebd/features/auth/presentation/controllers/auth_session_provider.dart';
import 'package:careermatebd/features/settings/presentation/controllers/app_preferences_controller.dart';
import 'package:careermatebd/shared/services/analytics/analytics_events.dart';
import 'package:careermatebd/shared/services/analytics/analytics_service.dart';
import 'package:careermatebd/shared/services/crash/crash_reporter.dart';
import 'package:careermatebd/shared/services/entitlement/ai_entitlement_controller.dart';
import 'package:careermatebd/shared/services/review/review_prompter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether this build may send analytics and crash reports (release, or
/// `ANALYTICS_DEBUG=true`). A provider so tests can turn it on.
final telemetryAllowedInBuildProvider = Provider<bool>((ref) {
  return EnvConfig.telemetryAllowedInBuild;
});

/// Keep alive with one `ref.watch` at the app root. It:
/// - turns Analytics and Crashlytics on or off from "Share usage analytics"
///   the moment the switch changes;
/// - logs `app_open` once per launch;
/// - sets the Crashlytics user id (hashed uid) and the `plan` user property;
/// - counts the launch for the rating rules.
final telemetryBootstrapProvider = Provider<void>((ref) {
  final analytics = ref.read(analyticsServiceProvider);
  final crash = ref.read(crashReporterProvider);
  final allowedInBuild = ref.read(telemetryAllowedInBuildProvider);
  var appOpenLogged = false;
  PlanProperty? plan;

  Future<void> apply(bool share) async {
    final enabled = allowedInBuild && share;
    await analytics.setEnabled(enabled);
    await crash.setEnabled(enabled);
    if (!appOpenLogged) {
      appOpenLogged = true;
      await analytics.log(AnalyticsEvent.appOpen);
    }
    if (plan case final current?) {
      await analytics.setPlan(current);
    }
  }

  ref.listen(appPreferencesControllerProvider, (previous, next) {
    final share = next.asData?.value.shareUsageAnalytics;
    if (share != null && share != previous?.asData?.value.shareUsageAnalytics) {
      unawaited(apply(share));
    }
  }, fireImmediately: true);

  ref.listen(currentAuthUserProvider, (previous, user) {
    if (user?.uid != previous?.uid) {
      unawaited(crash.setUser(user?.uid));
    }
  }, fireImmediately: true);

  ref.listen(aiEntitlementProvider, (previous, next) {
    final entitlement = next.asData?.value;
    if (entitlement == null) {
      return;
    }
    final current = entitlement.isProAt(DateTime.now())
        ? PlanProperty.pro
        : PlanProperty.free;
    if (current != plan) {
      plan = current;
      unawaited(analytics.setPlan(current));
    }
  }, fireImmediately: true);

  unawaited(ref.read(reviewPrompterProvider).recordLaunch());
});
