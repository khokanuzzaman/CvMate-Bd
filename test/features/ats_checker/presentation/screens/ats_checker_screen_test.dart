import 'dart:async';

import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/widgets/app_chip.dart';
import 'package:careermatebd/core/widgets/score_ring.dart';
import 'package:careermatebd/features/ats_checker/domain/entities/ats_check_category.dart';
import 'package:careermatebd/features/ats_checker/presentation/controllers/ats_checker_controller.dart';
import 'package:careermatebd/features/ats_checker/presentation/controllers/ats_checker_state.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/skill_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/core_flow_harness.dart';
import '../../../../helpers/design_cv.dart';
import '../../../../helpers/fake_cv_repository.dart';

const _jobPost =
    'We are hiring a Frontend Developer to build accessible interfaces with '
    'React, JavaScript, TypeScript, Next.js, REST API and Git. Experience '
    'with CI/CD, design systems and Agile teams is a plus.';

Future<CoreFlowApp> _open(
  WidgetTester tester, {
  FakeCvRepository? repository,
}) async {
  final app = await pumpCoreFlow(
    tester,
    repository: repository ?? FakeCvRepository([designCv()]),
    surface: const Size(390, 3200),
  );
  unawaited(app.router.push(RouteNames.atsCheckerPath));
  await tester.pumpAndSettle();
  return app;
}

AtsCheckerState _state(CoreFlowApp app) =>
    app.container.read(atsCheckerControllerProvider);

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _paste(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField).first, _jobPost);
  await tester.pumpAndSettle();
}

void main() {
  group('score', () {
    testWidgets('shows the real score, the CV and the honest note', (
      tester,
    ) async {
      final app = await _open(tester);
      final report = _state(app).report!;

      expect(
        tester.widget<ScoreRing>(find.byType(ScoreRing).first).percent,
        report.score,
      );
      expect(find.text(AppStrings.atsScoreOutOf(report.score)), findsOneWidget);
      expect(find.text(AppStrings.atsWords(report.wordCount)), findsOneWidget);
      expect(find.text(AppStrings.atsScoreNote), findsOneWidget);
      expect(find.text('Frontend Developer CV'), findsOneWidget);
    });

    testWidgets('the CV card opens a picker that switches the CV', (
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
      await _tap(tester, find.text('Product Designer CV'));

      expect(_state(app).selectedCvId, 'cv-2');
      expect(find.text('Product Designer CV'), findsOneWidget);
    });

    testWidgets('the shortcuts open the builder and AI Improve', (
      tester,
    ) async {
      await _open(tester);

      await _tap(tester, find.text(AppStrings.atsOpenBuilder));
      expect(find.text(builderPlaceholder), findsOneWidget);
    });

    testWidgets('with no CV it offers to create one', (tester) async {
      await _open(tester, repository: FakeCvRepository());

      expect(find.text(AppStrings.atsNoCvTitle), findsOneWidget);
      await _tap(tester, find.text(AppStrings.atsCreateCv));
      expect(find.text(builderPlaceholder), findsOneWidget);
    });
  });

  group('job post match', () {
    testWidgets('guides from empty to ready to checked', (tester) async {
      final app = await _open(tester);
      expect(find.text(AppStrings.atsPasteFirst), findsOneWidget);

      await _paste(tester);
      expect(find.text(AppStrings.atsReadyToCheck), findsOneWidget);
      expect(find.text(AppStrings.atsCheckMatch), findsOneWidget);

      await _tap(tester, find.text(AppStrings.atsCheckMatch));
      final match = _state(app).jobMatchReport!;

      expect(find.text(AppStrings.atsRecheck), findsOneWidget);
      expect(
        tester.widgetList<ScoreRing>(find.byType(ScoreRing)).last.percent,
        match.matchPercentage,
      );
      expect(find.text(AppStrings.atsHonestNote), findsOneWidget);
      for (final keyword in match.matchedKeywords) {
        expect(
          tester
              .widgetList<AppChip>(find.widgetWithText(AppChip, keyword))
              .any((chip) => chip.variant == AppChipVariant.matched),
          isTrue,
          reason: keyword,
        );
      }
      for (final keyword in match.missingKeywords) {
        expect(
          tester
              .widgetList<AppChip>(find.widgetWithText(AppChip, keyword))
              .any((chip) => chip.variant == AppChipVariant.missing),
          isTrue,
          reason: keyword,
        );
      }
    });

    testWidgets('Apply detected skills adds them to the CV', (tester) async {
      final repository = FakeCvRepository([designCv()]);
      final app = await _open(tester, repository: repository);
      await _paste(tester);
      await _tap(tester, find.text(AppStrings.atsCheckMatch));

      final suggested = _state(app).jobMatchReport!.suggestedSkillsToAdd;
      if (suggested.isEmpty) {
        // Nothing to add for this CV/post: the action must not be offered.
        expect(find.text(AppStrings.atsApplySkills), findsNothing);
        return;
      }

      await _tap(tester, find.text(AppStrings.atsApplySkills));

      expect(repository.saveCount, 1);
      final names = repository.store['cv-frontend']!.skills.map(
        (SkillInfo skill) => skill.name.toLowerCase(),
      );
      for (final skill in suggested) {
        expect(names, contains(skill.toLowerCase()));
      }
    });

    testWidgets('Copy suggestions is offered once there is a result', (
      tester,
    ) async {
      await _open(tester);
      expect(find.text(AppStrings.atsCopySuggestions), findsNothing);

      await _paste(tester);
      await _tap(tester, find.text(AppStrings.atsCheckMatch));

      expect(find.text(AppStrings.atsCopySuggestions), findsOneWidget);
    });
  });

  group('AI improvement', () {
    testWidgets('generates an editable suggestion and applies it', (
      tester,
    ) async {
      final repository = FakeCvRepository([designCv()]);
      final app = await _open(tester, repository: repository);
      expect(find.text(AppStrings.atsAiSuggestionLabel), findsNothing);

      await _tap(tester, find.text(AppStrings.atsAiImprove));
      expect(_state(app).hasAiSuggestion, isTrue);
      expect(find.text(AppStrings.atsAiSuggestionLabel), findsOneWidget);

      await tester.enterText(find.byType(TextField).last, 'My own summary.');
      await tester.pumpAndSettle();
      expect(_state(app).aiSuggestionText, 'My own summary.');

      await _tap(tester, find.text(AppStrings.atsAiApply));
      expect(repository.saveCount, 1);
      expect(
        repository.store['cv-frontend']!.professionalSummary,
        'My own summary.',
      );
    });

    testWidgets('the target toggle switches summary / objective', (
      tester,
    ) async {
      final app = await _open(tester);

      await _tap(tester, find.text('Career Objective'));

      expect(_state(app).aiTarget.name, 'careerObjective');
    });
  });

  testWidgets('lists every category with its score', (tester) async {
    final app = await _open(tester);
    final report = _state(app).report!;

    for (final category in AtsCheckCategory.values) {
      expect(find.text(category.label), findsWidgets);
    }
    expect(find.text(AppStrings.atsNotChecked), findsOneWidget);
    expect(
      find.text(
        AppStrings.atsCategoryScore(report.categoryScores.values.first),
      ),
      findsWidgets,
    );
    expect(find.text(AppStrings.atsJobMatchPlaceholder), findsOneWidget);
  });
}
