import 'package:careermatebd/app/router/main_tabs.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/widgets/bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/routed_screen_harness.dart';

Future<RoutedScreen> _openOn(
  WidgetTester tester,
  int current, {
  String path = RouteNames.jobTrackerPath,
}) {
  return pumpRoutedScreen(
    tester,
    path: path,
    screen: Builder(
      builder: (context) => Scaffold(
        body: const Text('tab-screen'),
        bottomNavigationBar: BottomNavBar(
          currentIndex: current,
          onTap: (index) => MainTabs.open(context, index, current: current),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('tapping the current tab does nothing', (tester) async {
    await _openOn(tester, MainTabs.tracker);

    await tester.tap(find.text('Tracker'));
    await tester.pumpAndSettle();

    expect(find.text('tab-screen'), findsOneWidget);
  });

  testWidgets('Home, Tracker and Profile replace the screen', (tester) async {
    for (final (label, path) in [
      ('Home', RouteNames.homePath),
      ('Profile', RouteNames.profilePath),
    ]) {
      final app = await _openOn(tester, MainTabs.tracker);

      await tester.tap(find.text(label));
      await tester.pumpAndSettle();

      expect(find.text(placeholderFor(path)), findsOneWidget, reason: label);
      expect(app.router.canPop(), isFalse, reason: '$label is not stacked');
    }
  });

  testWidgets('Tracker replaces when coming from another tab', (tester) async {
    final app = await _openOn(tester, MainTabs.home, path: RouteNames.homePath);

    await tester.tap(find.text('Tracker'));
    await tester.pumpAndSettle();

    expect(find.text('tab-screen'), findsNothing);
    expect(
      find.text(placeholderFor(RouteNames.jobTrackerPath)),
      findsOneWidget,
    );
    expect(app.router.canPop(), isFalse);
  });

  testWidgets('CVs and Tailor are pushed so Back returns', (tester) async {
    for (final (label, path) in [
      ('CVs', RouteNames.cvListPath),
      ('Tailor', RouteNames.tailoringPath),
    ]) {
      final app = await _openOn(tester, MainTabs.tracker);

      await tester.tap(find.text(label));
      await tester.pumpAndSettle();

      expect(find.text(placeholderFor(path)), findsOneWidget, reason: label);
      expect(app.router.canPop(), isTrue, reason: '$label is pushed');

      app.router.pop();
      await tester.pumpAndSettle();
      expect(find.text('tab-screen'), findsOneWidget, reason: label);
    }
  });
}
