import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/features/auth/data/repositories/firebase_auth_repository_impl.dart';
import 'package:careermatebd/features/auth/presentation/controllers/new_account_session_provider.dart';
import 'package:careermatebd/features/cv_builder/data/repositories/cv_repository_impl.dart';
import 'package:careermatebd/features/home/presentation/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_auth_repository.dart';
import '../../../../helpers/fake_cv_repository.dart';
import '../../../../helpers/routed_screen_harness.dart';

Future<void> _pumpHome(WidgetTester tester, {required bool newAccount}) async {
  final auth = FakeAuthRepository();
  addTearDown(auth.dispose);
  await auth.signInWithEmailAndPassword(email: 'a@b.c', password: 'secret12');
  await pumpRoutedScreen(
    tester,
    path: RouteNames.homePath,
    screen: const HomeScreen(),
    surface: const Size(390, 1400),
    overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      cvRepositoryProvider.overrideWithValue(FakeCvRepository()),
      isNewAccountSessionProvider.overrideWithValue(newAccount),
    ],
  );
}

void main() {
  testWidgets('Home says "Welcome" to a new account, "Welcome back" '
      'otherwise', (tester) async {
    await _pumpHome(tester, newAccount: true);
    expect(
      find.text(AppStrings.homeWelcomeEyebrowNew.toUpperCase()),
      findsOneWidget,
    );

    await _pumpHome(tester, newAccount: false);
    expect(
      find.text(AppStrings.homeWelcomeEyebrow.toUpperCase()),
      findsOneWidget,
    );
  });
}
