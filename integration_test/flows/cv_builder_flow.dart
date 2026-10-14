import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/features/cv_builder/data/repositories/cv_repository_impl.dart';
import 'package:careermatebd/features/subscription/presentation/screens/paywall_screen.dart';
import 'package:careermatebd/features/subscription/presentation/widgets/paywall_plan_card.dart';
import 'package:careermatebd/shared/services/entitlement/entitlement_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test/helpers/printing_mock.dart';
import '../support/qa_harness.dart';

Finder get _continue =>
    find.widgetWithText(PrimaryButton, AppStrings.builderContinue);
Finder _field(String hint) => find.widgetWithText(TextField, hint);
Finder _step(int n, String section) => find.text('Step $n of 7 · $section');

Future<void> _type(WidgetTester tester, String hint, String text) async {
  await typeInto(tester, _field(hint), text);
}

Future<void> _openNewCv(WidgetTester tester) async {
  await tapText(tester, AppStrings.homeNewCv);
  // New CVs start on the CV style screen; keep the default (International).
  await waitFor(tester, find.text(AppStrings.styleTitle));
  await tapOn(
    tester,
    find.widgetWithText(
      PrimaryButton,
      AppStrings.styleUse(AppStrings.styleShortInternational),
    ),
  );
  await waitFor(tester, _step(1, 'Personal'));
}

