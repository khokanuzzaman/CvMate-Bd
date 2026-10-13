import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/shared/services/ai/mock_ai_career_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test/helpers/clipboard_mock.dart';
import '../../test/helpers/printing_mock.dart';
import '../support/failing_ai_service.dart';
import '../support/qa_harness.dart';
import '../support/qa_seed.dart';

/// Logs whether a spinner is still on screen after the AI call had time to
/// fail, and which error copy (if any) the user got.
Future<void> _reportAiOutcome(
  WidgetTester tester,
  String flow,
  String surface,
) async {
  // Sample while the error is still on screen (snackbars last ~4s), then again
  // after a longer wait to catch a spinner that never ends.
  await pumpFor(tester, const Duration(seconds: 2));
  final snack = find
      .descendant(of: find.byType(SnackBar), matching: find.byType(Text))
      .evaluate()
      .map((e) => (e.widget as Text).data)
      .whereType<String>()
      .join(' | ');
  final simulated = find
      .textContaining('Simulated AI outage')
      .evaluate()
      .length;
  await shot(tester, flow, surface);
  await pumpFor(tester, const Duration(seconds: 6));
  final spinners = find.byType(CircularProgressIndicator).evaluate().length;
  debugPrint(
    'QA-NOTE ai-error[$surface] snackbar="$snack" '
    'errorTextWidgets=$simulated spinnersAfter8s=$spinners',
  );
}

