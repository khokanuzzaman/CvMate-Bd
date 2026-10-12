import 'package:careermatebd/app/router/route_names.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Text shown by the placeholder page of [path] (see [pumpRoutedScreen]).
String placeholderFor(String path) => 'page:$path';

/// Text a placeholder shows for the full location it was opened with, e.g.
/// `uri:/paywall?source=profile`.
String uriTextFor(String uri) => 'uri:$uri';

/// A container and router pumped by [pumpRoutedScreen].
class RoutedScreen {
  RoutedScreen(this.container, this.router);

  final ProviderContainer container;
  final GoRouter router;
}

/// Pumps [screen] at [path] inside a small router in which every other app
/// route is a placeholder page showing `placeholderFor(path)` — so a test can
/// tap something and check where it went. Routes in [routes] replace the
/// placeholders with real screens.
Future<RoutedScreen> pumpRoutedScreen(
  WidgetTester tester, {
  required String path,
  required Widget screen,
  List<Override> overrides = const [],
  Map<String, Widget> routes = const {},
  Size surface = const Size(390, 1200),
}) async {
  tester.view.physicalSize = surface;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(overrides: overrides);
  addTearDown(container.dispose);

  const knownPaths = [
    RouteNames.homePath,
    RouteNames.onboardingPath,
    RouteNames.loginPath,
    RouteNames.registerPath,
    RouteNames.settingsPath,
    RouteNames.profilePath,
    RouteNames.cvListPath,
    RouteNames.cvBuilderPath,
    RouteNames.aiImprovePath,
    RouteNames.jobTrackerPath,
    RouteNames.jobApplicationFormPath,
    RouteNames.jobApplicationDetailsPath,
    RouteNames.interviewPrepPath,
    RouteNames.tailoringPath,
    RouteNames.paywallPath,
  ];

  final pages = <String, GoRouterWidgetBuilder>{
    for (final known in knownPaths)
      known: (context, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(placeholderFor(known)),
              Text(uriTextFor(state.uri.toString())),
            ],
          ),
        ),
      ),
    for (final entry in routes.entries)
      entry.key: (context, state) => entry.value,
    path: (context, state) => screen,
  };

  final router = GoRouter(
    initialLocation: path,
    routes: [
      for (final entry in pages.entries)
        GoRoute(path: entry.key, builder: entry.value),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return RoutedScreen(container, router);
}
