import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/core/widgets/social_auth_button.dart';
import 'package:careermatebd/features/auth/domain/password_strength.dart';
import 'package:careermatebd/features/auth/presentation/widgets/password_strength_meter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/auth_screen_harness.dart';
import '../../../../helpers/fake_auth_repository.dart';

Finder get _createButton =>
    find.widgetWithText(PrimaryButton, AppStrings.createAccount);

Future<void> _fillForm(
  WidgetTester tester, {
  String name = 'Rahim Uddin',
  String email = 'rahim@example.com',
  String password = 'Rahim123',
}) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), name);
  await tester.enterText(fields.at(1), email);
  await tester.enterText(fields.at(2), password);
}

PasswordStrength _meterStrength(WidgetTester tester) {
  return tester
      .widget<PasswordStrengthMeter>(find.byType(PasswordStrengthMeter))
      .strength;
}

void main() {
  late FakeAuthRepository repository;

  setUp(() {
    repository = FakeAuthRepository();
  });

  tearDown(() async {
    await repository.dispose();
  });

  testWidgets('renders the register design copy and controls', (tester) async {
    await pumpAuthScreen(
      tester,
      repository: repository,
      initialLocation: '/register',
    );

    expect(find.text(AppStrings.registerHeadline), findsOneWidget);
    expect(find.text(AppStrings.registerSubtitle), findsOneWidget);
    expect(find.text(AppStrings.registerNameLabel), findsOneWidget);
    expect(find.text(AppStrings.authEmailLabel), findsOneWidget);
    expect(find.text(AppStrings.authPasswordLabel), findsOneWidget);
    expect(find.byType(PasswordStrengthMeter), findsOneWidget);
    expect(find.byType(Checkbox), findsOneWidget);
    expect(_createButton, findsOneWidget);
    expect(find.text(AppStrings.authHaveAccount), findsOneWidget);
  });

  testWidgets('Google sign-up is shown disabled (not implemented yet)', (
    tester,
  ) async {
    await pumpAuthScreen(
      tester,
      repository: repository,
      initialLocation: '/register',
    );

    final button = tester.widget<SocialAuthButton>(
      find.byType(SocialAuthButton),
    );
    expect(button.label, AppStrings.registerGoogle);
    expect(button.onPressed, isNull);
  });

  testWidgets('strength meter follows the password being typed', (
    tester,
  ) async {
    await pumpAuthScreen(
      tester,
      repository: repository,
      initialLocation: '/register',
    );
    final password = find.byType(TextFormField).at(2);

    expect(_meterStrength(tester), PasswordStrength.empty);

    await tester.enterText(password, 'abc');
    await tester.pump();
    expect(_meterStrength(tester), PasswordStrength.weak);

    await tester.enterText(password, 'abcdefgh');
    await tester.pump();
    expect(_meterStrength(tester), PasswordStrength.fair);

    await tester.enterText(password, 'Rahim123');
    await tester.pump();
    expect(_meterStrength(tester), PasswordStrength.strong);
  });

  testWidgets('requires the terms checkbox before creating an account', (
    tester,
  ) async {
    await pumpAuthScreen(
      tester,
      repository: repository,
      initialLocation: '/register',
    );

    await _fillForm(tester);
    await tester.tap(_createButton);
    await tester.pump();

    expect(find.text(AppStrings.registerTermsRequired), findsOneWidget);
    expect(repository.createdEmails, isEmpty);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(find.text(AppStrings.registerTermsRequired), findsNothing);
  });

  testWidgets('validates name, email and an 8+ character password', (
    tester,
  ) async {
    await pumpAuthScreen(
      tester,
      repository: repository,
      initialLocation: '/register',
    );

    await _fillForm(tester, name: '', email: 'not-an-email', password: 'short');
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(_createButton);
    await tester.pump();

    expect(find.text('Full name is required.'), findsOneWidget);
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(
      find.text('Password must be at least 8 characters.'),
      findsOneWidget,
    );
    expect(repository.createdEmails, isEmpty);
  });

  testWidgets('a valid form with terms accepted creates the account', (
    tester,
  ) async {
    await pumpAuthScreen(
      tester,
      repository: repository,
      initialLocation: '/register',
    );

    await _fillForm(tester);
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(_createButton);
    await tester.pumpAndSettle();

    expect(repository.createdEmails, ['rahim@example.com']);
    expect(find.text(homePlaceholder), findsOneWidget);
  });

  testWidgets('a failed sign-up shows the error banner', (tester) async {
    repository.failWith = 'An account already exists with this email.';
    await pumpAuthScreen(
      tester,
      repository: repository,
      initialLocation: '/register',
    );

    await _fillForm(tester);
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(_createButton);
    await tester.pumpAndSettle();

    expect(
      find.text('An account already exists with this email.'),
      findsOneWidget,
    );
    expect(find.text(homePlaceholder), findsNothing);
  });

  testWidgets('Log in link returns to login when there is no back stack', (
    tester,
  ) async {
    await pumpAuthScreen(
      tester,
      repository: repository,
      initialLocation: '/register',
    );

    await tester.tap(find.text(AppStrings.authLogIn));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.loginTitle), findsOneWidget);
  });
}
