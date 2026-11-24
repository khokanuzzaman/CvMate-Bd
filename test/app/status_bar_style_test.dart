import 'package:careermatebd/app/app.dart';
import 'package:careermatebd/app/constants/app_constants.dart';
import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/router/app_router.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/features/auth/data/repositories/firebase_auth_repository_impl.dart';
import 'package:careermatebd/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:careermatebd/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_auth_repository.dart';
import '../helpers/fake_onboarding_repository.dart';
import '../helpers/fake_settings_repository.dart';

/// iOS reads `statusBarBrightness` (the background), Android
/// `statusBarIconBrightness` (the icons). Dark icons = light background.
void _expectDarkIcons(String screen) {
  final style = SystemChrome.latestStyle;
  expect(style?.statusBarBrightness, Brightness.light, reason: screen);
  expect(style?.statusBarIconBrightness, Brightness.dark, reason: screen);
}

void main() {
  testWidgets('status bar: light icons on the splash, dark icons on light '
      'screens with and without an app bar', (tester) async {
    final auth = FakeAuthRepository();
    addTearDown(auth.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          settingsRepositoryProvider.overrideWithValue(
            FakeSettingsRepository(),
          ),
          onboardingRepositoryProvider.overrideWithValue(
            FakeOnboardingRepository(),
          ),
        ],
        child: const CareerMateApp(),
      ),
    );
    await tester.pump();

    expect(find.text(AppStrings.splashTagline), findsOneWidget);
    expect(SystemChrome.latestStyle?.statusBarBrightness, Brightness.dark);
    expect(SystemChrome.latestStyle?.statusBarIconBrightness, Brightness.light);

    await tester.pump(AppConstants.splashDuration);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.onboardingHeadline), findsOneWidget);
    _expectDarkIcons('onboarding (no app bar)');

    final container = ProviderScope.containerOf(
      tester.element(find.byType(CareerMateApp)),
    );
    container.read(appRouterProvider).push(RouteNames.forgotPasswordPath);
    await tester.pumpAndSettle();
    expect(find.byType(AppBar), findsOneWidget);
    _expectDarkIcons('forgot password (transparent app bar)');
  });
}
