import 'dart:async';
import 'dart:io';

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
import 'package:careermatebd/features/cv_builder/presentation/widgets/cv_pdf_pages_view.dart';
import 'package:careermatebd/shared/services/entitlement/entitlement_record.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/builder_harness.dart';
import '../../../../helpers/fake_cv_repository.dart';
import '../../../../helpers/poppler.dart';
import '../../../../helpers/preview_pages.dart';
import '../../../../helpers/screenshot_harness.dart';

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

/// Stands in for the native side of the `printing` plugin. Records every call
/// from Dart; when [completePrint] is true it also plays the native part of a
/// print job (asks Dart for the PDF, then reports the job as completed).
void _mockPrintingPlugin(
  WidgetTester tester,
  List<MethodCall> calls, {
  bool completePrint = true,
}) {
  const channel = MethodChannel('net.nfet.printing');
  const codec = StandardMethodCodec();

  Future<void> hostCall(String method, Map<String, Object?> args) {
    final done = Completer<void>();
    tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      channel.name,
      codec.encodeMethodCall(MethodCall(method, args)),
      (_) => done.complete(),
    );
    return done.future;
  }

  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
    call,
  ) async {
    calls.add(call);
    if (call.method == 'printPdf' && completePrint) {
      final job = (call.arguments as Map)['job'];
      unawaited(
        Future<void>(() async {
          await hostCall('onLayout', {
            'job': job,
            'width': 595.0,
            'height': 842.0,
            'marginLeft': 0.0,
            'marginTop': 0.0,
            'marginRight': 0.0,
            'marginBottom': 0.0,
          });
          await hostCall('onCompleted', {'job': job, 'completed': true});
        }),
      );
    }
    return 1;
  });
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      null,
    ),
  );
}

/// The selectable text of [pdf], as a viewer or an ATS reads it.
String _pdfText(Uint8List pdf) {
  final dir = Directory.systemTemp.createTempSync('cv_preview_text');
  addTearDown(() => dir.deleteSync(recursive: true));
  return Poppler.text(File('${dir.path}/cv.pdf')..writeAsBytesSync(pdf));
}

Future<void> _openMenu(WidgetTester tester) async {
  await tester.tap(find.byTooltip(AppStrings.previewMoreOptions));
  await tester.pumpAndSettle();
}

/// Lets real async work (PDF generation) finish.
Future<void> _letRealAsyncRun(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 800)),
  );
  await tester.pumpAndSettle();
}

