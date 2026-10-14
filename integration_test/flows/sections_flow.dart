import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/features/cv_builder/data/repositories/cv_repository_impl.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test/helpers/printing_mock.dart';
import '../support/qa_harness.dart';
import '../support/qa_seed.dart';

/// The widget of type [T] (matched by [finder]) on the same row as the section
/// titled [title]. The list is lazy, so scroll the row into reach first and
/// pin the exact widget (an index into `find.byType` shifts while scrolling).
Future<Finder> _onRowOf(
  WidgetTester tester,
  String title,
  Finder finder,
) async {
  await scrollIntoReach(tester, find.text(title));
  final y = tester.getCenter(find.text(title).first).dy;
  Element? best;
  var bestDistance = double.infinity;
  for (final element in finder.evaluate()) {
    final box = element.renderObject! as RenderBox;
    final dy = (box.localToGlobal(box.size.center(Offset.zero)).dy - y).abs();
    if (dy < bestDistance) {
      best = element;
      bestDistance = dy;
    }
  }
  final pinned = best!;
  return find.byElementPredicate((element) => element == pinned);
}

Future<Finder> _switchFor(WidgetTester tester, String title) =>
    _onRowOf(tester, title, find.byType(Switch));

Future<Finder> _handleFor(WidgetTester tester, String title) =>
    _onRowOf(tester, title, find.byIcon(Icons.drag_indicator_rounded));

Future<void> _dragHandle(
  WidgetTester tester,
  Finder handle, {
  required double dy,
}) async {
  final gesture = await tester.startGesture(tester.getCenter(handle));
  await pumpFor(tester, const Duration(milliseconds: 150));
  for (var i = 0; i < 10; i++) {
    await gesture.moveBy(Offset(0, dy / 10));
    await pumpFor(tester, const Duration(milliseconds: 40));
  }
  await gesture.up();
  await pumpFor(tester, const Duration(milliseconds: 600));
}

double _y(WidgetTester tester, String text) =>
    tester.getTopLeft(find.text(text).first).dy;

void registerSectionsFlow() {
  qaTest(
    'sections: reorder, hide, rename, add a custom section → preview → export '
    '→ restart keeps it',
    (tester) async {
      final shares = mockSharePlugin(tester);
      await launchSignedIn(tester);
      await seedCv(tester, nurseCv());

      await tapText(tester, 'CVs');
      await waitFor(tester, find.text('Edit saved CV'));
      await tapText(tester, 'Edit saved CV');
      await waitFor(tester, find.text('Step 1 of 7 · Personal'));

      // Builder top bar → Sections.
      await tapOn(tester, find.byTooltip(AppStrings.sectionsTooltip));
      await waitFor(tester, find.text(AppStrings.sectionsIntro));
      await shot(tester, 'sections', 'sections-default');

      // Reorder: Education above Summary.
      expect(
        _y(tester, AppStrings.previewSummary),
        lessThan(_y(tester, AppStrings.previewEducation)),
      );
      final rowDistance =
          _y(tester, AppStrings.previewEducation) -
          _y(tester, AppStrings.previewSummary);
      await _dragHandle(
        tester,
        await _handleFor(tester, AppStrings.previewEducation),
        dy: -(rowDistance + 20),
      );
      expect(
        _y(tester, AppStrings.previewEducation),
        lessThan(_y(tester, AppStrings.previewSummary)),
        reason: 'dragging the handle must move Education above Summary',
      );
      await shot(tester, 'sections', 'sections-reordered');

      // Hide Skills.
      await tapOn(tester, await _switchFor(tester, AppStrings.previewSkills));
      expect(find.text(AppStrings.sectionsHiddenTag), findsOneWidget);
      await shot(tester, 'sections', 'sections-skills-hidden');

      // Rename Experience.
      await tapText(tester, AppStrings.previewExperience);
      await waitFor(tester, find.text(AppStrings.sectionsRenameTitle));
      await typeInto(tester, find.byType(TextField).last, 'Work history');
      await shot(tester, 'sections', 'sections-rename-sheet');
      await tapOn(
        tester,
        find.widgetWithText(PrimaryButton, AppStrings.sectionsSave),
      );
      await waitFor(tester, find.text('Work history'));

      // Add a custom section (bullet list) → its builder page.
      await tapText(tester, AppStrings.sectionsAddCustom);
      await waitFor(tester, find.text(AppStrings.sectionsAddCustomTitle));
      await typeInto(tester, find.byType(TextField).last, 'Awards');
      await tapText(tester, AppStrings.sectionsLayoutBullets);
      await shot(tester, 'sections', 'sections-add-custom-sheet');
      await tapOn(
        tester,
        find.widgetWithText(PrimaryButton, AppStrings.sectionsCreate),
        settle: const Duration(seconds: 1),
      );
      await waitFor(tester, find.text(AppStrings.customSectionAddFirstRow));
      expect(find.text('Step 8 of 8 · Awards'), findsNothing);
      expect(find.textContaining('· Awards'), findsOneWidget);
      await tapText(tester, AppStrings.customSectionAddFirstRow);
      await typeInto(
        tester,
        fieldByHint(AppStrings.customSectionBulletHint),
        'Best Nurse Award 2024',
      );
      await shotTop(tester, 'sections', 'custom-section-page');

      // Preview shows the new order, the new title, the custom section; the
      // hidden one is gone.
      await tapOn(tester, find.byIcon(Icons.visibility_outlined));
      await waitFor(tester, find.text(AppStrings.previewExport));
      await shot(tester, 'sections', 'preview');
      expect(find.text('WORK HISTORY'), findsOneWidget);
      expect(find.text('EXPERIENCE'), findsNothing);
      expect(find.text('SKILLS'), findsNothing);
      expect(find.text('AWARDS'), findsOneWidget);
      expect(find.textContaining('Best Nurse Award 2024'), findsWidgets);
      final order = [
        _y(tester, 'EDUCATION'),
        _y(tester, 'SUMMARY'),
        _y(tester, 'WORK HISTORY'),
        _y(tester, 'AWARDS'),
      ];
      expect(order, [...order]..sort(), reason: 'preview follows the layout');

      // Export: the PDF goes to the share sheet.
      await tapText(
        tester,
        AppStrings.previewExport,
        settle: const Duration(seconds: 3),
      );
      expect(shares, isNotEmpty);
      final doc = shares.first.arguments['doc'];
      if (doc is List<int>) {
        await saveHostFile('sections/export.pdf', doc);
      }

      // The layout was saved with the CV, and survives a cold restart.
      await launchApp(tester, freshInstall: false);
      await waitFor(tester, find.text(AppStrings.homeTitle));
      final saved = await appContainer(
        tester,
      ).read(cvRepositoryImplProvider).getAllCvs();
      final cv = saved.firstWhere((c) => c.id == 'qa-nurse');
      expect(cv.sections.first.kind, CvSectionKind.education);
      expect(cv.isSectionVisible(CvSectionKind.skills), isFalse);
      expect(
        cv.sections
            .firstWhere((s) => s.kind == CvSectionKind.experience)
            .titleOverride,
        'Work history',
      );
      expect(cv.customSections.single.title, 'Awards');
      expect(
        cv.customSections.single.filledItems.single.title,
        'Best Nurse Award 2024',
      );
    },
  );
}
