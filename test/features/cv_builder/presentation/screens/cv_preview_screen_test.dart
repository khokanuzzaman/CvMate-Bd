import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_template.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/education_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/experience_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/language_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/personal_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/project_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/skill_info.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/training_info.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:careermatebd/shared/services/entitlement/entitlement_record.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/builder_harness.dart';
import '../../../../helpers/fake_cv_repository.dart';

CvProfile _fullProfile() {
  return CvProfile.empty().copyWith(
    id: 'cv-1',
    title: 'Frontend Developer CV',
    template: CvTemplate.modern,
    personalInfo: const PersonalInfo(
      fullName: 'Ayesha Rahman',
      desiredRole: 'Frontend Developer',
      email: 'ayesha@email.com',
      phone: '01712345678',
      address: 'Dhaka, BD',
      linkedInUrl: 'https://linkedin.com/in/ayesha',
    ),
    professionalSummary: 'Front-end developer building accessible interfaces.',
    careerObjective: 'Grow into a staff engineer.',
    experiences: [
      ExperienceInfo.empty(id: 'e1').copyWith(
        jobTitle: 'Frontend Developer',
        companyName: 'Acme Ltd.',
        startDate: '2022',
        isCurrentRole: true,
        highlights: const [
          'Rebuilt key screens',
          'Shipped features each sprint',
        ],
      ),
    ],
    skills: [
      SkillInfo.empty(id: 's1').copyWith(name: 'React'),
      SkillInfo.empty(id: 's2').copyWith(name: 'TypeScript'),
    ],
    education: [
      EducationInfo.empty(id: 'd1').copyWith(
        degree: 'BSc in Computer Science',
        institution: 'University name',
        startYear: '2018',
        endYear: '2022',
      ),
    ],
    projects: [
      ProjectInfo.empty(id: 'p1').copyWith(
        title: 'Expense Tracker',
        description: 'Personal finance app.',
        technologies: const ['React', 'Firebase'],
      ),
    ],
    trainings: [
      TrainingInfo.empty(id: 't1').copyWith(
        title: 'Flutter bootcamp',
        organization: 'Code Academy',
        completionYear: '2024',
      ),
    ],
    languages: [
      LanguageInfo.empty(
        id: 'l1',
      ).copyWith(name: 'Bangla', proficiency: 'Native'),
    ],
  );
}