void main() {
  // The preview's PDF is built on real async work; the app fonts must load
  // from test/fonts meanwhile, not from the network.
  setUpAll(loadTestFonts);

  group('paper preview', () {
    testWidgets(
      'shows the pages of the PDF that Export builds',
      skip: !Poppler.canRaster,
      (tester) async {
        final container = await pumpBuilderApp(
          tester,
          repository: FakeCvRepository([_fullProfile()]),
          initialLocation: RouteNames.cvPreviewPath,
          loadDraftId: 'cv-1',
        );
        final preview = await waitForPreviewPages(tester, container);

        final shown = shownPreviewPages(tester);
        expect(shown, isNotEmpty);
        expect(shown, preview.pages, reason: 'every page is on screen');
        expect(
          find.bySemanticsLabel(AppStrings.previewPageLabel(1, shown.length)),
          findsOneWidget,
        );

        final text = _pdfText(preview.pdf);
        expect(text, contains('Ayesha Rahman'));
        expect(text, contains('Frontend Developer'));
        for (final title in [
          'Summary',
          'Objective',
          'Experience',
          'Skills',
          'Education',
          'Projects',
          'Training',
          'Languages',
        ]) {
          expect(text, contains(title), reason: title);
        }
        expect(text, contains('Rebuilt key screens'));
      },
    );

    testWidgets(
      'the PDF in the preview leaves out sections that have no content',
      skip: !Poppler.canRaster,
      (tester) async {
        final container = await pumpBuilderApp(
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
        final preview = await waitForPreviewPages(tester, container);

        final text = _pdfText(preview.pdf).toLowerCase();
        expect(text, contains('ayesha rahman'));
        for (final title in ['summary', 'experience', 'skills', 'education']) {
          expect(text, isNot(contains(title)), reason: title);
        }
      },
    );

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
        const EntitlementRecord(freeExportsUsed: 1),
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

  group('review warnings', () {
    Finder summary(int n) => find.text(AppStrings.previewWarningsSummary(n));

    testWidgets('are hidden when there is nothing to fix', (tester) async {
      await pumpBuilderApp(
        tester,
        repository: FakeCvRepository([_fullProfile()]),
        initialLocation: RouteNames.cvPreviewPath,
        loadDraftId: 'cv-1',
      );

      expect(find.textContaining('to fix'), findsNothing);
    });

    testWidgets('show one compact line above the paper that expands', (
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

      // Collapsed: just the count, above the paper.
      expect(summary(4), findsOneWidget);
      expect(find.textContaining('No experience added yet'), findsNothing);
      expect(
        tester.getTopLeft(summary(4)).dy,
        lessThan(tester.getTopLeft(find.byType(CvPdfPagesView)).dy),
      );

      // Tap to expand into the list.
      await tester.tap(summary(4));
      await tester.pumpAndSettle();
      expect(find.textContaining('No experience added yet'), findsOneWidget);
      expect(find.textContaining('Projects are empty'), findsOneWidget);
      expect(
        find.textContaining('No training or certifications'),
        findsOneWidget,
      );
      expect(find.textContaining('Languages are empty'), findsOneWidget);

      // Tap again to collapse.
      await tester.tap(summary(4));
      await tester.pumpAndSettle();
      expect(find.textContaining('No experience added yet'), findsNothing);
    });

    testWidgets('use the singular for a single note', (tester) async {
      await pumpBuilderApp(
        tester,
        repository: FakeCvRepository([
          _fullProfile().copyWith(languages: const []),
        ]),
        initialLocation: RouteNames.cvPreviewPath,
        loadDraftId: 'cv-1',
      );

      expect(summary(1), findsOneWidget);
      expect(find.text('1 thing to fix'), findsOneWidget);
    });

    testWidgets('the line is a 48dp-high button', (tester) async {
      await pumpBuilderApp(
        tester,
        repository: FakeCvRepository([
          _fullProfile().copyWith(languages: const []),
        ]),
        initialLocation: RouteNames.cvPreviewPath,
        loadDraftId: 'cv-1',
      );

      final row = find.ancestor(of: summary(1), matching: find.byType(InkWell));
      expect(tester.getSize(row.first).height, greaterThanOrEqualTo(48));
    });
  });

  group('print (⋮ menu)', () {
    testWidgets('the top bar has a ⋮ menu with Print', (tester) async {
      await pumpBuilderApp(
        tester,
        repository: FakeCvRepository([_fullProfile()]),
        initialLocation: RouteNames.cvPreviewPath,
        loadDraftId: 'cv-1',
      );

      expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);
      expect(find.text(AppStrings.previewPrint), findsNothing);

      await _openMenu(tester);
      expect(find.text(AppStrings.previewPrint), findsOneWidget);
    });

    testWidgets('after the free export is used, Print opens the paywall', (
      tester,
    ) async {
      final calls = <MethodCall>[];
      _mockPrintingPlugin(tester, calls);
      final store = FakeEntitlementStore(
        const EntitlementRecord(freeExportsUsed: 1),
      );
      await pumpBuilderApp(
        tester,
        repository: FakeCvRepository([_fullProfile()]),
        entitlements: store,
        initialLocation: RouteNames.cvPreviewPath,
        loadDraftId: 'cv-1',
      );

      await _openMenu(tester);
      await tester.tap(find.text(AppStrings.previewPrint));
      await tester.pumpAndSettle();

      expect(find.text(paywallPlaceholder), findsOneWidget);
      expect(calls, isEmpty, reason: 'nothing was sent to the printer');
      expect(store.saveCount, 0);
    });

    testWidgets('the first print is free: it prints the PDF and is recorded', (
      tester,
    ) async {
      final calls = <MethodCall>[];
      _mockPrintingPlugin(tester, calls);
      final store = FakeEntitlementStore();
      await pumpBuilderApp(
        tester,
        repository: FakeCvRepository([_fullProfile()]),
        entitlements: store,
        initialLocation: RouteNames.cvPreviewPath,
        loadDraftId: 'cv-1',
      );

      await _openMenu(tester);
      await tester.tap(find.text(AppStrings.previewPrint));
      await _letRealAsyncRun(tester);

      final print = calls.where((call) => call.method == 'printPdf').single;
      expect((print.arguments as Map)['name'] as String, endsWith('.pdf'));
      expect(store.saveCount, 1, reason: 'the free export was recorded');
      expect(store.record.freeExportsUsed, 1);
      expect(find.text(paywallPlaceholder), findsNothing);
    });

    testWidgets('a print that never completes is not counted as an export', (
      tester,
    ) async {
      final calls = <MethodCall>[];
      _mockPrintingPlugin(tester, calls, completePrint: false);
      final store = FakeEntitlementStore();
      await pumpBuilderApp(
        tester,
        repository: FakeCvRepository([_fullProfile()]),
        entitlements: store,
        initialLocation: RouteNames.cvPreviewPath,
        loadDraftId: 'cv-1',
      );

      await _openMenu(tester);
      await tester.tap(find.text(AppStrings.previewPrint));
      await _letRealAsyncRun(tester);

      expect(calls.any((call) => call.method == 'printPdf'), isTrue);
      expect(
        store.saveCount,
        0,
        reason: 'only recorded once the job completes',
      );
    });

    testWidgets('Print is disabled while the CV is empty', (tester) async {
      await pumpBuilderApp(
        tester,
        repository: FakeCvRepository([CvProfile.empty().copyWith(id: 'cv-1')]),
        initialLocation: RouteNames.cvPreviewPath,
        loadDraftId: 'cv-1',
      );

      await _openMenu(tester);

      expect(
        find.ancestor(
          of: find.text(AppStrings.previewPrint),
          matching: find.byWidgetPredicate(
            (widget) => widget is PopupMenuItem && !widget.enabled,
          ),
        ),
        findsOneWidget,
      );
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
