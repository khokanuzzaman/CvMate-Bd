import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/features/ats_checker/presentation/screens/ats_checker_screen.dart';
import 'package:careermatebd/features/cover_letter/data/repositories/cover_letter_repository_impl.dart';
import 'package:careermatebd/features/cover_letter/domain/entities/cover_letter_draft.dart';
import 'package:careermatebd/features/cover_letter/domain/repositories/cover_letter_repository.dart';
import 'package:careermatebd/features/cover_letter/presentation/screens/cover_letter_screen.dart';
import 'package:careermatebd/features/cv_builder/data/repositories/cv_repository_impl.dart';
import 'package:careermatebd/features/interview_prep/data/repositories/interview_prep_session_repository_impl.dart';
import 'package:careermatebd/features/job_tracker/data/repositories/job_application_repository_impl.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_application.dart';
import 'package:careermatebd/features/job_tracker/domain/repositories/job_application_repository.dart';
import 'package:careermatebd/features/job_tracker/presentation/screens/job_application_details_screen.dart';
import 'package:careermatebd/features/job_tracker/presentation/screens/job_application_form_screen.dart';
import 'package:careermatebd/features/job_tracker/presentation/screens/job_tracker_screen.dart';
import 'package:careermatebd/features/interview_prep/domain/entities/interview_prep_session.dart';
import 'package:careermatebd/features/interview_prep/domain/repositories/interview_prep_session_repository.dart';
import 'package:careermatebd/features/interview_prep/presentation/screens/interview_prep_screen.dart';
import 'package:careermatebd/features/subscription/presentation/screens/paywall_screen.dart';
import 'package:careermatebd/features/tailoring/presentation/screens/tailoring_screen.dart';
import 'package:careermatebd/shared/services/ai/mock_ai_career_service.dart';
import 'package:careermatebd/shared/services/analytics/analytics_service.dart';
import 'package:careermatebd/shared/services/entitlement/entitlement_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'builder_harness.dart';
import 'fake_ai_career_service.dart';
import 'fake_cv_repository.dart';

const String homePlaceholder = 'home-page';
const String builderPlaceholder = 'builder-page';
const String aiImproveHarnessPlaceholder = 'ai-improve-page';
const String cvListPlaceholder = 'cv-list-page';

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

/// In-memory [InterviewPrepSessionRepository].
class FakeInterviewSessionRepository implements InterviewPrepSessionRepository {
  FakeInterviewSessionRepository([
    Iterable<InterviewPrepSession> initial = const [],
  ]) : sessions = [...initial];

  final List<InterviewPrepSession> sessions;
  int saveCount = 0;

  @override
  Future<List<InterviewPrepSession>> getAllSessions() async => [...sessions];

  @override
  Future<InterviewPrepSession?> getSessionById(String id) async {
    for (final session in sessions) {
      if (session.id == id) {
        return session;
      }
    }
    return null;
  }

  @override
  Future<InterviewPrepSession> saveSession(InterviewPrepSession session) async {
    sessions
      ..removeWhere((item) => item.id == session.id)
      ..add(session);
    saveCount++;
    return session;
  }

  @override
  Future<void> clearAllSessions() async => sessions.clear();
}

/// In-memory [JobApplicationRepository].
class FakeJobApplicationRepository implements JobApplicationRepository {
  FakeJobApplicationRepository([Iterable<JobApplication> initial = const []])
    : applications = [...initial];

  final List<JobApplication> applications;
  int saveCount = 0;

  JobApplication? byId(String id) {
    for (final application in applications) {
      if (application.id == id) {
        return application;
      }
    }
    return null;
  }

  @override
  Future<List<JobApplication>> getAllApplications() async =>
      [...applications]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  @override
  Future<JobApplication?> getApplicationById(String id) async => byId(id);

  @override
  Future<JobApplication> saveApplication(JobApplication application) async {
    applications
      ..removeWhere((item) => item.id == application.id)
      ..add(application);
    saveCount++;
    return application;
  }

  @override
  Future<void> deleteApplication(String id) async {
    applications.removeWhere((item) => item.id == id);
  }

  @override
  Future<void> clearAllApplications() async => applications.clear();
}

/// Records analytics events instead of sending them.
class RecordingAnalytics extends AnalyticsService {
  RecordingAnalytics();

  final List<(String, Map<String, Object>?)> events = [];

  Iterable<Map<String, Object>?> paramsFor(String name) => [
    for (final (eventName, params) in events)
      if (eventName == name) params,
  ];

  @override
  Future<void> logEvent(String name, {Map<String, Object>? params}) async {
    events.add((name, params));
  }
}

class CoreFlowApp {
  CoreFlowApp(
    this.container,
    this.router,
    this.ai,
    this.letters,
    this.analytics,
    this.jobs,
  );

  final ProviderContainer container;
  final GoRouter router;
  final FakeAiCareerService ai;
  final FakeCoverLetterRepository letters;
  final RecordingAnalytics analytics;
  final FakeJobApplicationRepository jobs;
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
  FakeInterviewSessionRepository? interviewSessions,
  FakeJobApplicationRepository? jobApplications,
  Size surface = const Size(390, 1000),
}) async {
  tester.view.physicalSize = surface;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final fakeAi = ai ?? FakeAiCareerService();
  final fakeLetters = letters ?? FakeCoverLetterRepository();
  final recorder = analytics ?? RecordingAnalytics();
  final fakeSessions = interviewSessions ?? FakeInterviewSessionRepository();
  final fakeJobs = jobApplications ?? FakeJobApplicationRepository();
  final container = ProviderContainer(
    overrides: [
      cvRepositoryProvider.overrideWithValue(repository),
      aiCareerServiceProvider.overrideWithValue(fakeAi),
      coverLetterRepositoryProvider.overrideWithValue(fakeLetters),
      analyticsServiceProvider.overrideWithValue(recorder),
      interviewPrepSessionRepositoryProvider.overrideWithValue(fakeSessions),
      jobApplicationRepositoryProvider.overrideWithValue(fakeJobs),
      entitlementServiceProvider.overrideWithValue(
        EntitlementService(entitlements ?? FakeEntitlementStore()),
      ),
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
      GoRoute(
        path: RouteNames.aiImprovePath,
        builder: (context, state) => placeholder(aiImproveHarnessPlaceholder),
      ),
      GoRoute(
        path: RouteNames.jobTrackerPath,
        builder: (context, state) => const JobTrackerScreen(),
      ),
      GoRoute(
        path: RouteNames.jobApplicationFormPath,
        builder: (context, state) => JobApplicationFormScreen(
          applicationId: state.uri.queryParameters['id'],
        ),
      ),
      GoRoute(
        path: RouteNames.jobApplicationDetailsPath,
        builder: (context, state) => JobApplicationDetailsScreen(
          applicationId: state.uri.queryParameters['id'],
        ),
      ),
      GoRoute(
        path: RouteNames.interviewPrepPath,
        builder: (context, state) => const InterviewPrepScreen(),
      ),
      GoRoute(
        path: RouteNames.cvListPath,
        builder: (context, state) => placeholder(cvListPlaceholder),
      ),
      GoRoute(
        path: RouteNames.atsCheckerPath,
        builder: (context, state) => const AtsCheckerScreen(),
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
  return CoreFlowApp(
    container,
    router,
    fakeAi,
    fakeLetters,
    recorder,
    fakeJobs,
  );
}