void registerStressFlow() {
  qaTest('text scale is clamped at 1.5x app-wide', (tester) async {
    await launchApp(tester);
    await waitFor(tester, find.text(AppStrings.onboardingGetStarted));
    final context = tester.element(find.byType(Scaffold).first);
    final scaledTen = MediaQuery.textScalerOf(context).scale(10);
    final expected = 10 * (qaTextScale > 1.5 ? 1.5 : qaTextScale);
    debugPrint('QA-NOTE text scale $qaTextScale → app sees ${scaledTen / 10}');
    expect(scaledTen, closeTo(expected, 0.01));
  });

  qaTest('stress: very long values and Bangla across the app', (tester) async {
    mockClipboard(tester);
    final shares = mockSharePlugin(tester);
    await launchSignedIn(tester);
    await seedCv(tester, stressCv());
    await seedCv(tester, banglaCv());
    await shot(tester, 'stress-long', 'home');

    await tapText(tester, 'CVs');
    await waitFor(tester, find.text('Edit saved CV'));
    await shot(tester, 'stress-long', 'cv-list');
    await goBack(tester);

    // Preview of the extreme CV + exported PDF.
    await tapOn(
      tester,
      find.textContaining('Senior Registered Nurse and').first,
    );
    await waitFor(tester, find.text(AppStrings.previewExport));
    await shot(tester, 'stress-long', 'preview-extreme');
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -1500));
    await pumpFor(tester, const Duration(milliseconds: 500));
    await shot(tester, 'stress-long', 'preview-extreme-scrolled');
    await tapText(
      tester,
      AppStrings.previewExport,
      settle: const Duration(seconds: 4),
    );
    final doc = shares.isEmpty ? null : shares.first.arguments['doc'];
    if (doc is List<int>) {
      await saveHostFile('stress-long/extreme.pdf', doc);
    }
    await goBack(tester);
    await waitFor(tester, find.text(AppStrings.homeTitle));

    // Bangla CV preview + builder.
    await tapOn(tester, find.text('আমার সিভি').first);
    await waitFor(tester, find.text(AppStrings.previewExport));
    await shot(tester, 'stress-long', 'preview-bangla');
    await goBack(tester);

    // Tailor with a ~6k-character job post.
    await tapText(tester, 'Tailor');
    await waitFor(tester, find.text(AppStrings.tailorStepPill(1)));
    await shot(tester, 'stress-long', 'tailor-step1-long-cv-title');
    await typeInto(tester, find.byType(TextField).first, longJobPost());
    await typeInto(
      tester,
      find.byType(TextField).at(1),
      'Senior Clinical Nurse Coordinator, Intensive Care and High Dependency Unit',
    );
    await typeInto(
      tester,
      find.byType(TextField).at(2),
      'Bangabandhu Sheikh Mujib Medical University Teaching Hospital Limited',
    );
    await shot(tester, 'stress-long', 'tailor-step1-long-job');
    await tapText(
      tester,
      AppStrings.tailorAnalyze,
      settle: const Duration(seconds: 3),
    );
    await waitFor(tester, find.text(AppStrings.tailorStepPill(2)));
    await shot(tester, 'stress-long', 'tailor-step2-long');
    await tapText(
      tester,
      AppStrings.tailorTailorMyCv,
      settle: const Duration(seconds: 3),
    );
    await waitFor(tester, find.text(AppStrings.tailorStepPill(3)));
    await shot(tester, 'stress-long', 'tailor-step3-long');
    await goBack(tester);
    await goBack(tester);
    await goBack(tester);
    await waitFor(tester, find.text(AppStrings.homeTitle));

    // Tracker with extreme strings.
    await tapText(tester, 'Tracker');
    await waitFor(tester, find.text(AppStrings.trackerEmptyTitle));
    await tapText(tester, AppStrings.trackerAdd);
    await waitFor(tester, find.text('Save application'));
    await typeInto(
      tester,
      fieldByHint('Bdjobs, BRAC Bank, Unilever Bangladesh'),
      'Bangabandhu Sheikh Mujib Medical University Teaching Hospital Limited',
    );
    await typeInto(
      tester,
      fieldByHint('Management Trainee, Flutter Developer'),
      'Senior Clinical Nurse Coordinator, Intensive Care and High Dependency Unit',
    );
    await tapText(
      tester,
      'Save application',
      settle: const Duration(seconds: 1),
    );
    await waitFor(tester, find.textContaining('Bangabandhu'));
    await shot(tester, 'stress-long', 'tracker-long-card');
    await tapOn(tester, find.textContaining('Senior Clinical Nurse').first);
    await waitFor(tester, find.text('Application details'));
    await shot(tester, 'stress-long', 'tracker-long-details');
  });

  qaTest('stress: forced AI error on every AI surface', (tester) async {
    mockClipboard(tester);
    await launchSignedIn(
      tester,
      overrides: [
        aiCareerServiceProvider.overrideWithValue(
          const FailingAiCareerService(),
        ),
      ],
    );
    await seedCv(tester, nurseCv());

    // Tailor
    await tapText(tester, 'Tailor');
    await waitFor(tester, find.text(AppStrings.tailorStepPill(1)));
    await typeInto(tester, find.byType(TextField).first, nurseJobPost);
    await tapText(
      tester,
      AppStrings.tailorAnalyze,
      settle: const Duration(seconds: 2),
    );
    // The match step is offline (rule engine); the AI call is "Tailor my CV".
    await waitFor(tester, find.text(AppStrings.tailorStepPill(2)));
    await tapText(
      tester,
      AppStrings.tailorTailorMyCv,
      settle: const Duration(seconds: 1),
    );
    await _reportAiOutcome(tester, 'stress-ai-error', 'tailor-my-cv');
    await goBack(tester);
    await goBack(tester);
    await waitFor(tester, find.text(AppStrings.homeTitle));

    // Cover letter
    await tapText(tester, AppStrings.actionCoverLetter);
    await waitFor(tester, find.text(AppStrings.coverLetterSetupTitle));
    final fields = find.byType(TextField);
    await typeInto(tester, fields.at(0), 'Square Hospital');
    await typeInto(tester, fields.at(1), 'Registered Nurse');
    await typeInto(tester, fields.at(2), nurseJobPost);
    await tapText(
      tester,
      AppStrings.coverLetterGenerate,
      settle: const Duration(seconds: 1),
    );
    await _reportAiOutcome(tester, 'stress-ai-error', 'cover-letter');
    await goBack(tester);
    await waitFor(tester, find.text(AppStrings.homeTitle));

    // Interview
    await tapText(tester, AppStrings.actionInterview);
    await waitFor(
      tester,
      find.text(AppStrings.interviewGenerate),
      timeout: const Duration(seconds: 30),
    );
    await tapText(
      tester,
      AppStrings.interviewGenerate,
      settle: const Duration(seconds: 1),
    );
    await _reportAiOutcome(tester, 'stress-ai-error', 'interview');
    await goBack(tester);
    await waitFor(tester, find.text(AppStrings.homeTitle));

    // ATS "Improve with AI"
    await tapText(tester, AppStrings.actionAtsCheck);
    await waitFor(
      tester,
      find.text(AppStrings.atsWhatToFix.toUpperCase()),
      timeout: const Duration(seconds: 30),
    );
    await tapOn(tester, find.byTooltip(AppStrings.tailorMoreOptions));
    await tapText(tester, AppStrings.atsMenuImproveWithAi);
    await waitFor(tester, find.text(AppStrings.atsAiSheetTitle));
    await tapText(
      tester,
      AppStrings.atsAiGenerate,
      settle: const Duration(seconds: 1),
    );
    await _reportAiOutcome(tester, 'stress-ai-error', 'ats-ai-sheet');
    await goBack(tester);
    await goBack(tester);
    await waitFor(tester, find.text(AppStrings.homeTitle));

    // Improve CV screen
    await tapText(
      tester,
      AppStrings.actionImproveCv,
      settle: const Duration(seconds: 1),
    );
    await pumpFor(tester, const Duration(seconds: 1));
    await shot(tester, 'stress-ai-error', 'improve-cv-screen');
  });

  qaTest('stress: empty states with no CV and no data', (tester) async {
    await launchSignedIn(tester);
    await shot(tester, 'stress-empty', 'home-empty');
    for (final (action, step) in [
      (AppStrings.actionAtsCheck, 'ats'),
      (AppStrings.actionCoverLetter, 'cover-letter'),
      (AppStrings.actionInterview, 'interview'),
      (AppStrings.actionImproveCv, 'improve-cv'),
    ]) {
      await tapText(tester, action, settle: const Duration(seconds: 1));
      await pumpFor(tester, const Duration(seconds: 2));
      await shot(tester, 'stress-empty', step);
      await goBack(tester);
      await waitFor(tester, find.text(AppStrings.homeTitle));
    }
    await tapText(tester, 'Tailor');
    await waitFor(tester, find.text(AppStrings.tailorNoCvTitle));
    await shot(tester, 'stress-empty', 'tailor');
    await goBack(tester);
    await tapText(tester, 'CVs');
    await pumpFor(tester, const Duration(seconds: 1));
    await shot(tester, 'stress-empty', 'cv-list');
    await goBack(tester);
  });
}