void main() {
  group('paper preview', () {
    testWidgets('renders the whole CV as a paper with its sections', (
      tester,
    ) async {
      await pumpBuilderApp(
        tester,
        repository: FakeCvRepository([_fullProfile()]),
        initialLocation: RouteNames.cvPreviewPath,
        loadDraftId: 'cv-1',
      );

      expect(find.text('Ayesha Rahman'), findsOneWidget);
      expect(find.text('Frontend Developer'), findsWidgets);
      expect(
        find.text(
          'Dhaka, BD · 01712345678 · ayesha@email.com · https://linkedin.com/in/ayesha',
        ),
        findsOneWidget,
      );
      for (final title in [
        'SUMMARY',
        'OBJECTIVE',
        'EXPERIENCE',
        'SKILLS',
        'EDUCATION',
        'PROJECTS',
        'TRAINING / CERTIFICATIONS',
        'LANGUAGES',
      ]) {
        expect(find.text(title), findsOneWidget, reason: title);
      }
      expect(find.text('Frontend Developer — Acme Ltd.'), findsOneWidget);
      expect(find.text('2022 — Now'), findsOneWidget);
      expect(find.text('• Rebuilt key screens'), findsOneWidget);
      expect(find.text('React'), findsOneWidget);
      expect(find.text('BSc in Computer Science'), findsOneWidget);
      expect(find.text('2018 — 2022'), findsOneWidget);
      expect(find.text('Bangla · Native'), findsOneWidget);
    });

    testWidgets('omits sections that have no content instead of placeholders', (
      tester,
    ) async {
      await pumpBuilderApp(
        tester,
        repository: FakeCvRepository([
          CvProfile.empty().copyWith(
            id: 'cv-1',
            personalInfo: const PersonalInfo(fullName: 'Ayesha Rahman'),
          ),
        ]),
        initialLocation: RouteNames.cvPreviewPath,
        loadDraftId: 'cv-1',
      );

      expect(find.text('Ayesha Rahman'), findsOneWidget);
      for (final title in ['SUMMARY', 'EXPERIENCE', 'SKILLS', 'EDUCATION']) {
        expect(find.text(title), findsNothing, reason: title);
      }
    });

    testWidgets('shows the template pill and opens the picker from it', (
      tester,
    ) async {
      await pumpBuilderApp(
        tester,
        repository: FakeCvRepository([_fullProfile()]),
        initialLocation: RouteNames.cvPreviewPath,
        loadDraftId: 'cv-1',
      );

      expect(find.text('Modern'), findsOneWidget);
      await tester.tap(find.text('Modern'));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.templateTitle), findsOneWidget);
    });

    testWidgets('Template button opens the picker too', (tester) async {
      await pumpBuilderApp(
        tester,
        repository: FakeCvRepository([_fullProfile()]),
        initialLocation: RouteNames.cvPreviewPath,
        loadDraftId: 'cv-1',
      );

      await tester.tap(
        find.widgetWithText(SecondaryButton, AppStrings.previewTemplate),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.templateTitle), findsOneWidget);
    });

    testWidgets('Export is disabled while the CV is empty', (tester) async {
      await pumpBuilderApp(
        tester,
        repository: FakeCvRepository([CvProfile.empty().copyWith(id: 'cv-1')]),
        initialLocation: RouteNames.cvPreviewPath,
        loadDraftId: 'cv-1',
      );

      final export = tester.widget<PrimaryButton>(
        find.widgetWithText(PrimaryButton, AppStrings.previewExport),
      );
      expect(export.onPressed, isNull);
    });
  });

  group('export gate', () {
    testWidgets('after the free export is used, Export opens the paywall', (
      tester,
    ) async {
      final store = FakeEntitlementStore(
        const EntitlementRecord(
          isPro: false,
          freeExportsUsed: 1,
          aiCreditsLeft: 20,
        ),
      );
      await pumpBuilderApp(
        tester,
        repository: FakeCvRepository([_fullProfile()]),
        entitlements: store,
        initialLocation: RouteNames.cvPreviewPath,
        loadDraftId: 'cv-1',
      );

      await tester.tap(
        find.widgetWithText(PrimaryButton, AppStrings.previewExport),
      );
      await tester.pumpAndSettle();

      expect(find.text(paywallPlaceholder), findsOneWidget);
      expect(store.saveCount, 0, reason: 'nothing exported, nothing recorded');
    });

    testWidgets('the first export is free: it shares the PDF and is recorded', (
      tester,
    ) async {
      final shared = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('net.nfet.printing'),
        (call) async {
          shared.add(call);
          return 1;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('net.nfet.printing'),
          null,
        ),
      );

      final store = FakeEntitlementStore();
      await pumpBuilderApp(
        tester,
        repository: FakeCvRepository([_fullProfile()]),
        entitlements: store,
        initialLocation: RouteNames.cvPreviewPath,
        loadDraftId: 'cv-1',
      );

      await tester.tap(
        find.widgetWithText(PrimaryButton, AppStrings.previewExport),
      );
      // Real PDF generation runs on real async work.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 800)),
      );
      await tester.pumpAndSettle();

      expect(
        shared,
        isNotEmpty,
        reason: 'the PDF was handed to the share sheet',
      );
      expect(shared.single.method, 'sharePdf');
      final args = shared.single.arguments as Map;
      expect(args['name'] as String, endsWith('.pdf'));
      expect((args['doc'] as Uint8List).take(4), [
        0x25,
        0x50,
        0x44,
        0x46,
      ]); // %PDF
      expect(store.saveCount, 1, reason: 'the free export was recorded');
      expect(store.record.freeExportsUsed, 1);
      expect(find.text(paywallPlaceholder), findsNothing);
    });

    testWidgets('a failed share is not recorded as a used export', (
      tester,
    ) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('net.nfet.printing'),
        (call) async => throw PlatformException(code: 'share_failed'),
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('net.nfet.printing'),
          null,
        ),
      );

      final store = FakeEntitlementStore();
      await pumpBuilderApp(
        tester,
        repository: FakeCvRepository([_fullProfile()]),
        entitlements: store,
        initialLocation: RouteNames.cvPreviewPath,
        loadDraftId: 'cv-1',
      );

      await tester.tap(
        find.widgetWithText(PrimaryButton, AppStrings.previewExport),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 800)),
      );
      await tester.pumpAndSettle();

      expect(store.saveCount, 0);
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });

  testWidgets('the draft survives opening the preview', (tester) async {
    final container = await pumpBuilderApp(
      tester,
      repository: FakeCvRepository([_fullProfile()]),
      initialLocation: RouteNames.cvPreviewPath,
      loadDraftId: 'cv-1',
    );

    expect(
      container.read(cvBuilderControllerProvider).draft.personalInfo.fullName,
      'Ayesha Rahman',
    );
  });
}
