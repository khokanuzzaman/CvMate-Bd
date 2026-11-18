import 'dart:collection';
import 'dart:developer' as developer;

import 'package:careermatebd/shared/services/analytics/analytics_events.dart';
import 'package:careermatebd/shared/services/analytics/analytics_sink.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService(sink: const FirebaseAnalyticsSink());
});

/// The only way the app talks to analytics. No screen calls Firebase.
///
/// - Accepts only [AnalyticsEvent]s that pass [AnalyticsSchema]: anything
///   else fails an assert (so tests catch it) and is dropped in release.
/// - Sends nothing while [enabled] is false: debug builds (unless
///   `ANALYTICS_DEBUG=true`) and when "Share usage analytics" is off.
/// - Keeps the last [recentLimit] event *names* for the optional diagnostics
///   in "Report a problem"; never parameters.
/// - Every call is best-effort: analytics can never crash or block the app.
class AnalyticsService {
  AnalyticsService({
    required AnalyticsSink sink,
    this.recentLimit = 20,
    bool enabled = false,
  }) : _sink = sink,
       _enabled = enabled;

  final AnalyticsSink _sink;
  final int recentLimit;
  final Queue<String> _recent = Queue<String>();
  bool _enabled;

  bool get enabled => _enabled;

  /// Oldest first.
  List<String> get recentEventNames => List.unmodifiable(_recent);

  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    await _safely(() => _sink.setCollectionEnabled(enabled));
  }

  Future<void> log(AnalyticsEvent event) async {
    final problems = AnalyticsSchema.violations(event);
    assert(problems.isEmpty, 'Analytics event refused: $problems');
    if (problems.isNotEmpty) {
      return;
    }
    _remember(event.name);
    if (_enabled) {
      await _safely(() => _sink.logEvent(event.name, event.params));
    }
  }

  /// [screenName] is a GoRoute name (never a path, which can carry ids).
  Future<void> screenView(String screenName) async {
    if (!AnalyticsSchema.screenName.hasMatch(screenName)) {
      return;
    }
    if (_enabled) {
      await _safely(() => _sink.logScreenView(screenName));
    }
  }

  Future<void> setPlan(PlanProperty plan) async {
    if (_enabled) {
      await _safely(() => _sink.setUserProperty('plan', plan.wire));
    }
  }

  /// After account deletion: a new analytics identity from now on.
  Future<void> resetIdentity() async {
    _recent.clear();
    await _safely(_sink.reset);
  }

  void _remember(String name) {
    _recent.addLast(name);
    while (_recent.length > recentLimit) {
      _recent.removeFirst();
    }
  }

  Future<void> _safely(Future<void> Function() call) async {
    try {
      await call();
    } catch (error) {
      // Not configured on this platform, or Firebase not initialized (tests).
      developer.log(
        'Analytics call failed (${error.runtimeType}).',
        name: 'cvmate.analytics',
      );
    }
  }
}
