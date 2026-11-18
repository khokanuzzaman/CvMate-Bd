import 'package:careermatebd/features/cv_builder/domain/entities/cv_style.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_template.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_step.dart';
import 'package:careermatebd/shared/services/analytics/analytics_events.dart';
import 'package:careermatebd/shared/services/analytics/analytics_route_observer.dart';
import 'package:careermatebd/shared/services/analytics/analytics_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/core_flow_harness.dart';

/// Every event the app can build, with every value of every parameter.
List<AnalyticsEvent> _everyEvent() => [
  AnalyticsEvent.appOpen,
  for (var step = 1; step <= 3; step++) AnalyticsEvent.onboardingStep(step),
  for (final choice in OnboardingChoice.values)
    AnalyticsEvent.onboardingComplete(choice),
  for (final method in AuthMethod.values) ...[
    AnalyticsEvent.signUp(method),
    AnalyticsEvent.login(method),
  ],
  AnalyticsEvent.logout,
  for (final style in CvStyle.values) AnalyticsEvent.cvCreated(style),
  for (final step in CvBuilderStep.values)
    AnalyticsEvent.cvSectionCompleted(step),
  for (final template in CvTemplate.values)
    AnalyticsEvent.templateSelected(template),
  for (final kind in AtsCheckKind.values)
    for (final score in [0, 39, 40, 59, 60, 79, 80, 100])
      AnalyticsEvent.atsCheckRun(kind, score),
  AnalyticsEvent.aiConsentShown,
  for (final result in ConsentResult.values)
    AnalyticsEvent.aiConsentResult(result),
  for (final action in AiAction.values) ...[
    AnalyticsEvent.aiActionStart(action),
    AnalyticsEvent.quotaExhausted(action),
    for (final result in AiResult.values)
      for (final ms in [10, 1500, 5000, 20000, 45000, 90000])
        AnalyticsEvent.aiActionResult(
          action,
          result,
          Duration(milliseconds: ms),
        ),
  ],
  for (final source in PaywallSource.values) AnalyticsEvent.paywallView(source),
  for (final package in PurchasePackage.values) ...[
    AnalyticsEvent.purchaseStart(package),
    for (final result in PurchaseResult.values)
      AnalyticsEvent.purchaseResult(result, package),
  ],
  for (final result in RestoreResult.values)
    AnalyticsEvent.restoreResult(result),
  for (final source in ExportSource.values)
    for (final format in ExportFormat.values) ...[
      AnalyticsEvent.exportStart(source, format),
      for (final result in ExportResult.values)
        AnalyticsEvent.exportResult(source, format, result),
      for (final gate in ExportGate.values)
        AnalyticsEvent.exportResult(
          source,
          format,
          ExportResult.ok,
          gate: gate,
        ),
    ],
  for (final trigger in ReviewTrigger.values)
    AnalyticsEvent.reviewPromptRequested(trigger),
  AnalyticsEvent.feedbackOpen,
  for (final category in FeedbackCategory.values)
    for (final diagnostics in [true, false])
      AnalyticsEvent.feedbackSent(category, diagnostics: diagnostics),
  for (final account in AccountKind.values) ...[
    AnalyticsEvent.accountDeleteStart(account),
    for (final result in DeleteResult.values)
      AnalyticsEvent.accountDeleteResult(account, result),
  ],
];

void main() {
  test('every event the app can build is in the schema, with only '
      'allowed enum values', () {
    final events = _everyEvent();
    for (final event in events) {
      expect(AnalyticsSchema.violations(event), isEmpty, reason: '$event');
      for (final value in event.params.values) {
        expect(value, anyOf(isA<int>(), matches(RegExp(r'^[a-z0-9_]+$'))));
      }
    }
    // Every schema entry is used, and the docs list matches the schema.
    expect(
      events.map((event) => event.name).toSet(),
      AnalyticsSchema.events.keys.toSet(),
    );
  });

  test('free text, unknown parameters and unknown events are refused', () {
    const freeText = AnalyticsEvent.raw('paywall_view', {
      'source': 'Rahim Uddin, rahim@example.com',
    });
    const extraParam = AnalyticsEvent.raw('logout', {'email': 'a@b.c'});
    const unknown = AnalyticsEvent.raw('cv_text', {});
    const outOfRange = AnalyticsEvent.raw('onboarding_step', {'step': 99});

    for (final event in [freeText, extraParam, unknown, outOfRange]) {
      expect(AnalyticsSchema.violations(event), isNotEmpty, reason: '$event');
    }
    // The service refuses it: an assert in tests, never sent.
    final analytics = RecordingAnalytics();
    expect(() => analytics.log(freeText), throwsA(isA<AssertionError>()));
    expect(analytics.events, isEmpty);
  });

  test('a deep-link paywall source never reaches analytics as text', () {
    expect(PaywallSource.parse('ai_quota'), PaywallSource.aiQuota);
    expect(PaywallSource.parse('<script>'), PaywallSource.other);
    expect(PaywallSource.parse(null), PaywallSource.other);
  });

  test('sends nothing while disabled, and keeps only the last 20 event '
      'names for diagnostics', () async {
    final sink = RecordingAnalyticsSink();
    final analytics = AnalyticsService(sink: sink);

    for (var i = 0; i < 25; i++) {
      await analytics.log(AnalyticsEvent.logout);
    }
    await analytics.log(AnalyticsEvent.feedbackOpen);

    expect(sink.events, isEmpty);
    expect(analytics.recentEventNames, hasLength(20));
    expect(analytics.recentEventNames.last, 'feedback_open');

    await analytics.setEnabled(true);
    await analytics.log(AnalyticsEvent.logout);
    expect(sink.events.single.$1, 'logout');
  });

  testWidgets('screen views use the route name, never the path or query', (
    tester,
  ) async {
    final analytics = RecordingAnalytics();
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        navigatorObservers: [AnalyticsRouteObserver(analytics)],
        home: const SizedBox(),
      ),
    );

    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: 'cv-preview'),
        builder: (_) => const SizedBox(),
      ),
    );
    await tester.pumpAndSettle();
    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/cvs/preview?id=abc'),
        builder: (_) => const SizedBox(),
      ),
    );
    await tester.pumpAndSettle();

    expect(analytics.sink.screens, ['cv-preview']);
  });
}
