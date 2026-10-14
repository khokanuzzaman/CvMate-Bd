import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/core/widgets/app_top_bar.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/education_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/experience_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/language_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/personal_info.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/ai_improve_controller.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/ai_improve_type.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../helpers/builder_harness.dart';
import '../../../../helpers/fake_cv_repository.dart';

Finder _field(String hint) => find.widgetWithText(TextField, hint);

Finder get _continue =>
    find.widgetWithText(PrimaryButton, AppStrings.builderContinue);

Finder get _back =>
    find.widgetWithText(SecondaryButton, AppStrings.builderBack);

Finder _step(int n, String section) => find.text('Step $n of 7 · $section');

Future<void> _type(WidgetTester tester, String hint, String text) async {
  await tester.enterText(_field(hint), text);
  await tester.pump();
}

Future<void> _tapChip(WidgetTester tester, String label) async {
  // Later chips sit off-screen in the horizontal scroller at phone width.
  await tester.ensureVisible(find.text(label));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

CvProfile _profile({
  List<EducationInfo> education = const [],
  List<ExperienceInfo> experiences = const [],
  List<LanguageInfo> languages = const [],
  String summary = '',
  String objective = '',
}) {
  return CvProfile.empty().copyWith(
    id: 'cv-1',
    title: 'Frontend Developer CV',
    personalInfo: const PersonalInfo(
      fullName: 'Ayesha Rahman',
      desiredRole: 'Frontend Developer',
      email: 'ayesha@email.com',
      phone: '01712345678',
      address: 'Dhaka, BD',
    ),
    education: education,
    experiences: experiences,
    languages: languages,
    professionalSummary: summary,
    careerObjective: objective,
  );
}

/// Lets any pending autosave timer fire so no timer outlives the test.
Future<void> _flush(WidgetTester tester) =>
    tester.pump(const Duration(seconds: 1));

void main() {
  late FakeCvRepository repository;

  setUp(() {
    repository = FakeCvRepository();
  });

  group('chrome', () {
    testWidgets('shows the CV title, section chips, progress and footer', (
      tester,
    ) async {
      await pumpBuilderApp(tester, repository: repository);

      expect(
        find.descendant(
          of: find.byType(AppTopBar),
          matching: find.text('New CV'),
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      for (final chip in [
        AppStrings.builderChipPersonal,
        AppStrings.builderChipEducation,
        AppStrings.builderChipExperience,
        AppStrings.builderChipSkills,
        AppStrings.builderChipProjects,
        AppStrings.builderChipTraining,
        AppStrings.builderChipSummary,
      ]) {
        expect(find.text(chip), findsOneWidget, reason: chip);
      }
      expect(_step(1, 'Personal'), findsOneWidget);
      expect(find.text('14%'), findsOneWidget);
      expect(_back, findsOneWidget);
      expect(_continue, findsOneWidget);
    });

    testWidgets('Personal page has the design fields plus the required ones', (
      tester,
    ) async {
      await pumpBuilderApp(tester, repository: repository);

      expect(find.text(AppStrings.photoPassportTitle), findsOneWidget);
      expect(find.text(AppStrings.photoPassportHint), findsOneWidget);
      for (final label in [
        AppStrings.builderFullName,
        AppStrings.builderHeadline,
        AppStrings.builderPhone,
        AppStrings.builderLocation,
        AppStrings.builderWebsite,
        // Not in the design, but required by the app's validation / data:
        AppStrings.builderEmail,
        AppStrings.builderPortfolio,
        AppStrings.builderCvTitle,
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
    });

    testWidgets('the photo block offers Take photo and Gallery', (
      tester,
    ) async {
      await pumpBuilderApp(tester, repository: repository);

      expect(find.text(AppStrings.photoTake), findsOneWidget);
      expect(find.text(AppStrings.photoGallery), findsOneWidget);
      expect(find.text(AppStrings.photoRemove), findsNothing);
    });

    testWidgets('Continue is blocked by the existing validation message', (
      tester,
    ) async {
      await pumpBuilderApp(tester, repository: repository);

      await tester.tap(_continue);
      await tester.pumpAndSettle();

      expect(_step(1, 'Personal'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
      // Shown in the snackbar and inline on the field.
      expect(find.text('Full name is required.'), findsWidgets);
    });

    testWidgets('the validation snackbar never covers Back / Continue', (
      tester,
    ) async {
      await pumpBuilderApp(tester, repository: repository);

      await tester.tap(_continue);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final snackBar = tester.getRect(find.byType(SnackBar));
      expect(
        snackBar.overlaps(tester.getRect(_continue)),
        isFalse,
        reason: 'the footer buttons must stay reachable while the toast shows',
      );
      expect(snackBar.overlaps(tester.getRect(_back)), isFalse);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('chips jump to a page and Back returns one page', (
      tester,
    ) async {
      await pumpBuilderApp(tester, repository: repository);

      await _tapChip(tester, AppStrings.builderChipProjects);
      expect(_step(5, 'Projects'), findsOneWidget);
      expect(find.text('71%'), findsOneWidget);

      await tester.tap(_back);
      await tester.pumpAndSettle();
      expect(_step(4, 'Skills & languages'), findsOneWidget);
    });

    testWidgets('the Skills page still enforces at least two skills', (
      tester,
    ) async {
      await pumpBuilderApp(tester, repository: repository);

      await _tapChip(tester, AppStrings.builderChipSkills);
      await tester.tap(_continue);
      await tester.pumpAndSettle();

      expect(_step(4, 'Skills & languages'), findsOneWidget);
      expect(
        find.text('Add at least two skills for a stronger CV.'),
        findsOneWidget,
      );
    });

    testWidgets('Training is kept as its own page before Summary', (
      tester,
    ) async {
      final container = await pumpBuilderApp(tester, repository: repository);

      await _tapChip(tester, AppStrings.builderChipTraining);
      expect(_step(6, 'Training / certifications'), findsOneWidget);

      await tester.tap(find.text(AppStrings.builderAddFirstTraining));
      await tester.pumpAndSettle();
      await _type(
        tester,
        AppStrings.builderTrainingNameHint,
        'Flutter bootcamp',
      );
      await _type(tester, AppStrings.builderOrganizationHint, 'Code Academy');

      final training = container
          .read(cvBuilderControllerProvider)
          .draft
          .trainings
          .single;
      expect(training.title, 'Flutter bootcamp');
      expect(training.organization, 'Code Academy');
      await _flush(tester);
    });
  });

  group('building a CV start to finish', () {
    testWidgets('personal → … → summary → preview, saving as it goes', (
      tester,
    ) async {
      final container = await pumpBuilderApp(tester, repository: repository);
      CvProfile draft() => container.read(cvBuilderControllerProvider).draft;

      // 1 · Personal
      await _type(tester, AppStrings.builderFullNameHint, 'Ayesha Rahman');
      await _type(tester, AppStrings.builderHeadlineHint, 'Frontend Developer');
      await _type(tester, AppStrings.builderPhoneHint, '01712345678');
      await _type(tester, AppStrings.builderLocationHint, 'Dhaka, BD');
      await _type(tester, AppStrings.builderEmailHint, 'ayesha@email.com');
      expect(draft().personalInfo.fullName, 'Ayesha Rahman');
      expect(draft().personalInfo.desiredRole, 'Frontend Developer');
      await tester.tap(_continue);
      await tester.pumpAndSettle();

      // 2 · Education — one inline card.
      expect(_step(2, 'Education'), findsOneWidget);
      expect(find.text('28%'), findsOneWidget);
      await tester.tap(find.text(AppStrings.builderAddFirstDegree));
      await tester.pumpAndSettle();
      expect(find.text('DEGREE 1'), findsOneWidget);
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
      final education = draft().education.single;
      expect(education.degree, 'BSc in Computer Science');
      expect(education.institution, 'Dhaka University');
      expect(education.startYear, '2018');
      expect(education.endYear, '2022');
      expect(education.isOngoing, isFalse);
      await tester.tap(_continue);
      await tester.pumpAndSettle();

      // 3 · Experience — dates box and bullets map back to the model.
      expect(_step(3, 'Experience'), findsOneWidget);
      await tester.tap(find.text(AppStrings.builderAddFirstRole));
      await tester.pumpAndSettle();
      expect(find.text('ROLE 1'), findsOneWidget);
      expect(find.text(AppStrings.builderImproveWithAi), findsOneWidget);
      await _type(tester, AppStrings.builderJobTitleHint, 'Frontend Developer');
      await _type(tester, AppStrings.builderCompanyHint, 'Acme Ltd.');
      await _type(tester, AppStrings.builderExperienceDatesHint, '2022 — Now');
      await _type(
        tester,
        AppStrings.builderBulletsHint,
        '• Built responsive interfaces\n• Shipped features each sprint',
      );
      final role = draft().experiences.single;
      expect(role.jobTitle, 'Frontend Developer');
      expect(role.companyName, 'Acme Ltd.');
      expect(role.startDate, '2022');
      expect(role.isCurrentRole, isTrue);
      expect(role.endDate, '');
      expect(role.highlights, [
        'Built responsive interfaces',
        'Shipped features each sprint',
      ]);
      await tester.tap(_continue);
      await tester.pumpAndSettle();

      // 4 · Skills & languages
      expect(_step(4, 'Skills & languages'), findsOneWidget);
      await _type(tester, AppStrings.builderSkillInputHint, 'React');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('React'), findsOneWidget);
      // Suggested skills come from the headline; tapping one adds it.
      await tester.tap(find.text('+TypeScript'));
      await tester.pumpAndSettle();
      expect(draft().skills.map((s) => s.name), ['React', 'TypeScript']);
      expect(find.text('+TypeScript'), findsNothing);

      await tester.tap(find.text(AppStrings.builderAddLanguage));
      await tester.pumpAndSettle();
      await _type(tester, AppStrings.builderLanguageNameHint, 'Bangla');
      await tester.tap(find.text(AppStrings.builderSaveLanguage));
      await tester.pumpAndSettle();
      expect(draft().languages.single.name, 'Bangla');
      expect(draft().languages.single.proficiency, 'Basic');
      await tester.tap(_continue);
      await tester.pumpAndSettle();

      // 5 · Projects (optional) and 6 · Training (optional)
      expect(_step(5, 'Projects'), findsOneWidget);
      await tester.tap(_continue);
      await tester.pumpAndSettle();
      expect(_step(6, 'Training / certifications'), findsOneWidget);
      await tester.tap(_continue);
      await tester.pumpAndSettle();

      // 7 · Summary — done banner, then Preview CV.
      expect(_step(7, 'Summary'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text(AppStrings.builderAllDone), findsNothing);
      await _type(
        tester,
        AppStrings.builderSummaryHint,
        'Front-end developer building accessible, performant React interfaces.',
      );
      expect(find.text(AppStrings.builderAllDone), findsOneWidget);
      expect(
        find.widgetWithText(PrimaryButton, AppStrings.builderPreviewCv),
        findsOneWidget,
      );

      await tester.tap(
        find.widgetWithText(PrimaryButton, AppStrings.builderPreviewCv),
      );
      await tester.pumpAndSettle();

      // Saved before leaving, and the preview shows the finished CV.
      expect(
        repository.saved(draft().id)?.personalInfo.fullName,
        'Ayesha Rahman',
      );
      expect(find.text(AppStrings.previewTitle), findsOneWidget);
      expect(find.text('Ayesha Rahman'), findsOneWidget);
      expect(find.text(AppStrings.previewExport), findsOneWidget);
      await _flush(tester);
    });

    testWidgets('Preview CV on the last page validates the summary first', (
      tester,
    ) async {
      await pumpBuilderApp(tester, repository: repository);

      await _tapChip(tester, AppStrings.builderChipSummary);
      await tester.tap(
        find.widgetWithText(PrimaryButton, AppStrings.builderPreviewCv),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.previewTitle), findsNothing);
      expect(
        find.text(
          'Add a professional summary or a career objective before continuing.',
        ),
        findsWidgets,
      );
    });

    testWidgets('the eye icon opens the preview from any page', (tester) async {
      await pumpBuilderApp(tester, repository: repository);

      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.previewTitle), findsOneWidget);
    });
  });

  group('entries', () {
    testWidgets('an entry can be removed from its card', (tester) async {
      final container = await pumpBuilderApp(tester, repository: repository);

      await _tapChip(tester, AppStrings.builderChipEducation);
      await tester.tap(find.text(AppStrings.builderAddFirstDegree));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.builderAddAnotherDegree));
      await tester.pumpAndSettle();
      expect(find.text('DEGREE 1'), findsOneWidget);
      expect(find.text('DEGREE 2'), findsOneWidget);

      await tester.tap(find.byTooltip(AppStrings.builderRemoveEntry).first);
      await tester.pumpAndSettle();

      expect(
        container.read(cvBuilderControllerProvider).draft.education.length,
        1,
      );
      expect(find.text('DEGREE 2'), findsNothing);
      await _flush(tester);
    });

    testWidgets('a skill chip is removed with its ×', (tester) async {
      final container = await pumpBuilderApp(tester, repository: repository);

      await _tapChip(tester, AppStrings.builderChipSkills);
      await _type(tester, AppStrings.builderSkillInputHint, 'React');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('React'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(container.read(cvBuilderControllerProvider).draft.skills, isEmpty);
      expect(find.text('React'), findsNothing);
      await _flush(tester);
    });

    testWidgets('duplicate skills are not added twice', (tester) async {
      final container = await pumpBuilderApp(tester, repository: repository);

      await _tapChip(tester, AppStrings.builderChipSkills);
      for (final value in ['React', 'react ']) {
        await _type(tester, AppStrings.builderSkillInputHint, value);
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
      }

      expect(
        container.read(cvBuilderControllerProvider).draft.skills.length,
        1,
      );
      await _flush(tester);
    });

    testWidgets('a saved language is edited and removed from its sheet', (
      tester,
    ) async {
      final container = await pumpBuilderApp(
        tester,
        repository: FakeCvRepository([
          _profile(
            languages: [
              LanguageInfo.empty(
                id: 'l1',
              ).copyWith(name: 'Bangla', proficiency: 'Native'),
            ],
          ),
        ]),
        loadDraftId: 'cv-1',
      );
      await _tapChip(tester, AppStrings.builderChipSkills);

      expect(find.text('Bangla'), findsOneWidget);
      expect(find.text('Native'), findsOneWidget);

      await tester.tap(find.text('Bangla'));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.builderEditLanguage), findsOneWidget);
      await tester.tap(find.text(AppStrings.builderDeleteLanguage));
      await tester.pumpAndSettle();

      expect(
        container.read(cvBuilderControllerProvider).draft.languages,
        isEmpty,
      );
      await _flush(tester);
    });
  });

  group('data safety', () {
    testWidgets('editing one field never rewrites untouched dates or bullets', (
      tester,
    ) async {
      // A start date that would NOT survive a parse (it contains " - ").
      final original = ExperienceInfo.empty(id: 'e1').copyWith(
        jobTitle: 'Engineer',
        companyName: 'Acme',
        startDate: 'Q1 - Q2 2020',
        endDate: '2021',
        highlights: const ['Did a thing', '  Did another  '],
      );
      final container = await pumpBuilderApp(
        tester,
        repository: FakeCvRepository([
          _profile(experiences: [original]),
        ]),
        loadDraftId: 'cv-1',
      );
      await _tapChip(tester, AppStrings.builderChipExperience);

      await tester.enterText(
        find.widgetWithText(TextField, 'Engineer'),
        'Senior Engineer',
      );
      await tester.pump();

      final updated = container
          .read(cvBuilderControllerProvider)
          .draft
          .experiences
          .single;
      expect(updated.jobTitle, 'Senior Engineer');
      expect(updated.startDate, 'Q1 - Q2 2020');
      expect(updated.endDate, '2021');
      expect(updated.isCurrentRole, isFalse);
      expect(updated.highlights, original.highlights);
      await _flush(tester);
    });

    testWidgets(
      'an ongoing education stays ongoing when another field changes',
      (tester) async {
        final container = await pumpBuilderApp(
          tester,
          repository: FakeCvRepository([
            _profile(
              education: [
                EducationInfo.empty(id: 'ed1').copyWith(
                  degree: 'BSc',
                  institution: 'DU',
                  startYear: '2021',
                  isOngoing: true,
                ),
              ],
            ),
          ]),
          loadDraftId: 'cv-1',
        );
        await _tapChip(tester, AppStrings.builderChipEducation);
        expect(find.widgetWithText(TextField, '2021 — Now'), findsOneWidget);

        await tester.enterText(
          find.widgetWithText(TextField, 'BSc'),
          'BSc CSE',
        );
        await tester.pump();

        final updated = container
            .read(cvBuilderControllerProvider)
            .draft
            .education
            .single;
        expect(updated.degree, 'BSc CSE');
        expect(updated.isOngoing, isTrue);
        expect(updated.startYear, '2021');
        expect(updated.endYear, '');
        await _flush(tester);
      },
    );

    testWidgets('fields re-read the draft after the AI screen edits it', (
      tester,
    ) async {
      final container = await pumpBuilderApp(
        tester,
        repository: FakeCvRepository([
          _profile(
            experiences: [
              ExperienceInfo.empty(id: 'e1').copyWith(
                jobTitle: 'Engineer',
                companyName: 'Acme',
                highlights: const ['Original bullet'],
              ),
            ],
          ),
        ]),
        loadDraftId: 'cv-1',
      );
      await _tapChip(tester, AppStrings.builderChipExperience);
      expect(
        find.widgetWithText(TextField, '• Original bullet'),
        findsOneWidget,
      );

      // "Improve with AI" opens the AI screen with the right type selected.
      await tester.tap(find.text(AppStrings.builderImproveWithAi));
      await tester.pumpAndSettle();
      expect(find.text(aiImprovePlaceholder), findsOneWidget);
      expect(
        container.read(aiImproveControllerProvider).improvementType,
        AiImproveType.experienceBullet,
      );

      // The AI screen applies a suggestion to the draft, then the user returns.
      final notifier = container.read(cvBuilderControllerProvider.notifier);
      final role = container
          .read(cvBuilderControllerProvider)
          .draft
          .experiences
          .single;
      notifier.updateExperience(
        role.copyWith(highlights: const ['AI rewrote this']),
      );
      GoRouter.of(tester.element(find.text(aiImprovePlaceholder))).pop();
      await tester.pumpAndSettle();

      expect(container.read(cvBuilderRefreshProvider), 1);
      expect(
        find.widgetWithText(TextField, '• AI rewrote this'),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextField, '• Original bullet'), findsNothing);
      await _flush(tester);
    });
  });

  group('Summary page', () {
    testWidgets('toggles between summary and objective, keeping both texts', (
      tester,
    ) async {
      final container = await pumpBuilderApp(
        tester,
        repository: FakeCvRepository([
          _profile(
            summary:
                'A summary that is comfortably longer than forty characters.',
            objective: 'Seeking a frontend role to grow.',
          ),
        ]),
        loadDraftId: 'cv-1',
      );
      await _tapChip(tester, AppStrings.builderChipSummary);

      expect(
        find.text(AppStrings.builderProfessionalSummary.toUpperCase()),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(
          TextField,
          'A summary that is comfortably longer than forty characters.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text(AppStrings.builderToggleObjective));
      await tester.pumpAndSettle();
      expect(
        find.text(AppStrings.builderCareerObjective.toUpperCase()),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(TextField, 'Seeking a frontend role to grow.'),
        findsOneWidget,
      );

      await tester.enterText(
        find.widgetWithText(TextField, 'Seeking a frontend role to grow.'),
        'Seeking a frontend role to grow and lead.',
      );
      await tester.pump();

      final draft = container.read(cvBuilderControllerProvider).draft;
      expect(
        draft.careerObjective,
        'Seeking a frontend role to grow and lead.',
      );
      expect(
        draft.professionalSummary,
        'A summary that is comfortably longer than forty characters.',
        reason: 'the other text is untouched',
      );
      await _flush(tester);
    });

    testWidgets('"Generate with AI" preselects the matching AI type', (
      tester,
    ) async {
      final container = await pumpBuilderApp(
        tester,
        repository: FakeCvRepository([_profile()]),
        loadDraftId: 'cv-1',
      );
      await _tapChip(tester, AppStrings.builderChipSummary);

      await tester.tap(find.text(AppStrings.builderGenerateWithAi));
      await tester.pumpAndSettle();

      expect(find.text(aiImprovePlaceholder), findsOneWidget);
      expect(
        container.read(aiImproveControllerProvider).improvementType,
        AiImproveType.professionalSummary,
      );
    });
  });

  group('draft safety', () {
    Future<ProviderContainer> openBuilderOverList(WidgetTester tester) async {
      final container = await pumpBuilderApp(
        tester,
        repository: repository,
        initialLocation: RouteNames.cvListPath,
      );
      GoRouter.of(tester.element(find.text('cv-list-page'))).push(builderPath);
      await tester.pumpAndSettle();
      return container;
    }

    String savedName(ProviderContainer container) {
      final id = container.read(cvBuilderControllerProvider).draft.id;
      return repository.saved(id)?.personalInfo.fullName ?? '';
    }

    testWidgets('moving to another page saves at once, not after the delay', (
      tester,
    ) async {
      final container = await pumpBuilderApp(tester, repository: repository);

      await _type(tester, AppStrings.builderFullNameHint, 'Ayesha Rahman');
      expect(
        savedName(container),
        '',
        reason: 'still waiting on the autosave timer',
      );

      await tester.tap(find.text(AppStrings.builderChipEducation));
      await tester.pump(); // one frame only: far less than the 800ms delay
      expect(savedName(container), 'Ayesha Rahman');
      await _flush(tester);
    });

    testWidgets('the Continue / Back buttons save the page being left', (
      tester,
    ) async {
      final container = await pumpBuilderApp(tester, repository: repository);
      await _tapChip(tester, AppStrings.builderChipEducation);

      await tester.tap(find.text(AppStrings.builderAddFirstDegree));
      await tester.pumpAndSettle();
      await _type(tester, AppStrings.builderDegreeHint, 'BSc');
      await tester.tap(_back);
      await tester.pump();

      final id = container.read(cvBuilderControllerProvider).draft.id;
      expect(repository.saved(id)?.education.single.degree, 'BSc');
      await _flush(tester);
    });

    testWidgets('does not save again when there is nothing new to save', (
      tester,
    ) async {
      await pumpBuilderApp(tester, repository: repository);

      await _type(tester, AppStrings.builderFullNameHint, 'Ayesha Rahman');
      await tester.tap(find.text(AppStrings.builderChipEducation));
      await tester.pump();
      final afterFirstMove = repository.saveCount;
      expect(afterFirstMove, 1);

      await tester.tap(find.text(AppStrings.builderChipPersonal));
      await tester.pump();
      await tester.tap(find.text(AppStrings.builderChipEducation));
      await tester.pump();

      expect(repository.saveCount, afterFirstMove);
      await _flush(tester);
    });

    testWidgets('leaving with the back button saves the draft', (tester) async {
      final container = await openBuilderOverList(tester);

      await _type(tester, AppStrings.builderFullNameHint, 'Ayesha Rahman');
      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.pumpAndSettle();

      expect(find.text('cv-list-page'), findsOneWidget);
      expect(savedName(container), 'Ayesha Rahman');
    });

    testWidgets('leaving by any other route also saves the draft', (
      tester,
    ) async {
      final container = await openBuilderOverList(tester);

      await _type(tester, AppStrings.builderFullNameHint, 'Ayesha Rahman');
      expect(savedName(container), '');

      // Not the back button: a plain navigation away disposes the builder.
      GoRouter.of(
        tester.element(find.text(AppStrings.builderFullName)),
      ).go(RouteNames.cvListPath);
      await tester.pumpAndSettle();

      expect(find.text('cv-list-page'), findsOneWidget);
      expect(savedName(container), 'Ayesha Rahman');
    });

    testWidgets('sending the app to the background saves the draft', (
      tester,
    ) async {
      final container = await pumpBuilderApp(tester, repository: repository);

      await _type(tester, AppStrings.builderFullNameHint, 'Ayesha Rahman');
      expect(savedName(container), '');

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      expect(savedName(container), 'Ayesha Rahman');
      await _flush(tester);
    });

    testWidgets('there is no manual Save button in the top bar', (
      tester,
    ) async {
      await pumpBuilderApp(tester, repository: repository);

      expect(find.byIcon(Icons.save_outlined), findsNothing);
      expect(find.byTooltip('Save draft'), findsNothing);
    });
  });
}
