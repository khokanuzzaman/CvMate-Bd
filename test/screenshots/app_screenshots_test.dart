// Renders the key screens at 390×844 with the real brand fonts and writes PNGs
// to build/screenshots/ (gitignored) for visual review against docs/design/.
// It also guards against layout errors: any overflow or exception fails it.
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/features/auth/data/repositories/firebase_auth_repository_impl.dart';
import 'package:careermatebd/features/auth/presentation/screens/login_screen.dart';
import 'package:careermatebd/features/auth/presentation/screens/register_screen.dart';
import 'package:careermatebd/features/cv_builder/data/repositories/cv_repository_impl.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_template.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_flow.dart';
import 'package:careermatebd/features/cv_builder/presentation/screens/cv_builder_screen.dart';
import 'package:careermatebd/features/cv_builder/presentation/screens/cv_preview_screen.dart';
import 'package:careermatebd/features/cv_builder/presentation/screens/cv_template_screen.dart';
import 'package:careermatebd/features/ats_checker/presentation/screens/ats_checker_screen.dart';
import 'package:careermatebd/features/cover_letter/data/repositories/cover_letter_repository_impl.dart';
import 'package:careermatebd/features/cover_letter/presentation/controllers/cover_letter_controller.dart';
import 'package:careermatebd/features/cover_letter/presentation/screens/cover_letter_screen.dart';
import 'package:careermatebd/features/home/presentation/screens/home_screen.dart';
import 'package:careermatebd/features/interview_prep/data/repositories/interview_prep_session_repository_impl.dart';
import 'package:careermatebd/features/interview_prep/presentation/screens/interview_prep_screen.dart';
import 'package:careermatebd/features/job_tracker/data/repositories/job_application_repository_impl.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_application.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_application_status.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_source.dart';
import 'package:careermatebd/features/job_tracker/presentation/screens/job_application_details_screen.dart';
import 'package:careermatebd/features/job_tracker/presentation/screens/job_application_form_screen.dart';
import 'package:careermatebd/features/job_tracker/presentation/screens/job_tracker_screen.dart';
import 'package:careermatebd/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:careermatebd/features/splash/presentation/screens/splash_screen.dart';
import 'package:careermatebd/features/subscription/presentation/screens/paywall_screen.dart';
import 'package:careermatebd/features/tailoring/presentation/screens/tailoring_screen.dart';
import 'package:careermatebd/shared/services/ai/mock_ai_career_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_auth_repository.dart';
import '../helpers/core_flow_harness.dart';
import '../helpers/design_cv.dart';
import '../helpers/fake_ai_career_service.dart';
import '../helpers/fake_cv_repository.dart';
import '../helpers/screenshot_harness.dart';

Future<ProviderContainer> _containerWith(CvProfile profile) async {
  final container = ProviderContainer(
    overrides: [
      cvRepositoryProvider.overrideWithValue(FakeCvRepository([profile])),
    ],
  );
  addTearDown(container.dispose);
  await container
      .read(cvBuilderControllerProvider.notifier)
      .loadDraft(profile.id);
  return container;
}

