import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/widgets/custom_error_view.dart';
import 'package:careermatebd/core/widgets/score_ring.dart';
import 'package:careermatebd/features/ats_checker/domain/usecases/ats_rule_engine.dart';
import 'package:careermatebd/features/ats_checker/presentation/controllers/ats_ai_target.dart';
import 'package:careermatebd/features/ats_checker/presentation/controllers/ats_checker_controller.dart';
import 'package:careermatebd/features/ats_checker/presentation/screens/ats_checker_screen.dart';
import 'package:careermatebd/features/ats_checker/presentation/utils/ats_fix_target.dart';
import 'package:careermatebd/features/ats_checker/presentation/widgets/ats_severity_chip.dart';
import 'package:careermatebd/features/cv_builder/data/repositories/cv_repository_impl.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:careermatebd/features/tailoring/presentation/controllers/tailoring_controller.dart';
import 'package:careermatebd/features/tailoring/presentation/screens/tailoring_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/clipboard_mock.dart';
import '../../../../helpers/design_cv.dart';
import '../../../../helpers/fake_cv_repository.dart';
import '../../../../helpers/routed_screen_harness.dart';

Future<RoutedScreen> _open(
  WidgetTester tester, {
  FakeCvRepository? repository,
  Map<String, Widget> routes = const {},
}) {
  return pumpRoutedScreen(
    tester,
    path: RouteNames.atsCheckerPath,
    screen: const AtsCheckerScreen(),
    routes: routes,
    overrides: [
      cvRepositoryProvider.overrideWithValue(
        repository ?? FakeCvRepository([designCv()]),
      ),
    ],
  );
}

