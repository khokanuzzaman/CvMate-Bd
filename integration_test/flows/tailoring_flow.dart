import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/widgets/app_chip.dart';
import 'package:careermatebd/core/widgets/score_ring.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test/helpers/clipboard_mock.dart';
import '../support/qa_harness.dart';
import '../support/qa_seed.dart';

void registerTailoringFlow() {
  qaTest(
    'tailoring: nurse job post → match → tailor → edit → cover letter → start over',
    (tester) async {
      final copied = mockClipboard(tester);
      await launchSignedIn(tester);
      await seedCv(tester, nurseCv());
      await shot(tester, 'tailoring', 'home-with-cv');

      await tapText(tester, 'Tailor');
      await waitFor(tester, find.text(AppStrings.tailorStepPill(1)));
      await shot(tester, 'tailoring', 'step1-empty');
      expect(find.text('Staff Nurse CV'), findsWidgets);

      final fields = find.byType(TextField);
      await typeInto(tester, fields.at(0), nurseJobPost);
      await typeInto(tester, fields.at(1), 'Registered Nurse');
      await typeInto(tester, fields.at(2), 'Square Hospital');
      await shot(tester, 'tailoring', 'step1-filled');

      await tapText(
        tester,
        AppStrings.tailorAnalyze,
        settle: const Duration(seconds: 2),
      );
      await waitFor(tester, find.text(AppStrings.tailorStepPill(2)));
      await shot(tester, 'tailoring', 'step2-match');
      final percent = tester.widget<ScoreRing>(find.byType(ScoreRing)).percent;
      debugPrint('QA-NOTE nurse match percent: $percent');
      final matched = find.byWidgetPredicate(
        (w) => w is AppChip && w.variant == AppChipVariant.matched,
      );
      final missing = find.byWidgetPredicate(
        (w) => w is AppChip && w.variant == AppChipVariant.missing,
      );
      // Mock AI quirk (see QA report): a nurse CV that already lists patient
      // care / vital signs / infection control can still score 0% here.
      debugPrint('QA-NOTE matched chips: ${matched.evaluate().length}');
      expect(missing, findsWidgets, reason: 'missing keyword chips');
      for (final tech in ['React', 'JavaScript', 'TypeScript', 'Next.js']) {
        expect(
          find.text(tech),
          findsNothing,
          reason: 'a nurse job post must not surface developer keyword "$tech"',
        );
      }
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
      await pumpFor(tester, const Duration(milliseconds: 400));
      await shot(tester, 'tailoring', 'step2-match-scrolled');

      await tapText(
        tester,
        AppStrings.tailorTailorMyCv,
        settle: const Duration(seconds: 2),
      );
      await waitFor(tester, find.text(AppStrings.tailorStepPill(3)));
      await shot(tester, 'tailoring', 'step3-result');
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -700));
      await pumpFor(tester, const Duration(milliseconds: 400));
      await shot(tester, 'tailoring', 'step3-result-scrolled');
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 1400));
      await pumpFor(tester, const Duration(milliseconds: 400));

      // Edit the summary.
      await tapOn(tester, find.text(AppStrings.tailorEdit).first);
      await typeInto(
        tester,
        find.byType(TextField).first,
        'Compassionate registered nurse with ICU-ready patient care skills.',
      );
      await shot(tester, 'tailoring', 'step3-editing-summary');
      await tapText(tester, AppStrings.tailorDone);
      expect(
        find.text(
          'Compassionate registered nurse with ICU-ready patient care skills.',
        ),
        findsOneWidget,
      );
      await shot(tester, 'tailoring', 'step3-edited');

      // Cover letter from the result page.
      await tapText(
        tester,
        AppStrings.tailorCoverLetter,
        settle: const Duration(seconds: 3),
      );
      await waitFor(tester, find.textContaining('Aligned to'));
      await shot(tester, 'tailoring', 'cover-letter-from-tailoring');
      expect(find.textContaining('Registered Nurse'), findsWidgets);
      expect(find.textContaining('Square Hospital'), findsWidgets);
      await tapOn(tester, find.byTooltip(AppStrings.coverLetterMoreOptions));
      await shot(tester, 'tailoring', 'cover-letter-menu');
      await tapText(tester, AppStrings.coverLetterCopyToClipboard);
      expect(
        copied,
        isNotEmpty,
        reason: 'Copy puts the letter on the clipboard',
      );
      expect(copied.last, contains('Square Hospital'));
      await shot(tester, 'tailoring', 'cover-letter-copied');
      await goBack(tester);

      // Start over asks first.
      await waitFor(tester, find.text(AppStrings.tailorStepPill(3)));
      await tapOn(tester, find.byTooltip(AppStrings.tailorMoreOptions));
      await tapText(tester, AppStrings.tailorStartOver);
      await waitFor(tester, find.text(AppStrings.tailorStartOverTitle));
      await shot(tester, 'tailoring', 'start-over-dialog');
      await tapText(tester, AppStrings.tailorCancel);
      expect(find.text(AppStrings.tailorStepPill(3)), findsOneWidget);
      await tapOn(tester, find.byTooltip(AppStrings.tailorMoreOptions));
      await tapText(tester, AppStrings.tailorStartOver);
      await tapOn(
        tester,
        find.widgetWithText(FilledButton, AppStrings.tailorStartOver),
      );
      await waitFor(tester, find.text(AppStrings.tailorStepPill(1)));
      await shot(tester, 'tailoring', 'after-start-over');
    },
  );

  qaTest(
    'tailoring: Start over on the match page (is the pasted post lost silently?)',
    (tester) async {
      await launchSignedIn(tester);
      await seedCv(tester, nurseCv());
      await tapText(tester, 'Tailor');
      await waitFor(tester, find.text(AppStrings.tailorStepPill(1)));
      await typeInto(tester, find.byType(TextField).first, nurseJobPost);
      await tapText(
        tester,
        AppStrings.tailorAnalyze,
        settle: const Duration(seconds: 2),
      );
      await waitFor(tester, find.text(AppStrings.tailorStepPill(2)));
      await tapOn(tester, find.byTooltip(AppStrings.tailorMoreOptions));
      await tapText(tester, AppStrings.tailorStartOver);
      final asked = find
          .text(AppStrings.tailorStartOverTitle)
          .evaluate()
          .isNotEmpty;
      debugPrint('QA-NOTE start over on match page asks first: $asked');
      await shot(tester, 'tailoring', 'match-page-start-over');
    },
  );
}
