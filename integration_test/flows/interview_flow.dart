import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/features/interview_prep/presentation/controllers/interview_prep_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test/helpers/clipboard_mock.dart';
import '../support/qa_harness.dart';
import '../support/qa_seed.dart';

void registerInterviewFlow() {
  qaTest('interview: setup → questions → practice → generate more → Bangla asks first', (
    tester,
  ) async {
    mockClipboard(tester);
    await launchSignedIn(tester);
    await seedCv(tester, nurseCv());

    await tapText(tester, AppStrings.actionInterview);
    await waitFor(tester, find.text(AppStrings.interviewGenerate),
        timeout: const Duration(seconds: 30));
    await shot(tester, 'interview', 'setup');

    await typeInto(tester, fieldByHint(AppStrings.interviewCompanyHint), 'Square Hospital');
    await typeInto(tester, fieldByHint(AppStrings.interviewJobPostHint), nurseJobPost);
    await shot(tester, 'interview', 'setup-filled');
    await tapText(tester, AppStrings.interviewGenerate,
        settle: const Duration(seconds: 3));
    await waitFor(tester, find.textContaining('From your CV'));
    await shot(tester, 'interview', 'questions');
    final state = appContainer(tester).read(interviewPrepControllerProvider);
    final firstCount = state.questions.length;
    debugPrint('QA-NOTE interview questions: $firstCount');
    expect(firstCount, greaterThan(0));

    // Open another card, then a category filter.
    await tapOn(tester, find.text(state.questions[1].question));
    await shot(tester, 'interview', 'second-card-open');

    // Practice: edit the answer in the sheet.
    await tapText(tester, AppStrings.interviewPractice);
    await waitFor(tester, find.text(AppStrings.interviewPracticeTitle));
    await shot(tester, 'interview', 'practice-sheet');
    await typeInto(tester, find.byType(TextField).last,
        'I follow the ward handover checklist every shift.');
    await tapText(tester, AppStrings.interviewFavorite);
    await shot(tester, 'interview', 'practice-sheet-edited-favorite');
    await goBack(tester);
    await waitFor(tester, find.text(AppStrings.interviewGenerateMore));

    // Generate more appends (does not replace).
    await tapText(tester, AppStrings.interviewGenerateMore,
        settle: const Duration(seconds: 3));
    await shot(tester, 'interview', 'generate-more');
    final afterMore =
        appContainer(tester).read(interviewPrepControllerProvider).questions;
    debugPrint('QA-NOTE after generate more: ${afterMore.length}');
    expect(afterMore.length, greaterThanOrEqualTo(firstCount),
        reason: 'Generate more must not drop questions');
    expect(
      afterMore.any((q) => q.answerText.contains('ward handover checklist')),
      isTrue,
      reason: 'Generate more must keep the edited answer',
    );

    // Bangla with an edited answer asks first.
    await tapText(tester, AppStrings.interviewShowInBangla);
    await waitFor(tester, find.text(AppStrings.interviewReplaceEditedTitle));
    await shot(tester, 'interview', 'bangla-asks-first');
    await tapText(tester, AppStrings.interviewReplaceEditedCancel);
    expect(find.text(AppStrings.interviewShowInBangla), findsOneWidget);
    await tapText(tester, AppStrings.interviewShowInBangla);
    await tapText(tester, AppStrings.interviewReplaceEditedContinue,
        settle: const Duration(seconds: 3));
    await waitFor(tester, find.text(AppStrings.interviewShowInEnglish));
    await shot(tester, 'interview', 'bangla-questions');

    // ⋮ menu: save / copy.
    await tapOn(tester, find.byTooltip(AppStrings.interviewMoreOptions));
    await shot(tester, 'interview', 'menu');
    await tapText(tester, AppStrings.interviewSaveSession);
    await shot(tester, 'interview', 'session-saved');
  });

  qaTest('interview: no CV, recent sessions, quick practice', (tester) async {
    mockClipboard(tester);
    await launchSignedIn(tester);
    await tapText(tester, AppStrings.actionInterview);
    await waitFor(tester, find.text(AppStrings.interviewNoCvTitle),
        timeout: const Duration(seconds: 30));
    await shot(tester, 'interview-empty', 'no-cv');
    await typeInto(tester, find.byType(TextField).first, 'Pharmacist');
    await tapText(tester, AppStrings.interviewGenerate,
        settle: const Duration(seconds: 3));
    await waitFor(tester, find.textContaining('From your target role'));
    await shot(tester, 'interview-empty', 'questions-no-cv');
  });
}