void registerCvBuilderFlow() {
  qaTest(
    'cv builder: all 7 steps → preview → template → export 1 free, 2 paywall',
    (tester) async {
      final shares = mockSharePlugin(tester);
      await launchSignedIn(tester);
      await shot(tester, 'cv-builder', 'home-empty');
      await _openNewCv(tester);
      await shot(tester, 'cv-builder', 'step1-personal-empty');

      // Validation: Continue with nothing filled in.
      await tapOn(tester, _continue);
      expect(find.text('Full name is required.'), findsWidgets);
      await shot(tester, 'cv-builder', 'step1-validation');

      await _type(tester, AppStrings.builderFullNameHint, 'Ayesha Rahman');
      await _type(tester, AppStrings.builderHeadlineHint, 'Frontend Developer');
      await _type(tester, AppStrings.builderPhoneHint, '01712345678');
      await _type(tester, AppStrings.builderLocationHint, 'Dhaka, BD');
      await _type(tester, AppStrings.builderEmailHint, 'ayesha@email.com');
      await shotTop(tester, 'cv-builder', 'step1-personal-filled');
      await tapOn(tester, _continue);

      // 2 · Education
      await waitFor(tester, _step(2, 'Education'));
      await shot(tester, 'cv-builder', 'step2-education-empty');
      await tapText(tester, AppStrings.builderAddFirstDegree);
      await _type(
        tester,
        AppStrings.builderDegreeHint,
        'BSc in Computer Science',
      );
      await _type(
        tester,
        AppStrings.builderInstitutionHint,
        'Dhaka University',
      );
      await _type(tester, AppStrings.builderEducationDatesHint, '2018 — 2022');
      await shotTop(tester, 'cv-builder', 'step2-education-filled');
      await tapOn(tester, _continue);

      // 3 · Experience
      await waitFor(tester, _step(3, 'Experience'));
      await tapText(tester, AppStrings.builderAddFirstRole);
      await _type(tester, AppStrings.builderJobTitleHint, 'Frontend Developer');
      await _type(tester, AppStrings.builderCompanyHint, 'Acme Ltd.');
      await _type(tester, AppStrings.builderExperienceDatesHint, '2022 — Now');
      await _type(
        tester,
        AppStrings.builderBulletsHint,
        '• Built responsive interfaces\n• Shipped features each sprint',
      );
      await shotTop(tester, 'cv-builder', 'step3-experience-filled');
      await tapOn(tester, _continue);

      // 4 · Skills & languages
      await waitFor(tester, _step(4, 'Skills & languages'));
      await shot(tester, 'cv-builder', 'step4-skills-empty');
      await _type(tester, AppStrings.builderSkillInputHint, 'React');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await pumpFor(tester, const Duration(milliseconds: 400));
      await tapText(tester, '+TypeScript');
      await tapText(tester, AppStrings.builderAddLanguage);
      await _type(tester, AppStrings.builderLanguageNameHint, 'Bangla');
      await shot(tester, 'cv-builder', 'step4-language-sheet');
      await tapText(tester, AppStrings.builderSaveLanguage);
      await shotTop(tester, 'cv-builder', 'step4-skills-filled');
      await tapOn(tester, _continue);

      // 5 · Projects, 6 · Training (optional) — look at both empty.
      await waitFor(tester, _step(5, 'Projects'));
      await shot(tester, 'cv-builder', 'step5-projects-empty');
      await tapText(tester, AppStrings.builderAddFirstProject);
      await _type(tester, AppStrings.builderProjectNameHint, 'Expense Tracker');
      await _type(
        tester,
        AppStrings.builderBulletsHint,
        '• Personal finance app with charts and budgets.',
      );
      await shotTop(tester, 'cv-builder', 'step5-projects-filled');
      await tapOn(tester, _continue);
      await waitFor(tester, _step(6, 'Training / certifications'));
      await shot(tester, 'cv-builder', 'step6-training-empty');
      await tapOn(tester, _continue);

      // 7 · Summary
      await waitFor(tester, _step(7, 'Summary'));
      await shot(tester, 'cv-builder', 'step7-summary-empty');
      await _type(
        tester,
        AppStrings.builderSummaryHint,
        'Front-end developer building accessible, performant React interfaces.',
      );
      await shotTop(tester, 'cv-builder', 'step7-summary-filled');
      await tapOn(
        tester,
        find.widgetWithText(PrimaryButton, AppStrings.builderPreviewCv),
        settle: const Duration(seconds: 1),
      );

      // Preview
      await waitFor(tester, find.text(AppStrings.previewExport));
      expect(find.text('Ayesha Rahman'), findsWidgets);
      await shot(tester, 'cv-builder', 'preview-modern');

      // Template picker → switch to Minimal.
      await tapOn(
        tester,
        find.widgetWithText(SecondaryButton, AppStrings.previewTemplate),
      );
      await waitFor(tester, find.text(AppStrings.templateTitle));
      await shot(tester, 'cv-builder', 'template-picker');
      await tapText(tester, 'Minimal');
      await shot(tester, 'cv-builder', 'template-picker-minimal-selected');
      await tapText(tester, 'Use Minimal template');
      await waitFor(tester, find.text(AppStrings.previewExport));
      await shot(tester, 'cv-builder', 'preview-minimal');

      // Export #1 is free; export #2 opens the paywall.
      final entitlements = appContainer(
        tester,
      ).read(entitlementServiceProvider);
      expect(await entitlements.remainingFreeExports, 1);
      await tapText(
        tester,
        AppStrings.previewExport,
        settle: const Duration(seconds: 3),
      );
      expect(
        shares,
        isNotEmpty,
        reason: 'export #1 should reach the share sheet',
      );
      final doc = shares.first.arguments['doc'];
      if (doc is List<int>) {
        await saveHostFile('cv-builder/export-1.pdf', doc);
      }
      final sharedName = (shares.first.arguments as Map)['name'] as String;
      expect(sharedName, endsWith('.pdf'));
      expect(
        sharedName,
        isNot(contains('_cv_cv')),
        reason: 'the export file name must not double the "_cv" suffix',
      );
      expect(find.byType(PaywallScreen), findsNothing);
      expect(await entitlements.remainingFreeExports, 0);
      await shot(tester, 'cv-builder', 'after-export-1');

      await tapText(
        tester,
        AppStrings.previewExport,
        settle: const Duration(seconds: 2),
      );
      await waitFor(tester, find.byType(PaywallScreen));
      expect(shares.length, 1, reason: 'export #2 must not share');
      await shot(tester, 'cv-builder', 'paywall-after-export-2');

      // Prices are on the first screen, above the pinned button (even on an
      // iPhone SE). Only checked at normal text size: at 1.5x the page scrolls.
      if (qaTextScale <= 1.0) {
        final cta = tester.getRect(
          find.widgetWithText(PrimaryButton, AppStrings.paywallCta),
        );
        for (final element in find.byType(PaywallPlanCard).evaluate()) {
          final rect = tester.getRect(find.byWidget(element.widget));
          expect(
            rect.bottom,
            lessThanOrEqualTo(cta.top),
            reason: 'a price card is hidden below the fold / behind the button',
          );
        }
        expect(
          tester.getRect(find.text(AppStrings.paywallOneTimeSubtitle)).bottom,
          lessThanOrEqualTo(cta.top),
        );
      }
    },
  );

  qaTest('cv builder: leave mid-way and return (auto-save)', (tester) async {
    await launchSignedIn(tester);
    await _openNewCv(tester);
    await _type(tester, AppStrings.builderFullNameHint, 'Nusrat Jahan');
    await _type(tester, AppStrings.builderHeadlineHint, 'Staff Nurse');
    await _type(tester, AppStrings.builderEmailHint, 'nusrat@email.com');
    await _type(tester, AppStrings.builderPhoneHint, '01812345678');
    await _type(tester, AppStrings.builderLocationHint, 'Dhaka, BD');
    await tapOn(tester, _continue);
    await waitFor(tester, _step(2, 'Education'));
    await tapText(tester, AppStrings.builderAddFirstDegree);
    await _type(tester, AppStrings.builderDegreeHint, 'BSc in Nursing');
    await shot(tester, 'cv-builder-autosave', 'mid-way-step2');

    // Leave with the back control, no explicit save.
    await goBack(tester);
    await waitFor(tester, find.text(AppStrings.homeTitle));
    await shot(tester, 'cv-builder-autosave', 'home-after-leaving');

    final saved = await appContainer(
      tester,
    ).read(cvRepositoryImplProvider).getAllCvs();
    expect(saved, isNotEmpty, reason: 'leaving mid-way must keep the draft');
    expect(saved.first.personalInfo.fullName, 'Nusrat Jahan');
    expect(saved.first.education.single.degree, 'BSc in Nursing');

    // A cold restart, then reopen the draft from the CVs tab.
    await launchApp(tester, freshInstall: false);
    await waitFor(tester, find.text(AppStrings.homeTitle));
    await shot(tester, 'cv-builder-autosave', 'home-after-restart');
    await tapText(tester, 'CVs');
    await waitFor(tester, find.text('Edit saved CV'));
    await shot(tester, 'cv-builder-autosave', 'cv-list');
    await tapText(tester, 'Edit saved CV');
    await waitFor(tester, find.text('Step 1 of 7 · Personal'));
    expect(_field(AppStrings.builderFullNameHint), findsOneWidget);
    expect(find.text('Nusrat Jahan'), findsWidgets);
    await shot(tester, 'cv-builder-autosave', 'reopened-step1');
    await tapOn(tester, _continue);
    await waitFor(tester, _step(2, 'Education'));
    expect(find.text('BSc in Nursing'), findsWidgets);
    await shot(tester, 'cv-builder-autosave', 'reopened-step2');
  });
}
