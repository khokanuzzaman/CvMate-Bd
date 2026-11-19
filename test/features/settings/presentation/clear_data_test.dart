import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/features/auth/data/repositories/firebase_auth_repository_impl.dart';
import 'package:careermatebd/features/cover_letter/data/repositories/cover_letter_repository_impl.dart';
import 'package:careermatebd/features/cv_builder/data/repositories/cv_repository_impl.dart';
import 'package:careermatebd/features/interview_prep/data/repositories/interview_prep_session_repository_impl.dart';
import 'package:careermatebd/features/job_tracker/data/repositories/job_application_repository_impl.dart';
import 'package:careermatebd/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:careermatebd/features/settings/presentation/controllers/settings_overview_controller.dart';
import 'package:careermatebd/features/settings/presentation/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../helpers/core_flow_harness.dart';
import '../../../helpers/design_cv.dart';
import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/fake_cv_repository.dart';
import '../../../helpers/fake_interview_session_repository.dart';
import '../../../helpers/fake_job_application_repository.dart';
import '../../../helpers/fake_settings_repository.dart';
import '../../../helpers/routed_screen_harness.dart';

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<FakeCvRepository> _pumpSettings(
  WidgetTester tester, {
  required bool signedIn,
  required Future<bool> Function() eraseCloud,
}) async {
  final auth = FakeAuthRepository();
  addTearDown(auth.dispose);
  if (signedIn) {
    await auth.signInWithEmailAndPassword(email: 'a@b.c', password: 'x');
  }
  final cvs = FakeCvRepository([designCv()]);
  await pumpRoutedScreen(
    tester,
    path: RouteNames.settingsPath,
    screen: const SettingsScreen(),
    surface: const Size(390, 2400),
    overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository()),
      cvRepositoryProvider.overrideWithValue(cvs),
      coverLetterRepositoryProvider.overrideWithValue(
        FakeCoverLetterRepository(),
      ),
      jobApplicationRepositoryProvider.overrideWithValue(
        FakeJobApplicationRepository(),
      ),
      interviewPrepSessionRepositoryProvider.overrideWithValue(
        FakeInterviewSessionRepository(),
      ),
      cvCloudBackupEraserProvider.overrideWithValue(eraseCloud),
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
  return cvs;
}

void main() {
  testWidgets('signed in: "Also delete my CV cloud backup" deletes the backup '
      'first, then the local data', (tester) async {
    final localCvsWhenCloudDeleted = <int>[];
    late final FakeCvRepository cvs;
    cvs = await _pumpSettings(
      tester,
      signedIn: true,
      eraseCloud: () async {
        localCvsWhenCloudDeleted.add(cvs.store.length);
        return true;
      },
    );

    await _tap(tester, find.text(AppStrings.clearDataTitle));
    expect(find.text(AppStrings.clearDataCloudKeptNote), findsOneWidget);
    await _tap(tester, find.text(AppStrings.clearDataAlsoCloud));
    expect(find.text(AppStrings.clearDataCloudDeletedNote), findsOneWidget);
    await _tap(tester, find.text(AppStrings.clearDataConfirm));

    expect(localCvsWhenCloudDeleted, [1], reason: 'cloud first, local after');
    expect(cvs.store, isEmpty);
    expect(find.text(AppStrings.clearDataDoneWithCloud), findsOneWidget);
  });

  testWidgets('if the cloud delete fails nothing is cleared', (tester) async {
    final cvs = await _pumpSettings(
      tester,
      signedIn: true,
      eraseCloud: () async => throw Exception('offline'),
    );
    await _tap(tester, find.text(AppStrings.clearDataTitle));
    await _tap(tester, find.text(AppStrings.clearDataAlsoCloud));
    await _tap(tester, find.text(AppStrings.clearDataConfirm));

    expect(cvs.store, hasLength(1));
    expect(find.text(AppStrings.clearDataCloudFailed), findsOneWidget);
  });

  testWidgets('a guest is not offered the cloud option', (tester) async {
    var cloudCalls = 0;
    final guestCvs = await _pumpSettings(
      tester,
      signedIn: false,
      eraseCloud: () async {
        cloudCalls++;
        return false;
      },
    );
    await _tap(tester, find.text(AppStrings.clearDataTitle));
    expect(find.text(AppStrings.clearDataAlsoCloud), findsNothing);
    await _tap(tester, find.text(AppStrings.clearDataConfirm));

    expect(guestCvs.store, isEmpty);
    expect(cloudCalls, 0);
    expect(find.text(AppStrings.clearDataDone), findsOneWidget);
  });
}