void main() {
  setUpAll(loadTestFonts);

  Future<void> expectCaptured(
    WidgetTester tester,
    GlobalKey key,
    String name,
  ) async {
    expect(tester.takeException(), isNull, reason: '$name rendered an error');
    final file = await saveScreenshot(tester, key, name);
    final size = pngSize(file);
    expect(size.width, 390 * 2, reason: name);
    expect(size.height, 844 * 2, reason: name);
    expect(file.lengthSync(), greaterThan(5000), reason: '$name looks blank');
  }

  test('the brand fonts are really loaded (not the placeholder font)', () {
    // The test placeholder font is monospaced-wide: "Ready to apply?" at 26px
    // would be 15 × 26 = 390px. Sora Bold is far narrower.
    final painter = TextPainter(
      text: TextSpan(text: 'Ready to apply?', style: AppTextStyles.h1),
      textDirection: TextDirection.ltr,
    )..layout();
    expect(painter.width, inInclusiveRange(150, 280));
  });

  test('৳ and Bangla text use the bundled Bengali font, not boxes', () {
    double width(String text, {bool fallback = true}) {
      final style = fallback
          ? AppTextStyles.body
          : AppTextStyles.body.copyWith(fontFamilyFallback: const <String>[]);
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      return painter.width;
    }

    // Without the fallback these glyphs are missing and drawn as one narrow
    // placeholder each; with it they get real Bengali glyph widths.
    expect(width('৳'), isNot(width('৳', fallback: false)));
    expect(width('বাংলা'), isNot(width('বাংলা', fallback: false)));
  });

  group('home + auth', () {
    testWidgets('home', (tester) async {
      useScreenshotSurface(tester);
      final auth = FakeAuthRepository();
      addTearDown(auth.dispose);
      await auth.signInWithEmailAndPassword(
        email: 'khokan@example.com',
        password: 'secret12',
      );
      final key = GlobalKey();

      await pumpScreenshotScreen(
        tester,
        key,
        const HomeScreen(),
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          cvRepositoryProvider.overrideWithValue(
            FakeCvRepository([
              designCv(),
              designCv(
                id: 'cv-designer',
                title: 'Product Designer CV',
                template: CvTemplate.professional,
                updatedAt: DateTime.now().subtract(const Duration(days: 9)),
              ),
            ]),
          ),
        ],
      );
      await expectCaptured(tester, key, '01_home');
    });

    testWidgets('splash', (tester) async {
      useScreenshotSurface(tester);
      final key = GlobalKey();
      await pumpScreenshotScreen(tester, key, const SplashScreen());
      await expectCaptured(tester, key, '02_splash');
    });

    testWidgets('onboarding', (tester) async {
      useScreenshotSurface(tester);
      final key = GlobalKey();
      await pumpScreenshotScreen(tester, key, const OnboardingScreen());
      await expectCaptured(tester, key, '03_onboarding');
    });

    testWidgets('login', (tester) async {
      useScreenshotSurface(tester);
      final auth = FakeAuthRepository();
      addTearDown(auth.dispose);
      final key = GlobalKey();
      await pumpScreenshotScreen(
        tester,
        key,
        const LoginScreen(),
        overrides: [authRepositoryProvider.overrideWithValue(auth)],
      );
      await expectCaptured(tester, key, '04_login');
    });

    testWidgets('register', (tester) async {
      useScreenshotSurface(tester);
      final auth = FakeAuthRepository();
      addTearDown(auth.dispose);
      final key = GlobalKey();
      await pumpScreenshotScreen(
        tester,
        key,
        const RegisterScreen(),
        overrides: [authRepositoryProvider.overrideWithValue(auth)],
      );
      await expectCaptured(tester, key, '05_register');
    });
  });

  group('cv builder steps', () {
    for (final (index, page) in CvBuilderFlow.pages.indexed) {
      testWidgets('step ${index + 1}: ${page.name}', (tester) async {
        useScreenshotSurface(tester);
        // The Personal design shows an empty form; every other page shows data.
        final container = await _containerWith(
          designCv(blankPersonal: page == CvBuilderPage.personal),
        );
        container
            .read(cvBuilderControllerProvider.notifier)
            .goToStep(page.entryStep.index);
        final key = GlobalKey();

        await pumpScreenshotScreen(
          tester,
          key,
          const CvBuilderScreen(),
          container: container,
        );
        await expectCaptured(
          tester,
          key,
          '${(index + 6).toString().padLeft(2, '0')}_builder_${index + 1}_${page.name}',
        );
      });
    }
  });

  group('preview', () {
    testWidgets('preview', (tester) async {
      useScreenshotSurface(tester);
      final container = await _containerWith(designCv());
      final key = GlobalKey();

      await pumpScreenshotScreen(
        tester,
        key,
        const CvPreviewScreen(),
        container: container,
      );
      await expectCaptured(tester, key, '13_preview');
    });

    testWidgets('preview with review notes expanded', (tester) async {
      useScreenshotSurface(tester);
      final container = await _containerWith(
        designCv(withTraining: false, withLanguages: false),
      );
      final key = GlobalKey();

      await pumpScreenshotScreen(
        tester,
        key,
        const CvPreviewScreen(),
        container: container,
      );
      await tester.tap(find.text('2 things to fix'));
      await tester.pumpAndSettle();
      await expectCaptured(tester, key, '14_preview_notes');
    });

    testWidgets('template picker', (tester) async {
      useScreenshotSurface(tester);
      final container = await _containerWith(designCv());
      final key = GlobalKey();

      await pumpScreenshotScreen(
        tester,
        key,
        const CvTemplateScreen(),
        container: container,
      );
      await expectCaptured(tester, key, '15_template_picker');
    });
  });
  group('tailoring, cover letter, paywall', () {
    const jobPost =
        'We are hiring a Frontend Developer to build accessible, performant '
        'interfaces with React, JavaScript, TypeScript, Next.js, REST API and '
        'Git. Experience with CI/CD, design systems and Agile teams is a plus.';

    List<Override> overrides(FakeAiCareerService ai) => [
      cvRepositoryProvider.overrideWithValue(FakeCvRepository([designCv()])),
      aiCareerServiceProvider.overrideWithValue(ai),
      coverLetterRepositoryProvider.overrideWithValue(
        FakeCoverLetterRepository(),
      ),
    ];

    Future<GlobalKey> openTailoring(
      WidgetTester tester,
      FakeAiCareerService ai,
    ) async {
      useScreenshotSurface(tester);
      final key = GlobalKey();
      await pumpScreenshotScreen(
        tester,
        key,
        const TailoringScreen(),
        overrides: overrides(ai),
      );
      return key;
    }

    Future<void> tapText(WidgetTester tester, String text) async {
      await tester.tap(find.text(text));
      await tester.pumpAndSettle();
    }

    testWidgets('tailor 1: paste the job post', (tester) async {
      final key = await openTailoring(tester, FakeAiCareerService());
      await expectCaptured(tester, key, '16_tailor_1_paste');
    });

    testWidgets('tailor 2: match results', (tester) async {
      final key = await openTailoring(tester, FakeAiCareerService());
      await tester.enterText(find.byType(TextField).first, jobPost);
      await tester.pumpAndSettle();
      await tapText(tester, AppStrings.tailorAnalyze);
      await expectCaptured(tester, key, '17_tailor_2_match');
    });

    testWidgets('tailor 3: your tailored CV', (tester) async {
      final key = await openTailoring(tester, FakeAiCareerService());
      await tester.enterText(find.byType(TextField).first, jobPost);
      await tester.pumpAndSettle();
      await tapText(tester, AppStrings.tailorAnalyze);
      await tapText(tester, AppStrings.tailorTailorMyCv);
      await expectCaptured(tester, key, '18_tailor_3_result');
    });

    testWidgets('cover letter', (tester) async {
      useScreenshotSurface(tester);
      final ai = FakeAiCareerService();
      final key = GlobalKey();
      final container = ProviderContainer(overrides: overrides(ai));
      addTearDown(container.dispose);
      final letters = container.read(coverLetterControllerProvider.notifier);
      await letters.initialize();
      letters
        ..selectCv('cv-frontend')
        ..updateTargetCompany('Acme')
        ..updateJobTitle('Frontend Developer')
        ..updateJobDetails(jobPost);
      await letters.generateContent();

      await pumpScreenshotScreen(
        tester,
        key,
        const CoverLetterScreen(),
        container: container,
      );
      await expectCaptured(tester, key, '19_cover_letter');
    });

    testWidgets('paywall', (tester) async {
      useScreenshotSurface(tester);
      final key = GlobalKey();
      await pumpScreenshotScreen(
        tester,
        key,
        const PaywallScreen(source: 'screenshot'),
      );
      await expectCaptured(tester, key, '20_paywall');
    });
  });
  group('ats, interview prep, job tracker', () {
    const jobPost =
        'We are hiring a Frontend Developer to build accessible, performant '
        'interfaces with React, JavaScript, TypeScript, Next.js, REST API and '
        'Git. Experience with CI/CD, design systems and Agile teams is a plus.';

    final jobs = FakeJobApplicationRepository([
      JobApplication.empty().copyWith(
        id: 'j1',
        companyName: 'Acme Ltd.',
        jobTitle: 'Frontend Developer',
        jobSource: JobSource.linkedIn,
        status: JobApplicationStatus.interview,
        appliedDate: DateTime(2026, 9, 12),
        interviewDate: DateTime(2026, 10, 20),
        followUpDate: DateTime(2026, 10, 1),
        cvId: 'cv-frontend',
        notes: 'Second round with the design lead. Bring the case study.',
        createdAt: DateTime(2026, 9, 12),
        updatedAt: DateTime(2026, 10, 3),
      ),
      JobApplication.empty().copyWith(
        id: 'j2',
        companyName: 'BRAC Bank',
        jobTitle: 'Management Trainee',
        jobSource: JobSource.bdjobs,
        status: JobApplicationStatus.applied,
        appliedDate: DateTime(2026, 9, 28),
        createdAt: DateTime(2026, 9, 28),
        updatedAt: DateTime(2026, 9, 29),
      ),
      JobApplication.empty().copyWith(
        id: 'j3',
        companyName: 'Beta Soft',
        jobTitle: 'UI Engineer',
        jobSource: JobSource.reference,
        status: JobApplicationStatus.offered,
        appliedDate: DateTime(2026, 8, 30),
        createdAt: DateTime(2026, 8, 30),
        updatedAt: DateTime(2026, 9, 20),
      ),
    ]);

    List<Override> overrides(FakeAiCareerService ai) => [
      cvRepositoryProvider.overrideWithValue(FakeCvRepository([designCv()])),
      aiCareerServiceProvider.overrideWithValue(ai),
      coverLetterRepositoryProvider.overrideWithValue(
        FakeCoverLetterRepository(),
      ),
      interviewPrepSessionRepositoryProvider.overrideWithValue(
        FakeInterviewSessionRepository(),
      ),
      jobApplicationRepositoryProvider.overrideWithValue(jobs),
    ];

    Future<GlobalKey> open(WidgetTester tester, Widget screen) async {
      useScreenshotSurface(tester);
      final key = GlobalKey();
      await pumpScreenshotScreen(
        tester,
        key,
        screen,
        overrides: overrides(FakeAiCareerService()),
      );
      return key;
    }

    testWidgets('ats checker', (tester) async {
      final key = await open(tester, const AtsCheckerScreen());
      await expectCaptured(tester, key, '21_ats_checker');
    });

    testWidgets('ats checker job match', (tester) async {
      final key = await open(tester, const AtsCheckerScreen());
      await tester.enterText(find.byType(TextField).first, jobPost);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(AppStrings.atsCheckMatch));
      await tester.tap(find.text(AppStrings.atsCheckMatch));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.text(AppStrings.atsMissing.toUpperCase()),
      );
      await tester.pumpAndSettle();
      await expectCaptured(tester, key, '22_ats_job_match');
    });

    testWidgets('interview prep', (tester) async {
      final key = await open(tester, const InterviewPrepScreen());
      await expectCaptured(tester, key, '23_interview_prep');
    });

    testWidgets('interview prep results', (tester) async {
      final key = await open(tester, const InterviewPrepScreen());
      final generate = find.text(AppStrings.interviewGenerate);
      await tester.ensureVisible(generate);
      await tester.tap(generate);
      await tester.pumpAndSettle();
      final question = find.text('How do you keep a React app fast?');
      await tester.ensureVisible(question);
      await tester.tap(question);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(AppStrings.interviewAnswerLabel));
      await tester.pumpAndSettle();
      await expectCaptured(tester, key, '24_interview_results');
    });

    testWidgets('job tracker', (tester) async {
      final key = await open(tester, const JobTrackerScreen());
      await expectCaptured(tester, key, '25_job_tracker');
    });

    testWidgets('job application form', (tester) async {
      final key = await open(
        tester,
        const JobApplicationFormScreen(applicationId: 'j1'),
      );
      await expectCaptured(tester, key, '26_job_form');
    });

    testWidgets('job application details', (tester) async {
      final key = await open(
        tester,
        const JobApplicationDetailsScreen(applicationId: 'j1'),
      );
      await expectCaptured(tester, key, '27_job_details');
    });
  });
}
