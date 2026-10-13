import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/qa_harness.dart';

Finder get _createButton =>
    find.widgetWithText(PrimaryButton, AppStrings.createAccount);
Finder get _logInButton =>
    find.widgetWithText(PrimaryButton, AppStrings.authLogIn);

Future<void> _logOutFromProfile(WidgetTester tester) async {
  await tapText(tester, 'Profile');
  await waitFor(tester, find.text(AppStrings.goProTitle));
  await tapText(tester, AppStrings.profileLogOut);
  await tapOn(
    tester,
    find.widgetWithText(FilledButton, AppStrings.profileLogOut),
  );
}

void registerAuthFlow() {
  qaTest('auth: splash → onboarding → register (8-char rule) → home', (
    tester,
  ) async {
    await launchApp(tester);
    await shot(tester, 'auth', 'splash');

    await waitFor(tester, find.text(AppStrings.onboardingGetStarted));
    await shot(tester, 'auth', 'onboarding');

    // Onboarding → Log in → Create account (the only route to Register).
    await tapText(tester, AppStrings.authLogIn);
    await waitFor(tester, find.text(AppStrings.loginTitle));
    await shot(tester, 'auth', 'login-empty');
    await tapText(tester, AppStrings.createAccount);
    await waitFor(tester, find.text(AppStrings.registerHeadline));
    await shot(tester, 'auth', 'register-empty');

    final email = uniqueEmail('register');
    final fields = find.byType(TextFormField);
    await typeInto(tester, fields.at(0), 'Rahim Uddin');
    await typeInto(tester, fields.at(1), email);
    await typeInto(tester, fields.at(2), 'abcdefg'); // 7 chars
    await tapOn(tester, find.byType(Checkbox));
    await shot(tester, 'auth', 'register-7char-filled');
    await tapOn(tester, _createButton);
    expect(
      find.text('Password must be at least 8 characters.'),
      findsOneWidget,
      reason: '7-character password must be rejected on Register',
    );
    await shot(tester, 'auth', 'register-7char-rejected');

    await typeInto(tester, fields.at(2), 'Rahim123'); // 8 chars
    await tester.pump(const Duration(milliseconds: 200));
    await shot(tester, 'auth', 'register-8char-filled');
    await tapOn(tester, _createButton, settle: const Duration(seconds: 1));
    await waitFor(tester, find.text(AppStrings.homeTitle));
    await shot(tester, 'auth', 'home-after-register');

    // Onboarding shows once: a relaunch while signed in goes straight home.
    await launchApp(tester, freshInstall: false);
    await waitFor(tester, find.text(AppStrings.homeTitle));
    expect(find.text(AppStrings.onboardingGetStarted), findsNothing);
    await shot(tester, 'auth', 'relaunch-signed-in');
  });

  qaTest('auth: logout → login (6 chars ok, 5 rejected); onboarding once', (
    tester,
  ) async {
    // A 6-character-password account, made in the emulator only.
    final email = uniqueEmail('login');
    await resetAppState();
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: 'abc123',
    );
    await FirebaseAuth.instance.signOut();

    await launchApp(tester, freshInstall: false);
    await waitFor(tester, find.text(AppStrings.onboardingGetStarted));
    await tapText(tester, AppStrings.authLogIn);
    await waitFor(tester, find.text(AppStrings.loginTitle));

    final fields = find.byType(TextFormField);
    await typeInto(tester, fields.at(0), email);
    await typeInto(tester, fields.at(1), 'abc12'); // 5 chars
    await tapOn(tester, _logInButton);
    expect(
      find.text('Password must be at least 6 characters.'),
      findsOneWidget,
      reason: '5-character password must be rejected on Login',
    );
    await shot(tester, 'auth-login', 'login-5char-rejected');

    await typeInto(tester, fields.at(1), 'wrongpass');
    await tapOn(tester, _logInButton, settle: const Duration(seconds: 1));
    await waitFor(
      tester,
      find.byWidgetPredicate(
        (w) =>
            w is Text &&
            (w.data == 'Email or password is incorrect.' ||
                w.data == 'Incorrect password. Please try again.'),
      ),
      reason: 'wrong-password banner',
    );
    await shot(tester, 'auth-login', 'login-wrong-password');

    await typeInto(tester, fields.at(1), 'abc123'); // 6 chars
    await tapOn(tester, _logInButton, settle: const Duration(seconds: 1));
    await waitFor(tester, find.text(AppStrings.homeTitle));
    await shot(tester, 'auth-login', 'home-after-login');

    // Log out from Profile.
    await _logOutFromProfile(tester);
    await pumpFor(tester, const Duration(seconds: 1));
    await shot(tester, 'auth-login', 'after-logout');
    final landedOnOnboarding = find
        .text(AppStrings.onboardingGetStarted)
        .evaluate()
        .isNotEmpty;
    debugPrint(
      'QA-NOTE logout lands on: '
      '${landedOnOnboarding ? 'onboarding' : 'login'}',
    );

    // A cold relaunch after the user has seen onboarding must not show it.
    await launchApp(tester, freshInstall: false);
    await waitFor(tester, find.text(AppStrings.loginTitle));
    expect(find.text(AppStrings.onboardingGetStarted), findsNothing);
    await shot(tester, 'auth-login', 'relaunch-signed-out');
  });
}
