import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/qa_harness.dart';
import '../support/qa_seed.dart';

void registerProfileNavFlow() {
  qaTest(
    'profile: plan badge, Go Pro, language, theme, legal, settings, logout',
    (tester) async {
      await launchSignedIn(tester);
      await tapText(tester, 'Profile');
      await waitFor(tester, find.text(AppStrings.goProTitle));
      await shot(tester, 'profile', 'profile-top');
      expect(
        find.text(AppStrings.planFree),
        findsOneWidget,
        reason: 'plan badge',
      );
      expect(find.text(AppStrings.goProTitle), findsOneWidget);

      // Go Pro → paywall → close.
      await tapText(tester, AppStrings.goProCta);
      await waitFor(tester, find.text(AppStrings.paywallTitle));
      await shot(tester, 'profile', 'paywall-from-profile');
      await tapOn(tester, find.bySemanticsLabel(AppStrings.paywallClose));
      await waitGone(tester, find.text(AppStrings.paywallTitle));

      // Language sheet → Bangla.
      await tapText(tester, AppStrings.profileAppLanguage);
      await waitFor(tester, find.text(AppStrings.profileLanguageNote));
      await shot(tester, 'profile', 'language-sheet');
      await tapText(tester, 'Bangla');
      await waitFor(tester, find.text('Language preference saved.'));
      await shot(tester, 'profile', 'language-saved');
      await pumpFor(tester, const Duration(seconds: 4));

      // Theme: Dark / Auto are "coming soon".
      await tapText(tester, AppStrings.themeDark);
      await tapText(tester, AppStrings.themeAuto);
      await shot(tester, 'profile', 'theme-dark-auto-coming-soon');
      await tapText(tester, AppStrings.themeLight);

      // Scroll to the lower groups.
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -900));
      await pumpFor(tester, const Duration(milliseconds: 500));
      await shot(tester, 'profile', 'profile-bottom');
      await tapText(tester, AppStrings.paywallRestore);
      expect(
        find.byType(AlertDialog),
        findsNothing,
        reason: 'Restore is disabled',
      );
      await tapText(tester, AppStrings.profilePrivacyTerms);
      await waitFor(tester, find.byType(AlertDialog));
      await shot(tester, 'profile', 'privacy-terms');
      await tapText(tester, AppStrings.legalClose);

      // More settings → back.
      await tapText(tester, AppStrings.profileMoreSettings);
      await waitFor(tester, find.text(AppStrings.settings));
      await shot(tester, 'profile', 'settings-top');
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -1200));
      await pumpFor(tester, const Duration(milliseconds: 500));
      await shot(tester, 'profile', 'settings-bottom');
      await goBack(tester);
      await waitGone(tester, find.text(AppStrings.settings));

      // Log out asks first.
      await tapText(tester, AppStrings.profileLogOut);
      await waitFor(tester, find.text(AppStrings.logOutBody));
      await shot(tester, 'profile', 'logout-dialog');
      await tapText(tester, AppStrings.logOutCancel);
      expect(find.text(AppStrings.profileLogOut), findsOneWidget);
      await tapText(tester, AppStrings.profileLogOut);
      await tapOn(
        tester,
        find.widgetWithText(FilledButton, AppStrings.profileLogOut),
      );
      await pumpFor(tester, const Duration(seconds: 2));
      await shot(tester, 'profile', 'after-logout');
    },
  );

  qaTest('guest: onboarding "Get started" → Home → Profile as guest', (
    tester,
  ) async {
    await launchApp(tester);
    await waitFor(tester, find.text(AppStrings.onboardingGetStarted));
    await tapText(tester, AppStrings.onboardingGetStarted);
    await waitFor(tester, find.text(AppStrings.homeTitle));
    await shot(tester, 'guest', 'home-guest');
    await tapText(tester, 'Profile');
    await waitFor(tester, find.text(AppStrings.profileGuest));
    await shot(tester, 'guest', 'profile-guest');
    expect(find.text(AppStrings.profileLogOut), findsNothing);
    await tapText(tester, AppStrings.profileLogIn);
    await waitFor(tester, find.text(AppStrings.loginTitle));
    await tapText(tester, AppStrings.loginForgot);
    await waitFor(tester, find.text('Back to login'));
    await shot(tester, 'guest', 'forgot-password');
    await typeInto(
      tester,
      find.byType(TextFormField).first,
      'qa-forgot@example.com',
    );
    await tapText(tester, 'Send reset link');
    await pumpFor(tester, const Duration(seconds: 2));
    await shot(tester, 'guest', 'forgot-password-sent');
  });

  qaTest('navigation: every bottom-nav tab and back button', (tester) async {
    await launchSignedIn(tester);
    await seedCv(tester, nurseCv());
    await shot(tester, 'nav', 'home');

    // CVs (pushed) → back to Home.
    await tapText(tester, 'CVs');
    await waitFor(tester, find.text('Edit saved CV'));
    await shot(tester, 'nav', 'cvs-tab');
    await goBack(tester);
    await waitFor(tester, find.text(AppStrings.homeTitle));

    // Tailor (pushed) → back.
    await tapText(tester, 'Tailor');
    await waitFor(tester, find.text(AppStrings.tailorStepPill(1)));
    await shot(tester, 'nav', 'tailor-tab');
    await goBack(tester);
    await waitFor(tester, find.text(AppStrings.homeTitle));

    // Tracker and Profile are tabs: switching replaces.
    await tapText(tester, 'Tracker');
    await waitFor(tester, find.text(AppStrings.trackerEmptyTitle));
    await shot(tester, 'nav', 'tracker-tab');
    await tapText(tester, 'Profile');
    await waitFor(tester, find.text(AppStrings.goProTitle));
    await shot(tester, 'nav', 'profile-tab');
    await tapText(tester, 'Home');
    await waitFor(tester, find.text(AppStrings.homeTitle));

    // Tracker → CVs → back stays on Tracker.
    await tapText(tester, 'Tracker');
    await waitFor(tester, find.text(AppStrings.trackerEmptyTitle));
    await tapText(tester, 'CVs');
    await waitFor(tester, find.text('Edit saved CV'));
    await goBack(tester);
    await waitFor(tester, find.text(AppStrings.trackerEmptyTitle));
    await tapText(tester, 'Home');
    await waitFor(tester, find.text(AppStrings.homeTitle));

    // Home quick actions: Create CV, Improve CV (AI), each with a back button.
    for (final action in [
      AppStrings.actionCreateCv,
      AppStrings.actionImproveCv,
    ]) {
      await tapText(tester, action, settle: const Duration(seconds: 1));
      await pumpFor(tester, const Duration(seconds: 1));
      await shot(
        tester,
        'nav',
        'quick-${action.toLowerCase().replaceAll(' ', '-')}',
      );
      await goBack(tester);
      await waitFor(tester, find.text(AppStrings.homeTitle));
    }

    // Tapping a CV on Home opens its preview; Home "Start tailoring" works.
    await tapText(tester, 'Staff Nurse CV');
    await waitFor(tester, find.text(AppStrings.previewExport));
    await shot(tester, 'nav', 'home-cv-opens-preview');
    await goBack(tester);
    await waitFor(tester, find.text(AppStrings.homeTitle));
    await tapText(tester, AppStrings.homeHeroCta);
    await waitFor(tester, find.text(AppStrings.tailorStepPill(1)));
    await goBack(tester);
    await waitFor(tester, find.text(AppStrings.homeTitle));
    await shot(tester, 'nav', 'home-with-cv');
  });
}
