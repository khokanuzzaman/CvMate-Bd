import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/errors/app_exception.dart';
import 'package:careermatebd/features/account_deletion/data/account_deletion_service.dart';
import 'package:careermatebd/features/account_deletion/presentation/controllers/account_deletion_controller.dart';
import 'package:careermatebd/features/auth/data/repositories/firebase_auth_repository_impl.dart';
import 'package:careermatebd/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:careermatebd/features/settings/presentation/controllers/settings_overview_controller.dart';
import 'package:careermatebd/features/settings/presentation/screens/settings_screen.dart';
import 'package:careermatebd/shared/services/ai/ai_server_client.dart';
import 'package:careermatebd/shared/services/billing/fake_billing_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/fake_settings_repository.dart';
import '../../../helpers/routed_screen_harness.dart';

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Delete account: the dialog points to the store to cancel a '
      'subscription; when the server wants a recent sign-in it asks for the '
      'password, then deletes and goes to onboarding', (tester) async {
    final auth = FakeAuthRepository();
    addTearDown(auth.dispose);
    await auth.signInWithEmailAndPassword(email: 'a@b.c', password: 'secret12');
    final steps = <String>[];
    var serverWantsReauth = true;

    await pumpRoutedScreen(
      tester,
      path: RouteNames.settingsPath,
      screen: const SettingsScreen(),
      surface: const Size(390, 2400),
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository()),
        packageInfoLoaderProvider.overrideWithValue(
          () async => PackageInfo(
            appName: 'CvMate',
            packageName: 'com.khokan.careermatebd',
            version: '1.0.0',
            buildNumber: '1',
          ),
        ),
        accountDeletionServiceProvider.overrideWithValue(
          AccountDeletionService(
            auth: auth,
            deleteAccountOnServer: () async {
              steps.add('server');
              if (serverWantsReauth) {
                serverWantsReauth = false;
                throw const AppException(
                  AiFailureMessages.reauth,
                  code: AiFailureCodes.reauthRequired,
                );
              }
            },
            billing: FakeBillingService(),
            wipeLocalData: () async => steps.add('local'),
          ),
        ),
      ],
    );

    await _tap(tester, find.text(AppStrings.deleteAccount));
    expect(find.text(AppStrings.deleteAccountTitle), findsOneWidget);
    expect(
      find.textContaining('does not cancel a subscription'),
      findsOneWidget,
    );
    expect(
      find.text(AppStrings.deleteAccountManageSubscriptions),
      findsOneWidget,
    );

    await _tap(tester, find.text(AppStrings.deleteAccountConfirm));
    expect(find.text(AppStrings.deleteAccountPasswordTitle), findsOneWidget);
    expect(steps, ['server'], reason: 'the server refused before deleting');

    await tester.enterText(find.byType(TextField), 'secret12');
    await _tap(tester, find.text(AppStrings.deleteAccountConfirm));

    expect(auth.reauthPasswords, ['secret12']);
    expect(steps, ['server', 'server', 'local']);
    expect(auth.currentUser, isNull);
    expect(
      find.text(placeholderFor(RouteNames.onboardingPath)),
      findsOneWidget,
    );
  });

  testWidgets('Cancel keeps everything', (tester) async {
    final auth = FakeAuthRepository();
    addTearDown(auth.dispose);
    await auth.signInWithEmailAndPassword(email: 'a@b.c', password: 'secret12');
    final steps = <String>[];

    await pumpRoutedScreen(
      tester,
      path: RouteNames.settingsPath,
      screen: const SettingsScreen(),
      surface: const Size(390, 2400),
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository()),
        packageInfoLoaderProvider.overrideWithValue(
          () async => PackageInfo(
            appName: 'CvMate',
            packageName: 'com.khokan.careermatebd',
            version: '1.0.0',
            buildNumber: '1',
          ),
        ),
        accountDeletionServiceProvider.overrideWithValue(
          AccountDeletionService(
            auth: auth,
            deleteAccountOnServer: () async => steps.add('server'),
            billing: FakeBillingService(),
            wipeLocalData: () async => steps.add('local'),
          ),
        ),
      ],
    );

    await _tap(tester, find.text(AppStrings.deleteAccount));
    await _tap(tester, find.text(AppStrings.deleteAccountCancel));

    expect(steps, isEmpty);
    expect(auth.currentUser, isNotNull);
  });
}
