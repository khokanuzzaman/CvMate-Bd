import 'dart:async';

import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/core/widgets/app_chip.dart';
import 'package:careermatebd/core/widgets/score_ring.dart';
import 'package:careermatebd/features/tailoring/presentation/controllers/tailoring_controller.dart';
import 'package:careermatebd/features/tailoring/presentation/controllers/tailoring_flow_controller.dart';
import 'package:careermatebd/shared/services/entitlement/entitlement_record.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/builder_harness.dart';
import '../../../../helpers/core_flow_harness.dart';
import '../../../../helpers/design_cv.dart';
import '../../../../helpers/fake_ai_career_service.dart';
import '../../../../helpers/fake_cv_repository.dart';
import '../../../../helpers/printing_mock.dart';

const _jobPost =
    'We are hiring a Frontend Developer to build accessible, performant '
    'interfaces with React, JavaScript, TypeScript, Next.js, REST API and Git. '
    'Experience with CI/CD, design systems and Agile teams is a plus.';

const _usedFreeExport = EntitlementRecord(
  isPro: false,
  freeExportsUsed: 1,
  aiCreditsLeft: 20,
);

Future<CoreFlowApp> _open(
  WidgetTester tester, {
  FakeCvRepository? repository,
  FakeEntitlementStore? entitlements,
}) async {
  final app = await pumpCoreFlow(
    tester,
    repository: repository ?? FakeCvRepository([designCv()]),
    entitlements: entitlements,
    surface: const Size(390, 1700),
  );
  unawaited(app.router.push(RouteNames.tailoringPath));
  await tester.pumpAndSettle();
  return app;
}

Future<void> _paste(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField).first, _jobPost);
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _toMatch(WidgetTester tester) async {
  await _paste(tester);
  await _tap(tester, find.text(AppStrings.tailorAnalyze));
}

Future<void> _toResult(WidgetTester tester) async {
  await _toMatch(tester);
  await _tap(tester, find.text(AppStrings.tailorTailorMyCv));
}

VoidCallback? _onPressed(WidgetTester tester, String label) => tester
    .widget<PrimaryButton>(find.widgetWithText(PrimaryButton, label))
    .onPressed;

AppChipVariant _chipVariant(WidgetTester tester, String label) =>
    tester.widget<AppChip>(find.widgetWithText(AppChip, label)).variant;

