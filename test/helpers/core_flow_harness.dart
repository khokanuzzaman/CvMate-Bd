import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/features/cover_letter/data/repositories/cover_letter_repository_impl.dart';
import 'package:careermatebd/features/cover_letter/domain/entities/cover_letter_draft.dart';
import 'package:careermatebd/features/cover_letter/domain/repositories/cover_letter_repository.dart';
import 'package:careermatebd/features/cover_letter/presentation/screens/cover_letter_screen.dart';
import 'package:careermatebd/features/cv_builder/data/repositories/cv_repository_impl.dart';
import 'package:careermatebd/features/subscription/presentation/screens/paywall_screen.dart';
import 'package:careermatebd/features/tailoring/presentation/screens/tailoring_screen.dart';
import 'package:careermatebd/shared/services/ai/mock_ai_career_service.dart';
import 'package:careermatebd/shared/services/analytics/analytics_service.dart';
import 'package:careermatebd/shared/services/analytics/analytics_sink.dart';
import 'package:careermatebd/shared/services/entitlement/entitlement_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'builder_harness.dart';
import 'fake_ai_career_service.dart';
import 'fake_cv_repository.dart';

const String homePlaceholder = 'home-page';
const String builderPlaceholder = 'builder-page';

/// In-memory [CoverLetterRepository].
class FakeCoverLetterRepository implements CoverLetterRepository {
  FakeCoverLetterRepository([Iterable<CoverLetterDraft> initial = const []])
    : drafts = [...initial];

  final List<CoverLetterDraft> drafts;
  int saveCount = 0;

  @override
  Future<List<CoverLetterDraft>> getAllDrafts() async => [...drafts];

  @override
  Future<CoverLetterDraft> saveDraft(CoverLetterDraft draft) async {
    drafts
      ..removeWhere((item) => item.id == draft.id)
      ..add(draft);
    saveCount++;
    return draft;
  }

  @override
  Future<CoverLetterDraft?> getDraftById(String id) async {
    for (final draft in drafts) {
      if (draft.id == id) {
        return draft;
      }
    }
    return null;
  }

  @override
  Future<void> deleteDraft(String id) async {
    drafts.removeWhere((item) => item.id == id);
  }

  @override
  Future<void> clearAllDrafts() async => drafts.clear();
}

/// Records analytics events instead of sending them. Every event still
/// goes through [AnalyticsService.log], so an event with a free-text or
/// unknown parameter fails the test (see [AnalyticsSchema]).
class RecordingAnalytics extends AnalyticsService {
  RecordingAnalytics() : this._(RecordingAnalyticsSink());

  RecordingAnalytics._(this.sink) : super(sink: sink, enabled: true);

  final RecordingAnalyticsSink sink;

  List<(String, Map<String, Object>)> get events => sink.events;

  Iterable<Map<String, Object>> paramsFor(String name) => [
    for (final (eventName, params) in events)
      if (eventName == name) params,
  ];
}

class RecordingAnalyticsSink implements AnalyticsSink {
  final List<(String, Map<String, Object>)> events = [];
  final List<String> screens = [];
  final Map<String, String?> userProperties = {};
  final List<bool> collection = [];
  int resets = 0;

  @override
  Future<void> logEvent(String name, Map<String, Object> params) async =>
      events.add((name, params));

  @override
  Future<void> logScreenView(String screenName) async =>
      screens.add(screenName);

  @override
  Future<void> setUserProperty(String name, String? value) async =>
      userProperties[name] = value;

  @override
  Future<void> setCollectionEnabled(bool enabled) async =>
      collection.add(enabled);

  @override
  Future<void> reset() async => resets++;
}

class CoreFlowApp {
  CoreFlowApp(
    this.container,
    this.router,
    this.ai,
    this.letters,
    this.analytics,
  );

  final ProviderContainer container;
  final GoRouter router;
  final FakeAiCareerService ai;
  final FakeCoverLetterRepository letters;
  final RecordingAnalytics analytics;
}

/// Pumps the real Tailoring, Cover letter and Paywall screens in a small router
/// (home and the CV builder are placeholders), with a scripted AI service and
/// in-memory repositories. Starts on the home placeholder; call
/// `app.router.push(...)` to open a screen so back navigation can be tested.
Future<CoreFlowApp> pumpCoreFlow(
  WidgetTester tester, {
  required FakeCvRepository repository,
  FakeEntitlementStore? entitlements,
  FakeAiCareerService? ai,
  FakeCoverLetterRepository? letters,
  RecordingAnalytics? analytics,
  Size surface = const Size(390, 1000),
  List<Override> overrides = const [],
}) async {
  tester.view.physicalSize = surface;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final fakeAi = ai ?? FakeAiCareerService();
  final fakeLetters = letters ?? FakeCoverLetterRepository();
  final recorder = analytics ?? RecordingAnalytics();
  final container = ProviderContainer(
    overrides: [
      cvRepositoryProvider.overrideWithValue(repository),
      aiCareerServiceProvider.overrideWithValue(fakeAi),
      coverLetterRepositoryProvider.overrideWithValue(fakeLetters),
      analyticsServiceProvider.overrideWithValue(recorder),
      entitlementServiceProvider.overrideWithValue(
        EntitlementService(entitlements ?? FakeEntitlementStore()),
      ),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);

  Widget placeholder(String label) =>
      Scaffold(body: Center(child: Text(label)));

  final router = GoRouter(
    initialLocation: RouteNames.homePath,
    routes: [
      GoRoute(
        path: RouteNames.homePath,
        builder: (context, state) => placeholder(homePlaceholder),
      ),
      GoRoute(
        path: RouteNames.tailoringPath,
        builder: (context, state) => const TailoringScreen(),
      ),
      GoRoute(
        path: RouteNames.coverLetterPath,
        builder: (context, state) => const CoverLetterScreen(),
      ),
      GoRoute(
        path: RouteNames.paywallPath,
        builder: (context, state) =>
            PaywallScreen(source: state.uri.queryParameters['source']),
      ),
      GoRoute(
        path: RouteNames.cvBuilderPath,
        builder: (context, state) => placeholder(builderPlaceholder),
      ),
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
  return CoreFlowApp(container, router, fakeAi, fakeLetters, recorder);
}
