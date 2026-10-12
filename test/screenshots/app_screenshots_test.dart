// Renders the key screens at 390×844 with the real brand fonts and writes PNGs
// to build/screenshots/ (gitignored) for visual review against docs/design/.
// It also guards against layout errors: any overflow or exception fails it.
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/features/auth/data/repositories/firebase_auth_repository_impl.dart';
import 'package:careermatebd/features/auth/presentation/screens/login_screen.dart';
import 'package:careermatebd/features/auth/presentation/screens/register_screen.dart';
import 'package:careermatebd/features/cv_builder/data/repositories/cv_repository_impl.dart';
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
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_flow.dart';
import 'package:careermatebd/features/cv_builder/presentation/screens/cv_builder_screen.dart';
import 'package:careermatebd/features/cv_builder/presentation/screens/cv_preview_screen.dart';
import 'package:careermatebd/features/cv_builder/presentation/screens/cv_template_screen.dart';
import 'package:careermatebd/features/home/presentation/screens/home_screen.dart';
import 'package:careermatebd/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:careermatebd/features/splash/presentation/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_auth_repository.dart';
import '../helpers/fake_cv_repository.dart';
import '../helpers/screenshot_harness.dart';

/// A CV shaped like the design mocks. [blankPersonal] leaves the personal form
/// empty (as in the Personal design); otherwise every section is filled so the
/// Summary page shows its "all done" banner.
CvProfile _designCv({
  bool blankPersonal = false,
  bool withTraining = true,
  bool withLanguages = true,
  String id = 'cv-frontend',
  String title = 'Frontend Developer CV',
  CvTemplate template = CvTemplate.modern,
  DateTime? updatedAt,
}) {
  return CvProfile.empty().copyWith(
    id: id,
    title: title,
    template: template,
    updatedAt: updatedAt ?? DateTime.now().subtract(const Duration(days: 2)),
    personalInfo: blankPersonal
        ? const PersonalInfo()
        : const PersonalInfo(
            fullName: 'Ayesha Rahman',
            desiredRole: 'Frontend Developer',
            email: 'ayesha@email.com',
            phone: '01712345678',
            address: 'Dhaka, BD',
            linkedInUrl: 'https://linkedin.com/in/ayesha',
          ),
    professionalSummary:
        'Front-end developer building accessible, performant React '
        'interfaces. Comfortable owning features end to end and working in '
        'Agile teams.',
    education: [
      EducationInfo.empty(id: 'ed1').copyWith(
        degree: 'BSc in Computer Science',
        institution: blankPersonal ? '' : 'Dhaka University',
        startYear: '2018',
        endYear: '2022',
      ),
    ],
    experiences: [
      ExperienceInfo.empty(id: 'ex1').copyWith(
        jobTitle: 'Frontend Developer',
        companyName: 'Acme Ltd.',
        startDate: '2022',
        isCurrentRole: true,
        highlights: const [
          'Built responsive React interfaces used by thousands of users.',
          'Collaborated with designers to ship new features each sprint.',
        ],
      ),
      ExperienceInfo.empty(id: 'ex2').copyWith(
        jobTitle: 'Junior Developer',
        companyName: 'Beta Soft',
        startDate: '2020',
        endDate: '2022',
        highlights: const ['Maintained the web app and fixed bugs.'],
      ),
    ],
    skills: [
      for (final (index, name) in [
        'React',
        'JavaScript',
        'Git',
        'TypeScript',
      ].indexed)
        SkillInfo.empty(id: 's$index').copyWith(name: name),
    ],
    projects: [
      ProjectInfo.empty(id: 'p1').copyWith(
        title: 'Expense Tracker App',
        technologies: const ['React', 'Firebase'],
        description:
            '• Personal finance app with charts and budgets.\n'
            '• Built the full React front end and Firebase backend.',
      ),
    ],
    trainings: withTraining
        ? [
            TrainingInfo.empty(id: 't1').copyWith(
              title: 'Flutter bootcamp',
              organization: 'Code Academy',
              completionYear: '2024',
            ),
          ]
        : const [],
    languages: withLanguages
        ? [
            LanguageInfo.empty(
              id: 'l1',
            ).copyWith(name: 'Bangla', proficiency: 'Native'),
            LanguageInfo.empty(
              id: 'l2',
            ).copyWith(name: 'English', proficiency: 'Fluent'),
          ]
        : const [],
  );
}

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
              _designCv(),
              _designCv(
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
          _designCv(blankPersonal: page == CvBuilderPage.personal),
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
      final container = await _containerWith(_designCv());
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
        _designCv(withTraining: false, withLanguages: false),
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
      final container = await _containerWith(_designCv());
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
}
