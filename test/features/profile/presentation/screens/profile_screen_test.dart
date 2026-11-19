import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/widgets/bottom_nav_bar.dart';
import 'package:careermatebd/features/auth/data/repositories/firebase_auth_repository_impl.dart';
import 'package:careermatebd/features/profile/presentation/screens/profile_screen.dart';
import 'package:careermatebd/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:careermatebd/features/settings/presentation/controllers/settings_overview_controller.dart';
import 'package:careermatebd/shared/services/entitlement/ai_entitlement.dart';
import 'package:careermatebd/shared/services/entitlement/entitlement_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../helpers/builder_harness.dart';
import '../../../../helpers/fake_ai_entitlement.dart';
import '../../../../helpers/fake_auth_repository.dart';
import '../../../../helpers/fake_settings_repository.dart';
import '../../../../helpers/routed_screen_harness.dart';

class _App {
  _App(this.screen, this.auth, this.settings);

  final RoutedScreen screen;
  final FakeAuthRepository auth;
  final FakeSettingsRepository settings;
}

Future<_App> _open(
  WidgetTester tester, {
  bool signedIn = true,
  bool anonymous = false,
  AiEntitlement? plan,
  Future<PackageInfo> Function()? packageInfo,
}) async {
  final auth = FakeAuthRepository(displayName: 'Ayesha Rahman');
  addTearDown(auth.dispose);
  if (anonymous) {
    await auth.signInAnonymously();
  } else if (signedIn) {
    await auth.signInWithEmailAndPassword(
      email: 'ayesha@email.com',
      password: 'secret12',
    );
  }
  final settings = FakeSettingsRepository();

  final screen = await pumpRoutedScreen(
    tester,
    path: RouteNames.profilePath,
    screen: const ProfileScreen(),
    surface: const Size(390, 1500),
    overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      entitlementStoreProvider.overrideWithValue(FakeEntitlementStore()),
      ...fakeEntitlementOverrides(FakeAiEntitlementController(plan)),
      settingsRepositoryProvider.overrideWithValue(settings),
      packageInfoLoaderProvider.overrideWithValue(
        packageInfo ??
            () async => PackageInfo(
              appName: 'CvMate',
              packageName: 'com.khokan.careermatebd',
              version: '1.2.3',
              buildNumber: '45',
            ),
      ),
    ],
  );
  return _App(screen, auth, settings);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('account', () {
    testWidgets('shows the name, email and Free plan', (tester) async {
      await _open(tester);

      expect(find.text('Ayesha Rahman'), findsOneWidget);
      expect(find.text('ayesha@email.com'), findsOneWidget);
      expect(find.text(AppStrings.planFree), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('without a display name the email is not repeated', (
      tester,
    ) async {
      final auth = FakeAuthRepository();
      addTearDown(auth.dispose);
      await auth.signInWithEmailAndPassword(email: 'sam@x.com', password: 'pw');
      await pumpRoutedScreen(
        tester,
        path: RouteNames.profilePath,
        screen: const ProfileScreen(),
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          entitlementStoreProvider.overrideWithValue(FakeEntitlementStore()),
          settingsRepositoryProvider.overrideWithValue(
            FakeSettingsRepository(),
          ),
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

      expect(find.text('sam@x.com'), findsOneWidget);
    });

    testWidgets('an unreadable app version just leaves the footer out', (
      tester,
    ) async {
      await _open(
        tester,
        packageInfo: () async => throw Exception('no package info'),
      );

      expect(find.textContaining('CvMate 1'), findsNothing);
      expect(find.text('Ayesha Rahman'), findsOneWidget);
    });

    testWidgets('a Pro user sees the Pro badge and no Go Pro banner', (
      tester,
    ) async {
      await _open(tester, plan: proEntitlement);

      expect(find.text(AppStrings.planPro), findsOneWidget);
      expect(find.text(AppStrings.planFree), findsNothing);
      expect(find.text(AppStrings.goProTitle), findsNothing);
    });

    testWidgets('a guest sees Guest and how to sign in', (tester) async {
      await _open(tester, signedIn: false);

      expect(find.text(AppStrings.profileGuest), findsOneWidget);
      expect(find.text(AppStrings.profileGuestSubtitle), findsOneWidget);
      expect(find.text(AppStrings.profileLogOut), findsNothing);

      await _tap(tester, find.text(AppStrings.profileLogIn));
      expect(find.text(placeholderFor(RouteNames.loginPath)), findsOneWidget);
    });

    testWidgets('a guest can create an account', (tester) async {
      await _open(tester, signedIn: false);

      await _tap(tester, find.text(AppStrings.profileCreateAccount));

      expect(
        find.text(placeholderFor(RouteNames.registerPath)),
        findsOneWidget,
      );
    });
  });

  group('Go Pro', () {
    testWidgets('See plans opens the paywall, tagged with its source', (
      tester,
    ) async {
      await _open(tester);

      expect(find.text(AppStrings.goProTitle), findsOneWidget);
      await _tap(tester, find.text(AppStrings.goProCta));

      expect(find.text(uriTextFor('/paywall?source=profile')), findsOneWidget);
    });
  });

  group('preferences', () {
    testWidgets('v1 has no theme or app-language rows (light only, '
        'English UI)', (tester) async {
      await _open(tester);

      expect(find.text(AppStrings.profileTheme), findsNothing);
      expect(find.text(AppStrings.themeDark), findsNothing);
      expect(find.text(AppStrings.themeComingSoon), findsNothing);
      expect(find.text(AppStrings.profileAppLanguage), findsNothing);
    });

    testWidgets('there is no reminders toggle (no such preference exists)', (
      tester,
    ) async {
      await _open(tester);

      expect(find.byType(Switch), findsNothing);
      expect(find.textContaining('reminder'), findsNothing);
    });
  });

  group('account rows', () {
    testWidgets('Cloud backup is on while signed in', (tester) async {
      await _open(tester);

      expect(find.text(AppStrings.profileCloudBackup), findsOneWidget);
      expect(find.text(AppStrings.profileCloudOn), findsOneWidget);
      expect(find.text(AppStrings.profileCloudOnNote), findsOneWidget);
    });

    testWidgets('Cloud backup is on for a guest session too', (tester) async {
      await _open(tester, anonymous: true);

      expect(find.text(AppStrings.profileCloudOn), findsOneWidget);
    });

    testWidgets('Cloud backup is off, and says why, when signed out', (
      tester,
    ) async {
      await _open(tester, signedIn: false);

      expect(find.text(AppStrings.profileCloudOff), findsOneWidget);
      expect(find.text(AppStrings.profileCloudOffNote), findsOneWidget);
    });

    testWidgets('Restore purchases opens the paywall, where Restore is', (
      tester,
    ) async {
      await _open(tester);

      await _tap(tester, find.text(AppStrings.paywallRestore));
      expect(find.text(uriTextFor('/paywall?source=restore')), findsOneWidget);
    });

    testWidgets('Privacy & terms shows the policy and terms', (tester) async {
      await _open(tester);

      await _tap(tester, find.text(AppStrings.profilePrivacyTerms));

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.textContaining('Privacy Policy placeholder'), findsOneWidget);
      expect(find.textContaining('Terms placeholder'), findsOneWidget);

      await _tap(tester, find.text(AppStrings.legalClose));
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('More settings opens the full settings screen', (tester) async {
      await _open(tester);

      await _tap(tester, find.text(AppStrings.profileMoreSettings));

      expect(
        find.text(placeholderFor(RouteNames.settingsPath)),
        findsOneWidget,
      );
    });
  });

  group('log out', () {
    testWidgets('asks first; Cancel keeps the session', (tester) async {
      final app = await _open(tester);

      await _tap(tester, find.text(AppStrings.profileLogOut));
      expect(find.text(AppStrings.logOutBody), findsOneWidget);
      await _tap(tester, find.text(AppStrings.logOutCancel));

      expect(app.auth.currentUser, isNotNull);
      expect(find.text('Ayesha Rahman'), findsOneWidget);
    });

    testWidgets('confirming signs out and returns to onboarding', (
      tester,
    ) async {
      final app = await _open(tester);

      await _tap(tester, find.text(AppStrings.profileLogOut));
      await _tap(
        tester,
        find.widgetWithText(FilledButton, AppStrings.profileLogOut),
      );

      expect(app.auth.currentUser, isNull);
      expect(
        find.text(placeholderFor(RouteNames.onboardingPath)),
        findsOneWidget,
      );
    });
  });

  group('footer and navigation', () {
    testWidgets('shows the app version', (tester) async {
      await _open(tester);

      expect(
        find.text(AppStrings.profileVersion('1.2.3 (45)')),
        findsOneWidget,
      );
    });

    testWidgets('the nav has Profile selected and switches tabs', (
      tester,
    ) async {
      await _open(tester);
      expect(
        tester.widget<BottomNavBar>(find.byType(BottomNavBar)).currentIndex,
        4,
      );

      await _tap(tester, find.text('Tracker'));

      expect(
        find.text(placeholderFor(RouteNames.jobTrackerPath)),
        findsOneWidget,
      );
    });
  });
}
