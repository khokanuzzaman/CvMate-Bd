import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/core/widgets/social_auth_button.dart';
import 'package:careermatebd/features/auth/presentation/widgets/auth_error_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/auth_screen_harness.dart';
import '../../../../helpers/fake_auth_repository.dart';

Finder get _logInButton =>
    find.widgetWithText(PrimaryButton, AppStrings.authLogIn);

Future<void> _fillCredentials(
  WidgetTester tester, {
  String email = 'rahim@example.com',
  String password = 'secret12',
}) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), email);
  await tester.enterText(fields.at(1), password);
}

void main() {
  late FakeAuthRepository repository;

  setUp(() {
    repository = FakeAuthRepository();
  });

  tearDown(() async {
    await repository.dispose();
  });

  testWidgets('renders the login design copy and controls', (tester) async {
    await pumpAuthScreen(
      tester,
      repository: repository,
      initialLocation: '/login',
    );

    expect(find.text(AppStrings.brandName), findsOneWidget);
    expect(find.text(AppStrings.loginTitle), findsOneWidget);
    expect(find.text(AppStrings.loginSubtitle), findsOneWidget);
    expect(find.text(AppStrings.authEmailLabel), findsOneWidget);
    expect(find.text(AppStrings.authPasswordLabel), findsOneWidget);
    expect(find.text(AppStrings.loginForgot), findsOneWidget);
    expect(_logInButton, findsOneWidget);
    expect(find.text(AppStrings.authOr), findsOneWidget);
    expect(find.text(AppStrings.loginNewHere), findsOneWidget);
  });

  testWidgets('Google sign-in is shown disabled (not implemented yet)', (
    tester,
  ) async {
    await pumpAuthScreen(
      tester,
      repository: repository,
      initialLocation: '/login',
    );

    final button = tester.widget<SocialAuthButton>(
      find.byType(SocialAuthButton),
    );
    expect(button.label, AppStrings.loginGoogle);
    expect(button.onPressed, isNull);
  });

  testWidgets('password field toggles between hidden and visible', (
    tester,
  ) async {
    await pumpAuthScreen(
      tester,
      repository: repository,
      initialLocation: '/login',
    );

    TextField passwordField() =>
        tester.widget<TextField>(find.byType(TextField).at(1));

    expect(passwordField().obscureText, isTrue);

    await tester.tap(find.byTooltip(AppStrings.authShowPassword));
    await tester.pump();
    expect(passwordField().obscureText, isFalse);

    await tester.tap(find.byTooltip(AppStrings.authHidePassword));
    await tester.pump();
    expect(passwordField().obscureText, isTrue);
  });

  testWidgets('submitting empty fields shows validation and skips sign-in', (
    tester,
  ) async {
    await pumpAuthScreen(
      tester,
      repository: repository,
      initialLocation: '/login',
    );

    await tester.tap(_logInButton);
    await tester.pump();

    expect(find.text('Email is required.'), findsOneWidget);
    expect(find.text('Password is required.'), findsOneWidget);
    expect(repository.signInEmails, isEmpty);
  });

  testWidgets('valid credentials sign in and continue to home', (tester) async {
    await pumpAuthScreen(
      tester,
      repository: repository,
      initialLocation: '/login',
    );

    await _fillCredentials(tester);
    await tester.tap(_logInButton);
    await tester.pumpAndSettle();

    expect(repository.signInEmails, ['rahim@example.com']);
    expect(find.text(homePlaceholder), findsOneWidget);
  });

  testWidgets('login accepts a 6-character password (no 8-char minimum)', (
    tester,
  ) async {
    await pumpAuthScreen(
      tester,
      repository: repository,
      initialLocation: '/login',
    );

    // Firebase allows 6+ characters; existing accounts must keep working.
    await _fillCredentials(tester, password: 'abc123');
    await tester.tap(_logInButton);
    await tester.pumpAndSettle();

    expect(find.textContaining('at least'), findsNothing);
    expect(repository.signInEmails, ['rahim@example.com']);
    expect(find.text(homePlaceholder), findsOneWidget);
  });

  testWidgets('login still rejects passwords under 6 characters', (
    tester,
  ) async {
    await pumpAuthScreen(
      tester,
      repository: repository,
      initialLocation: '/login',
    );

    await _fillCredentials(tester, password: 'abc12');
    await tester.tap(_logInButton);
    await tester.pump();

    expect(
      find.text('Password must be at least 6 characters.'),
      findsOneWidget,
    );
    expect(repository.signInEmails, isEmpty);
  });

  testWidgets('a failed sign-in shows the error banner and stays on login', (
    tester,
  ) async {
    repository.failWith = 'Email or password is incorrect.';
    await pumpAuthScreen(
      tester,
      repository: repository,
      initialLocation: '/login',
    );

    await _fillCredentials(tester);
    await tester.tap(_logInButton);
    await tester.pumpAndSettle();

    expect(find.byType(AuthErrorBanner), findsOneWidget);
    expect(find.text('Email or password is incorrect.'), findsOneWidget);
    expect(find.text(homePlaceholder), findsNothing);
    expect(find.text(AppStrings.loginTitle), findsOneWidget);
  });

  testWidgets('Forgot? opens the reset-password screen', (tester) async {
    await pumpAuthScreen(
      tester,
      repository: repository,
      initialLocation: '/login',
    );

    await tester.tap(find.text(AppStrings.loginForgot));
    await tester.pumpAndSettle();

    expect(find.text('forgot-page'), findsOneWidget);
  });

  testWidgets('Create account link opens registration', (tester) async {
    await pumpAuthScreen(
      tester,
      repository: repository,
      initialLocation: '/login',
    );

    await tester.tap(find.text(AppStrings.createAccount));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.registerHeadline), findsOneWidget);
  });
}
