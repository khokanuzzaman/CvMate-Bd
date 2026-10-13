import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/features/ats_checker/presentation/controllers/ats_checker_controller.dart';
import 'package:careermatebd/features/ats_checker/presentation/utils/ats_fix_target.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test/helpers/clipboard_mock.dart';
import '../support/qa_harness.dart';
import '../support/qa_seed.dart';

void registerAtsFlow() {
  qaTest('ats: report → every Fix opens the right builder step', (
    tester,
  ) async {
    await launchSignedIn(tester);
    await seedCv(tester, nurseCv());
    await seedCv(tester, weakCv());

    await tapText(tester, AppStrings.actionAtsCheck);
    await waitFor(
      tester,
      find.text(AppStrings.atsWhatToFix.toUpperCase()),
      timeout: const Duration(seconds: 30),
    );
    await shot(tester, 'ats', 'report-first-cv');

    // The newest CV (the thin one) is checked first. Switch to the nurse CV
    // through the picker and back again.
    await tapOn(tester, find.text('Fresher Draft').first);
    await shot(tester, 'ats', 'cv-picker');
    await tapText(tester, 'Staff Nurse CV', settle: const Duration(seconds: 2));
    await waitFor(tester, find.text('Staff Nurse CV'));
    await shot(tester, 'ats', 'report-nurse-cv');
    await tapOn(tester, find.text('Staff Nurse CV').first);
    await tapText(tester, 'Fresher Draft', settle: const Duration(seconds: 2));
    await waitFor(tester, find.text('Fresher Draft'));
    await shot(tester, 'ats', 'report-weak-cv');
    final state = appContainer(tester).read(atsCheckerControllerProvider);
    debugPrint(
      'QA-NOTE ats selected CV: ${state.selectedCvId} '
      'issues: ${state.report?.issues.length}',
    );
    final issues = state.report!.issues;
    expect(issues, isNotEmpty);

    for (var i = 0; i < issues.length; i++) {
      final issue = issues[i];
      final expectedPage = CvBuilderFlow.pageFor(atsFixStep(issue.category));
      final fix = find.text(AppStrings.atsFix).at(i);
      await tapOn(tester, fix, settle: const Duration(seconds: 1));
      final expectedLabel = AppStrings.builderStepLabel(
        CvBuilderFlow.pages.indexOf(expectedPage) + 1,
        CvBuilderFlow.pages.length,
        expectedPage.sectionTitle,
      );
      await waitFor(
        tester,
        find.text(expectedLabel),
        reason:
            'Fix for "${issue.problem}" (${issue.category.name}) '
            'should open "$expectedLabel"',
      );
      if (i == 0) {
        await shot(tester, 'ats', 'fix-opened-builder');
      }
      await goBack(tester);
      await waitFor(tester, find.text(AppStrings.atsWhatToFix.toUpperCase()));
    }
    await shot(tester, 'ats', 'back-from-fixes');
  });

  qaTest('ats: ⋮ actions, job-post check, AI sheet', (tester) async {
    mockClipboard(tester);
    await launchSignedIn(tester);
    await seedCv(tester, nurseCv());

    await tapText(tester, AppStrings.actionAtsCheck);
    await waitFor(
      tester,
      find.text(AppStrings.atsWhatToFix.toUpperCase()),
      timeout: const Duration(seconds: 30),
    );
    await shot(tester, 'ats', 'nurse-report');

    // ⋮ before any job post.
    await tapOn(tester, find.byTooltip(AppStrings.tailorMoreOptions));
    await shot(tester, 'ats', 'menu-open');
    await tapText(tester, AppStrings.atsMenuApplySkills);
    expect(find.text(AppStrings.atsNeedsJobPost), findsOneWidget);
    await shot(tester, 'ats', 'apply-skills-needs-job-post');

    // Check against a job post → Tailor with this CV.
    await pumpFor(tester, const Duration(seconds: 4));
    await tapText(tester, AppStrings.atsCheckAgainstJob);
    await waitFor(tester, find.text(AppStrings.tailorStepPill(1)));
    await shot(tester, 'ats', 'check-against-job-in-tailor');
    await typeInto(tester, find.byType(TextField).first, nurseJobPost);
    await goBack(tester);
    await waitFor(tester, find.text(AppStrings.atsWhatToFix.toUpperCase()));

    await tapOn(tester, find.byTooltip(AppStrings.tailorMoreOptions));
    await tapText(tester, AppStrings.atsMenuCopySuggestions);
    await shot(tester, 'ats', 'copy-suggestions');
    await pumpFor(tester, const Duration(seconds: 4));
    await tapOn(tester, find.byTooltip(AppStrings.tailorMoreOptions));
    await tapText(tester, AppStrings.atsMenuApplySkills);
    await shot(tester, 'ats', 'apply-detected-skills');
    await pumpFor(tester, const Duration(seconds: 4));

    await tapOn(tester, find.byTooltip(AppStrings.tailorMoreOptions));
    await tapText(tester, AppStrings.atsMenuImproveWithAi);
    await waitFor(tester, find.text(AppStrings.atsAiSheetTitle));
    await shot(tester, 'ats', 'ai-sheet');
    await tapText(
      tester,
      AppStrings.atsAiGenerate,
      settle: const Duration(seconds: 3),
    );
    await waitFor(tester, find.text(AppStrings.atsAiSuggestionLabel));
    await shot(tester, 'ats', 'ai-sheet-suggestion');
    await tapText(
      tester,
      AppStrings.atsAiApply,
      settle: const Duration(seconds: 1),
    );
    await shot(tester, 'ats', 'ai-applied');
  });
}
