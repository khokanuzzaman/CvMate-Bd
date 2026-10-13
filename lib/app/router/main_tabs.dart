import 'package:careermatebd/app/router/route_names.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// The five bottom-nav slots (see `BottomNavBar.defaultItems`) and where each
/// one leads.
///
/// Home, Tracker and Profile are tabs: switching replaces the current screen so
/// the back stack does not pile up. CVs and Tailor are flows with their own
/// back button, so they are pushed on top.
abstract final class MainTabs {
  static const int home = 0;
  static const int cvs = 1;
  static const int tailor = 2;
  static const int tracker = 3;
  static const int profile = 4;

  /// Navigates to the tab at [index]; a no-op when it is already [current].
  static void open(BuildContext context, int index, {required int current}) {
    if (index == current) {
      return;
    }
    switch (index) {
      case home:
        context.go(RouteNames.homePath);
      case cvs:
        context.push(RouteNames.cvListPath);
      case tailor:
        context.push(RouteNames.tailoringPath);
      case tracker:
        context.go(RouteNames.jobTrackerPath);
      case profile:
        context.go(RouteNames.profilePath);
    }
  }
}
