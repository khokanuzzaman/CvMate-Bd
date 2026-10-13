import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test/helpers/clipboard_mock.dart';
import '../support/qa_harness.dart';
import '../support/qa_seed.dart';

void registerCoverLetterFlow() {
  qaTest(
    'cover letter: setup → generate → tone → regenerate → edit → export → drafts',
    (tester) async {
      final shares = mockSharePlus(tester);
      mockClipboard(tester);
      await launchSignedIn(tester);
      await seedCv(tester, nurseCv());

      await tapText(tester, AppStrings.actionCoverLetter);
      await waitFor(tester, find.text(AppStrings.coverLetterSetupTitle));
      await shot(tester, 'cover-letter', 'setup-empty');

      // Generate with nothing filled in → inline validation.
      await tapText(tester, AppStrings.coverLetterGenerate);
      expect(find.text('Target company name is required.'), findsWidgets);
      await shot(tester, 'cover-letter', 'setup-validation');

      final fields = find.byType(TextField);
      await typeInto(tester, fields.at(0), 'Square Hospital');
      await typeInto(tester, fields.at(1), 'Registered Nurse');
      await typeInto(tester, fields.at(2), nurseJobPost);
      await shot(tester, 'cover-letter', 'setup-filled');
      await tapText(
        tester,
        AppStrings.coverLetterGenerate,
        settle: const Duration(seconds: 3),
      );
      await waitFor(tester, find.textContaining('Aligned to'));
      await shot(tester, 'cover-letter', 'letter-professional');

      await tapText(tester, AppStrings.coverLetterToneFriendly);
      await tapText(
        tester,
        AppStrings.coverLetterRegenerate,
        settle: const Duration(seconds: 3),
      );
      await shot(tester, 'cover-letter', 'letter-friendly-regenerated');

      await tapText(tester, AppStrings.coverLetterEdit);
      await typeInto(
        tester,
        find.byType(TextField).last,
        'My own edited letter.',
      );
      await shot(tester, 'cover-letter', 'letter-editing');
      await tapText(tester, AppStrings.coverLetterDoneEditing);
      expect(find.text('My own edited letter.'), findsOneWidget);

      await tapText(
        tester,
        AppStrings.coverLetterExport,
        settle: const Duration(seconds: 2),
      );
      expect(shares, isNotEmpty, reason: 'Export opens the share sheet');
      await shot(tester, 'cover-letter', 'after-export');

      // Back out and reopen it from Recent drafts.
      await goBack(tester);
      await waitFor(tester, find.text(AppStrings.homeTitle));
      await tapText(tester, AppStrings.actionCoverLetter);
      // Reopening shows the last letter; the form + Recent drafts are one tap away.
      await waitFor(tester, find.textContaining('Aligned to'));
      await shot(tester, 'cover-letter', 'reopened-shows-last-letter');
      await tapOn(tester, find.textContaining('Aligned to'));
      await waitFor(
        tester,
        find.text(AppStrings.coverLetterRecentDrafts.toUpperCase()),
      );
      await shot(tester, 'cover-letter', 'recent-drafts');
      await tapText(tester, AppStrings.coverLetterOpenDraft);
      await waitFor(tester, find.text('My own edited letter.'));
      await shot(tester, 'cover-letter', 'draft-reopened');
    },
  );

  qaTest('cover letter: delete a draft asks first', (tester) async {
    mockSharePlus(tester);
    await launchSignedIn(tester);
    await seedCv(tester, nurseCv());
    await tapText(tester, AppStrings.actionCoverLetter);
    await waitFor(tester, find.text(AppStrings.coverLetterSetupTitle));
    final fields = find.byType(TextField);
    await typeInto(tester, fields.at(0), 'Evercare Hospital');
    await typeInto(tester, fields.at(1), 'Staff Nurse');
    await typeInto(tester, fields.at(2), nurseJobPost);
    await tapText(
      tester,
      AppStrings.coverLetterGenerate,
      settle: const Duration(seconds: 3),
    );
    await waitFor(tester, find.textContaining('Aligned to'));
    await tapText(
      tester,
      AppStrings.coverLetterExport,
      settle: const Duration(seconds: 2),
    );
    await goBack(tester);
    await tapText(tester, AppStrings.actionCoverLetter);
    await waitFor(tester, find.textContaining('Aligned to'));
    await tapOn(tester, find.textContaining('Aligned to'));
    await waitFor(tester, find.byTooltip(AppStrings.coverLetterDeleteDraft));
    await tapOn(tester, find.byTooltip(AppStrings.coverLetterDeleteDraft));
    await waitFor(tester, find.text(AppStrings.coverLetterDeleteTitle));
    await shot(tester, 'cover-letter', 'delete-dialog');
    await tapText(tester, AppStrings.coverLetterCancel);
    expect(find.byTooltip(AppStrings.coverLetterDeleteDraft), findsOneWidget);
    await tapOn(tester, find.byTooltip(AppStrings.coverLetterDeleteDraft));
    await tapOn(
      tester,
      find.widgetWithText(FilledButton, AppStrings.coverLetterDelete),
    );
    await waitGone(tester, find.byTooltip(AppStrings.coverLetterDeleteDraft));
    await shot(tester, 'cover-letter', 'after-delete');
  });
}
