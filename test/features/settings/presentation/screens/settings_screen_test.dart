import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/features/auth/data/repositories/firebase_auth_repository_impl.dart';
import 'package:careermatebd/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:careermatebd/features/settings/presentation/controllers/settings_overview_controller.dart';
import 'package:careermatebd/features/settings/presentation/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../helpers/fake_auth_repository.dart';
import '../../../../helpers/fake_settings_repository.dart';
import '../../../../helpers/routed_screen_harness.dart';

Future<(FakeAuthRepository, FakeSettingsRepository)> _open(
  WidgetTester tester, {
  required bool signedIn,
}) async {
  final auth = FakeAuthRepository();
  addTearDown(auth.dispose);
  if (signedIn) {
    await auth.signInWithEmailAndPassword(email: 'a@b.c', password: 'x');
  }
  final settings = FakeSettingsRepository();
  await pumpRoutedScreen(
    tester,
    path: RouteNames.settingsPath,
    screen: const SettingsScreen(),
    surface: const Size(390, 2400),
    overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      settingsRepositoryProvider.overrideWithValue(settings),
      packageInfoLoaderProvider.overrideWithValue(
        () async => PackageInfo(
          appName: 'CvMate',
          packageName: 'com.khokan.careermatebd',
          version: '1.0.0',
          buildNumber: '1',
        ),
      ),
    ],
  );
  return (auth, settings);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('AI features start off; the switch saves consent on and off', (
    tester,
  ) async {
    final (_, settings) = await _open(tester, signedIn: false);
    final aiSwitch = find.widgetWithText(
      SwitchListTile,
      AppStrings.aiFeaturesSetting,
    );
    expect(tester.widget<SwitchListTile>(aiSwitch).value, isFalse);

    await _tap(tester, aiSwitch);
    expect(settings.preferences.aiConsent, isTrue);
    expect(find.text('AI features turned on.'), findsOneWidget);

    await _tap(tester, aiSwitch);
    expect(settings.preferences.aiConsent, isFalse);
  });

  testWidgets('a guest gets Login and Register; a signed-in user can reset '
      'the password for their own email', (tester) async {
    await _open(tester, signedIn: false);
    expect(find.text('Guest / local mode'), findsOneWidget);
    expect(find.text('Reset password'), findsNothing);
    await _tap(tester, find.text('Login'));
    expect(find.text(placeholderFor(RouteNames.loginPath)), findsOneWidget);

    final (auth, _) = await _open(tester, signedIn: true);
    expect(find.text('Login'), findsNothing);
    await _tap(tester, find.text('Reset password'));
    expect(auth.resetEmails, ['a@b.c']);
  });
}
