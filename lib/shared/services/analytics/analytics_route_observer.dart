import 'dart:async';

import 'package:careermatebd/shared/services/analytics/analytics_service.dart';
import 'package:flutter/widgets.dart';

/// Logs `screen_view` for every GoRoute shown, by route *name* (for example
/// `cv-preview`), never by path or query, which can carry ids. Dialogs and
/// sheets are not screens and are skipped.
///
/// One instance per GoRouter (a NavigatorObserver belongs to one Navigator).
class AnalyticsRouteObserver extends NavigatorObserver {
  AnalyticsRouteObserver(this.analytics);

  final AnalyticsService analytics;

  void _log(Route<dynamic>? route) {
    if (route is! PageRoute) {
      return;
    }
    final name = route.settings.name;
    if (name != null && name.isNotEmpty) {
      unawaited(analytics.screenView(name));
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _log(route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _log(newRoute);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) {
      _log(previousRoute);
    }
  }
}