void main() {
  final report = const AtsRuleEngine().analyzeCv(designCv());

  testWidgets('shows the engine score, its sections and its issues', (
    tester,
  ) async {
    await _open(tester);

    final ring = tester.widget<ScoreRing>(find.byType(ScoreRing));
    expect(ring.percent, report.score);
    expect(ring.showPercentSign, isFalse);
    expect(find.text('${report.score}'), findsOneWidget);
    expect(find.textContaining('with ${report.issues.length} fix'), findsOne);

    // One tile per real section score — Job Match is not one of them.
    expect(find.text('Contact'), findsOneWidget);
    expect(find.text('Formatting'), findsOneWidget);
    expect(find.text('Job Match'), findsNothing);

    for (final issue in report.issues) {
      expect(find.text(issue.problem), findsOneWidget);
      expect(find.text(issue.suggestion), findsOneWidget);
    }
    expect(find.byType(AtsSeverityChip), findsNWidgets(report.issues.length));
    expect(find.text(AppStrings.atsFix), findsNWidgets(report.issues.length));
    expect(find.text(AppStrings.atsCheckedNow), findsOneWidget);
  });

  testWidgets('an issue example is labelled once, not "Example: Example:"', (
    tester,
  ) async {
    await _open(tester);

    final withExample = report.issues
        .where((issue) => (issue.exampleImprovement ?? '').isNotEmpty)
        .toList();
    expect(withExample, isNotEmpty);
    expect(find.textContaining('Example: Example'), findsNothing);
    for (final issue in withExample) {
      final sample = issue.exampleImprovement!.replaceFirst(
        RegExp(r'^example:\s*', caseSensitive: false),
        '',
      );
      expect(find.text(AppStrings.atsExample(sample)), findsWidgets);
    }
  });

  testWidgets('lists the most severe issue first', (tester) async {
    await _open(tester);

    final first = tester.getTopLeft(find.text(report.issues.first.problem));
    final last = tester.getTopLeft(find.text(report.issues.last.problem));
    expect(first.dy, lessThan(last.dy));
  });

  testWidgets('Fix opens the builder on the issue\'s step', (tester) async {
    final app = await _open(tester);

    await tester.tap(find.text(AppStrings.atsFix).first);
    await tester.pumpAndSettle();

    expect(find.text(placeholderFor(RouteNames.cvBuilderPath)), findsOneWidget);
    final builder = app.container.read(cvBuilderControllerProvider);
    expect(builder.draft.id, 'cv-frontend');
    expect(builder.currentStep, atsFixStep(report.issues.first.category));
  });

  testWidgets('"Check against a job post" continues in Tailor with this CV', (
    tester,
  ) async {
    final repository = FakeCvRepository([
      designCv(),
      designCv(id: 'cv-other', title: 'Other CV'),
    ]);
    final app = await _open(tester, repository: repository);
    app.container
        .read(atsCheckerControllerProvider.notifier)
        .selectCv('cv-other');
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.atsCheckAgainstJob));
    await tester.pumpAndSettle();

    expect(find.text(placeholderFor(RouteNames.tailoringPath)), findsOneWidget);
    expect(app.container.read(tailoringControllerProvider).cvId, 'cv-other');
  });

  testWidgets('the real Tailor screen opens with that CV already chosen', (
    tester,
  ) async {
    final app = await _open(
      tester,
      repository: FakeCvRepository([
        designCv(),
        designCv(id: 'cv-other', title: 'Other CV'),
      ]),
      routes: {RouteNames.tailoringPath: const TailoringScreen()},
    );
    app.container
        .read(atsCheckerControllerProvider.notifier)
        .selectCv('cv-other');
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.atsCheckAgainstJob));
    await tester.pumpAndSettle();

    // Step 1 of Tailor, showing the CV picked on the ATS screen.
    expect(find.text(AppStrings.tailorTitle), findsOneWidget);
    expect(find.text('Other CV'), findsOneWidget);
    expect(find.text('Frontend Developer CV'), findsNothing);
  });

  testWidgets('choosing another CV re-checks that CV', (tester) async {
    final app = await _open(
      tester,
      repository: FakeCvRepository([
        designCv(),
        designCv(id: 'cv-other', title: 'Other CV'),
      ]),
    );
    expect(
      app.container.read(atsCheckerControllerProvider).selectedCvId,
      'cv-frontend',
    );

    await tester.tap(find.text('Frontend Developer CV'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Other CV'));
    await tester.pumpAndSettle();

    expect(
      app.container.read(atsCheckerControllerProvider).selectedCvId,
      'cv-other',
    );
    expect(find.text('Other CV'), findsOneWidget);
  });

  testWidgets('with no CV it offers to create one', (tester) async {
    await _open(tester, repository: FakeCvRepository());

    expect(find.text(AppStrings.atsNoCvTitle), findsOneWidget);
    expect(find.text(AppStrings.atsCreateCv), findsOneWidget);
    expect(find.text(AppStrings.atsCheckAgainstJob), findsNothing);
    expect(find.byType(ScoreRing), findsNothing);
  });

  testWidgets('a load failure shows an error with a retry', (tester) async {
    await _open(tester, repository: _ThrowingCvRepository());

    expect(find.byType(CustomErrorView), findsOneWidget);
    expect(find.text(AppStrings.atsLoadErrorTitle), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  group('job-match actions (⋮ menu)', () {
    // Names Firebase, which the design CV's project uses but its skills list
    // does not — so it is a skill the CV can honestly gain.
    const jobPost =
        'We need a frontend developer with React, Firebase and Git to build '
        'accessible interfaces and ship features every sprint.';

    Future<void> choose(WidgetTester tester, String label) async {
      await tester.tap(find.byTooltip(AppStrings.tailorMoreOptions));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pump();
      await tester.pumpAndSettle();
    }

    test('the job post used below really yields a detectable skill', () {
      final match = const AtsRuleEngine().analyzeJobPost(
        profile: designCv(),
        jobPostText: jobPost,
      );
      expect(match.suggestedSkillsToAdd, contains('Firebase'));
    });

    test('the job post used for "nothing to add" yields no skill', () {
      final match = const AtsRuleEngine().analyzeJobPost(
        profile: designCv(),
        jobPostText:
            'Seeking someone skilled in React, JavaScript, Git and TypeScript.',
      );
      expect(match.suggestedSkillsToAdd, isEmpty);
    });

    testWidgets('both actions sit beside the summary generator', (
      tester,
    ) async {
      await _open(tester);

      await tester.tap(find.byTooltip(AppStrings.tailorMoreOptions));
      await tester.pumpAndSettle();

      for (final label in [
        AppStrings.atsMenuImproveWithAi,
        AppStrings.atsMenuApplySkills,
        AppStrings.atsMenuCopySuggestions,
        AppStrings.atsMenuOpenAiImprove,
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
    });

    testWidgets('without a job post they say what to do first', (tester) async {
      final copied = mockClipboard(tester);
      await _open(tester);

      await choose(tester, AppStrings.atsMenuCopySuggestions);

      expect(find.text(AppStrings.atsNeedsJobPost), findsOneWidget);
      expect(copied, isEmpty);
    });

    testWidgets('Copy suggestions uses the job post pasted in Tailor', (
      tester,
    ) async {
      final copied = mockClipboard(tester);
      final app = await _open(tester);
      app.container
          .read(tailoringControllerProvider.notifier)
          .updateJobPost(jobPostText: jobPost);

      await choose(tester, AppStrings.atsMenuCopySuggestions);

      expect(copied.single, contains('Job Match Score:'));
      expect(copied.single, contains('Firebase'));
      expect(find.text('Job match suggestions copied.'), findsOneWidget);
    });

    testWidgets('Apply detected skills adds them to the CV', (tester) async {
      final repository = FakeCvRepository([designCv()]);
      final app = await _open(tester, repository: repository);
      app.container
          .read(tailoringControllerProvider.notifier)
          .updateJobPost(jobPostText: jobPost);

      await choose(tester, AppStrings.atsMenuApplySkills);

      final skills = repository.saved('cv-frontend')!.skills.map((s) => s.name);
      expect(skills, contains('Firebase'));
      expect(find.text('Detected skills added to CV.'), findsOneWidget);
    });

    testWidgets('nothing to add is reported, not silently ignored', (
      tester,
    ) async {
      final repository = FakeCvRepository([designCv()]);
      final app = await _open(tester, repository: repository);
      app.container
          .read(tailoringControllerProvider.notifier)
          .updateJobPost(
            jobPostText:
                'Seeking someone skilled in React, JavaScript, Git and '
                'TypeScript.',
          );

      await choose(tester, AppStrings.atsMenuApplySkills);

      expect(find.text('No detected skills are ready to add.'), findsOneWidget);
      expect(repository.saveCount, 0);
    });
  });

  group('Improve with AI (⋮ menu)', () {
    Future<RoutedScreen> openSheet(
      WidgetTester tester,
      FakeCvRepository repository,
    ) async {
      final app = await _open(tester, repository: repository);
      await tester.tap(find.byTooltip(AppStrings.tailorMoreOptions));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.atsMenuImproveWithAi));
      await tester.pumpAndSettle();
      return app;
    }

    testWidgets('generates a suggestion and applies it to the CV', (
      tester,
    ) async {
      final repository = FakeCvRepository([designCv()]);
      final app = await openSheet(tester, repository);

      expect(find.text(AppStrings.atsAiSheetTitle), findsOneWidget);
      await tester.tap(find.text(AppStrings.atsAiGenerate));
      await tester.pumpAndSettle();

      final suggestion = app.container
          .read(atsCheckerControllerProvider)
          .aiSuggestionText;
      expect(suggestion, isNotEmpty);
      expect(find.text(AppStrings.atsAiSuggestionLabel), findsOneWidget);

      await tester.tap(find.text(AppStrings.atsAiApply));
      await tester.pumpAndSettle();

      final CvProfile saved = repository.saved('cv-frontend')!;
      expect(saved.professionalSummary, suggestion);
    });

    testWidgets('the target chips switch between summary and objective', (
      tester,
    ) async {
      final app = await openSheet(tester, FakeCvRepository([designCv()]));

      await tester.tap(find.text('Career Objective'));
      await tester.pumpAndSettle();

      expect(
        app.container.read(atsCheckerControllerProvider).aiTarget.label,
        'Career Objective',
      );
    });
  });
}

class _ThrowingCvRepository extends FakeCvRepository {
  @override
  Future<List<CvProfile>> getAllCvs() async => throw Exception('boom');
}
