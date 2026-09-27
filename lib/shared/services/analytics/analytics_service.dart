import 'dart:async';

import 'package:careermatebd/shared/services/analytics/analytics_events.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return const AnalyticsService();
});

/// Logs app_open once, when first read. Keep it alive with a single
/// `ref.watch(analyticsBootstrapProvider)` near the app root.
final analyticsBootstrapProvider = Provider<void>((ref) {
  unawaited(ref.read(analyticsServiceProvider).logEvent(AnalyticsEvents.appOpen));
});

/// Thin wrapper over Firebase Analytics for the core funnel.
///
/// Every call is best-effort: failures are swallowed so analytics can never
/// crash or block the app (e.g. Analytics not configured on a platform, or
/// Firebase not initialized in a unit test).
class AnalyticsService {
  const AnalyticsService();

  Future<void> logEvent(String name, {Map<String, Object>? params}) async {
    try {
      await FirebaseAnalytics.instance.logEvent(name: name, parameters: params);
    } catch (_) {
      // Intentionally ignored — analytics must not affect app behaviour.
    }
  }
}
