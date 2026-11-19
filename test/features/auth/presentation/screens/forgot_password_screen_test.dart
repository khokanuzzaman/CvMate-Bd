import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/features/auth/data/repositories/firebase_auth_repository_impl.dart';
import 'package:careermatebd/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_auth_repository.dart';
import '../../../../helpers/routed_screen_harness.dart';

const _sent = 'Password reset email sent. Check your inbox.';

Future<FakeAuthRepository> _open(WidgetTester tester) async {
  final auth = FakeAuthRepository();
  addTearDown(auth.dispose);
  await pumpRoutedScreen(
    tester,
    path: RouteNames.forgotPasswordPath,
    screen: const ForgotPasswordScreen(),
    overrides: [authRepositoryProvider.overrideWithValue(auth)],
  );
  return auth;
}

Future<void> _send(WidgetTester tester, String email) async {
  await tester.enterText(find.byType(TextFormField), email);
  await tester.tap(find.text('Send reset link'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('an invalid email is not sent; a valid one is, and the screen '
      'says to check the inbox', (tester) async {
    final auth = await _open(tester);

    await _send(tester, 'not-an-email');
    expect(auth.resetEmails, isEmpty);

    await _send(tester, 'rahim@example.com');
    expect(auth.resetEmails, ['rahim@example.com']);
    expect(find.text(_sent), findsWidgets);
  });

  testWidgets('a failed request shows why, and Back to login goes to login', (
    tester,
  ) async {
    final auth = await _open(tester);
    auth.resetFailWith = 'No account uses this email.';

    await _send(tester, 'rahim@example.com');
    expect(find.text('No account uses this email.'), findsOneWidget);
    expect(find.text(_sent), findsNothing);

    await tester.ensureVisible(find.text('Back to login'));
    await tester.tap(find.text('Back to login'));
    await tester.pumpAndSettle();
    expect(find.text(placeholderFor(RouteNames.loginPath)), findsOneWidget);
  });
}