void main() {
  group('Step 1/3 — paste', () {
    testWidgets('shows the CV card, hint and optional fields', (tester) async {
      await _open(tester);

      expect(find.text(AppStrings.tailorStepPill(1)), findsOneWidget);
      expect(find.text('Frontend Developer CV'), findsOneWidget);
      expect(
        find.text(AppStrings.tailorTemplateSubtitle('Modern')),
        findsOneWidget,
      );
      expect(find.text(AppStrings.tailorWorksForAnyRole), findsOneWidget);
      expect(
        find.textContaining(AppStrings.tailorOptional, findRichText: true),
        findsNWidgets(2),
      );
      expect(find.text(AppStrings.tailorAnalyze), findsOneWidget);
    });

    testWidgets('Analyze match needs a real job post', (tester) async {
      final app = await _open(tester);
      expect(_onPressed(tester, AppStrings.tailorAnalyze), isNull);

      await tester.enterText(find.byType(TextField).first, 'too short');
      await tester.pumpAndSettle();
      expect(_onPressed(tester, AppStrings.tailorAnalyze), isNull);

      await _paste(tester);
      expect(_onPressed(tester, AppStrings.tailorAnalyze), isNotNull);

      final state = app.container.read(tailoringControllerProvider);
      expect(state.jobPostText, _jobPost, reason: 'typing reaches the state');
    });

    testWidgets('title and company reach the controller', (tester) async {
      final app = await _open(tester);
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(1), 'React Developer');
      await tester.enterText(fields.at(2), 'Acme Inc.');

      final state = app.container.read(tailoringControllerProvider);
      expect(state.jobTitle, 'React Developer');
      expect(state.company, 'Acme Inc.');
    });

    testWidgets('the CV card opens a picker that selects another CV', (
      tester,
    ) async {
      final app = await _open(
        tester,
        repository: FakeCvRepository([
          designCv(),
          designCv(id: 'cv-2', title: 'Product Designer CV'),
        ]),
      );

      await _tap(tester, find.text('Frontend Developer CV'));
      expect(find.text(AppStrings.tailorChooseCv), findsOneWidget);
      await _tap(tester, find.text('Product Designer CV'));

      expect(app.container.read(tailoringControllerProvider).cvId, 'cv-2');
      expect(find.text('Product Designer CV'), findsOneWidget);
    });

    testWidgets('with no CV it explains what to do instead', (tester) async {
      final app = await pumpCoreFlow(tester, repository: FakeCvRepository());
      unawaited(app.router.push(RouteNames.tailoringPath));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.tailorNoCvTitle), findsOneWidget);
    });
  });

  group('Step 2/3 — match', () {
    testWidgets('shows the real coverage % and the keyword chips', (
      tester,
    ) async {
      final app = await _open(tester);
      await _toMatch(tester);

      final report = app.container
          .read(tailoringControllerProvider)
          .matchReport!;
      expect(find.text(AppStrings.tailorStepPill(2)), findsOneWidget);
      expect(
        tester.widget<ScoreRing>(find.byType(ScoreRing)).percent,
        report.matchPercentage,
      );
      expect(find.text('${report.matchPercentage}%'), findsOneWidget);

      expect(report.matchedKeywords, isNotEmpty);
      expect(report.missingKeywords, isNotEmpty);
      for (final keyword in report.matchedKeywords) {
        expect(_chipVariant(tester, keyword), AppChipVariant.matched);
      }
      for (final keyword in report.missingKeywords) {
        expect(_chipVariant(tester, keyword), AppChipVariant.missing);
      }
      expect(find.text('${report.matchedKeywords.length}'), findsWidgets);
      expect(
        find.textContaining(
          AppStrings.tailorTruthfulEmphasis,
          findRichText: true,
        ),
        findsOneWidget,
      );
      expect(find.text(AppStrings.tailorTailorMyCv), findsOneWidget);
    });

    testWidgets('Back returns to step 1 with the job post kept', (
      tester,
    ) async {
      await _open(tester);
      await _toMatch(tester);

      await _tap(tester, find.byIcon(Icons.chevron_left_rounded));

      expect(find.text(AppStrings.tailorStepPill(1)), findsOneWidget);
      expect(find.text(_jobPost), findsOneWidget);
    });
  });

  group('Step 3/3 — result', () {
    testWidgets('shows the tailored summary, skills and bullet rewrite', (
      tester,
    ) async {
      final app = await _open(tester);
      await _toResult(tester);

      expect(app.ai.tailorCalls, 1);
      expect(find.text(AppStrings.tailorStepPill(3)), findsOneWidget);
      expect(find.text(FakeAiCareerService.tailoredSummary), findsOneWidget);
      expect(find.text(AppStrings.tailorAiTailored), findsOneWidget);

      // Skills the CV does not list are filled; ones it has are outlined.
      expect(_chipVariant(tester, 'Next.js'), AppChipVariant.selected);
      expect(_chipVariant(tester, 'React'), AppChipVariant.neutral);

      // Before / after: the original is struck through, the new one keeps its
      // [add %] placeholder highlighted.
      expect(
        find.text(
          'Built responsive React interfaces used by thousands of users.',
        ),
        findsOneWidget,
      );
      expect(find.text('[add %]'), findsOneWidget);
      expect(
        find.textContaining('Rebuilt key screens', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('the badge is the real match of the tailored CV', (
      tester,
    ) async {
      final app = await _open(tester);
      await _toResult(tester);

      final percent = app.container.read(tailoredMatchPercentProvider);
      expect(percent, isNotNull);
      expect(find.text(AppStrings.tailorMatchBadge(percent!)), findsOneWidget);
    });

    testWidgets('Edit changes the tailoring state (summary, skills, bullet)', (
      tester,
    ) async {
      final app = await _open(tester);
      await _toResult(tester);
      final edits = find.text(AppStrings.tailorEdit);
      expect(edits, findsNWidgets(3));

      await _tap(tester, edits.at(0));
      await tester.enterText(
        find.byType(TextField).first,
        'A sharper summary.',
      );
      await tester.pumpAndSettle();
      var result = app.container.read(tailoringControllerProvider).result!;
      expect(result.tailoredSummary, 'A sharper summary.');

      await _tap(tester, find.text(AppStrings.tailorDone));
      await _tap(tester, find.text(AppStrings.tailorEdit).at(1));
      await tester.enterText(find.byType(TextField).first, 'React, Go');
      await tester.pumpAndSettle();
      result = app.container.read(tailoringControllerProvider).result!;
      expect(result.emphasizedSkills, ['React', 'Go']);

      await _tap(tester, find.text(AppStrings.tailorDone));
      await _tap(tester, find.text(AppStrings.tailorEdit).at(2));
      await tester.enterText(find.byType(TextField).first, 'My own bullet');
      await tester.pumpAndSettle();
      result = app.container.read(tailoringControllerProvider).result!;
      expect(result.rewrittenBullets.single.suggested, 'My own bullet');
    });

    testWidgets('Back goes 3 → 2 → 1 and then leaves the flow', (tester) async {
      await _open(tester);
      await _toResult(tester);

      await _tap(tester, find.byIcon(Icons.chevron_left_rounded));
      expect(find.text(AppStrings.tailorStepPill(2)), findsOneWidget);
      await _tap(tester, find.byIcon(Icons.chevron_left_rounded));
      expect(find.text(AppStrings.tailorStepPill(1)), findsOneWidget);
      await _tap(tester, find.byIcon(Icons.chevron_left_rounded));
      expect(find.text(homePlaceholder), findsOneWidget);
    });

    testWidgets('the saves-as-a-copy note is shown', (tester) async {
      await _open(tester);
      await _toResult(tester);
      expect(find.text(AppStrings.tailorSavesAsCopy), findsOneWidget);
    });
  });

  group('Save & export', () {
    testWidgets('saves a new copy, then shares the PDF (first export free)', (
      tester,
    ) async {
      final shared = mockSharePlugin(tester);
      final repository = FakeCvRepository([designCv()]);
      final store = FakeEntitlementStore();
      final app = await _open(
        tester,
        repository: repository,
        entitlements: store,
      );
      await _toResult(tester);

      await tester.tap(find.text(AppStrings.tailorSaveExport));
      await letRealAsyncRun(tester);

      expect(repository.saveCount, 1);
      final copy = repository.store.values.firstWhere(
        (cv) => cv.id != 'cv-frontend',
      );
      expect(copy.title, contains('Tailored'));
      expect(copy.professionalSummary, FakeAiCareerService.tailoredSummary);
      expect(
        repository.store['cv-frontend']!.professionalSummary,
        isNot(FakeAiCareerService.tailoredSummary),
        reason: 'the original CV stays untouched',
      );

      expect(shared.single.method, 'sharePdf');
      expect(store.record.freeExportsUsed, 1);
      expect(app.analytics.paramsFor('cv_exported').single, {
        'source': 'tailoring',
        'type': 'share',
      });
    });

    testWidgets('exporting the same result again does not save a second copy', (
      tester,
    ) async {
      mockSharePlugin(tester);
      final repository = FakeCvRepository([designCv()]);
      await _open(
        tester,
        repository: repository,
        entitlements: FakeEntitlementStore(),
      );
      await _toResult(tester);

      await tester.tap(find.text(AppStrings.tailorSaveExport));
      await letRealAsyncRun(tester);
      await tester.tap(find.text(AppStrings.tailorSaveExport));
      await letRealAsyncRun(tester);

      expect(repository.saveCount, 1);
    });

    testWidgets(
      'after the free export the copy is saved and the paywall opens',
      (tester) async {
        final shared = mockSharePlugin(tester);
        final repository = FakeCvRepository([designCv()]);
        final store = FakeEntitlementStore(_usedFreeExport);
        await _open(tester, repository: repository, entitlements: store);
        await _toResult(tester);

        await _tap(tester, find.text(AppStrings.tailorSaveExport));

        expect(repository.saveCount, 1);
        expect(find.text(AppStrings.paywallTitle), findsOneWidget);
        expect(shared, isEmpty, reason: 'nothing was exported');
        expect(store.saveCount, 0, reason: 'no export was recorded');
      },
    );

    testWidgets('Print (⋮ menu) goes through the same gate', (tester) async {
      final repository = FakeCvRepository([designCv()]);
      await _open(
        tester,
        repository: repository,
        entitlements: FakeEntitlementStore(_usedFreeExport),
      );
      await _toResult(tester);

      await _tap(tester, find.byTooltip(AppStrings.tailorMoreOptions));
      await _tap(tester, find.text(AppStrings.tailorPrint));

      expect(find.text(AppStrings.paywallTitle), findsOneWidget);
      expect(repository.saveCount, 0, reason: 'printing does not save a copy');
    });
  });

  group('Cover letter hand-off', () {
    testWidgets('opens aligned to the job and writes the letter', (
      tester,
    ) async {
      final app = await _open(tester);
      final fields = find.byType(TextField);
      await tester.enterText(fields.first, _jobPost);
      await tester.enterText(fields.at(1), 'Frontend Developer');
      await tester.enterText(fields.at(2), 'Acme');
      await tester.pumpAndSettle();
      await _tap(tester, find.text(AppStrings.tailorAnalyze));
      await _tap(tester, find.text(AppStrings.tailorTailorMyCv));

      await _tap(tester, find.text(AppStrings.tailorCoverLetter));

      expect(
        find.text(AppStrings.coverLetterAlignedTo('Frontend Developer · Acme')),
        findsOneWidget,
      );
      expect(app.ai.coverLetterCalls, 1);
      expect(app.ai.lastCoverLetterCompany, 'Acme');
      expect(app.ai.lastCoverLetterJobTitle, 'Frontend Developer');
      expect(
        app.ai.lastCoverLetterSummary,
        FakeAiCareerService.tailoredSummary,
        reason: 'the letter is written from the tailored summary',
      );
    });

    testWidgets('without a company it opens the form with the job filled in', (
      tester,
    ) async {
      final app = await _open(tester);
      await _toResult(tester);

      await _tap(tester, find.text(AppStrings.tailorCoverLetter));

      expect(app.ai.coverLetterCalls, 0);
      expect(find.text(AppStrings.coverLetterGenerate), findsOneWidget);
      expect(find.text(_jobPost), findsOneWidget);
    });
  });
}
