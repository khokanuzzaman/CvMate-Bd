import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/features/auth/data/repositories/firebase_auth_repository_impl.dart';
import 'package:careermatebd/features/cv_builder/data/repositories/cv_repository_impl.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/presentation/screens/cv_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_auth_repository.dart';
import '../../../../helpers/fake_cv_repository.dart';
import '../../../../helpers/routed_screen_harness.dart';

Future<void> _openDelete(WidgetTester tester, {required bool signedIn}) async {
  final auth = FakeAuthRepository();
  addTearDown(auth.dispose);
  if (signedIn) {
    await auth.signInWithEmailAndPassword(email: 'a@b.c', password: 'x');
  }
  await pumpRoutedScreen(
    tester,
    path: RouteNames.cvListPath,
    screen: const CvListScreen(),
    surface: const Size(390, 1600),
    overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      cvRepositoryProvider.overrideWithValue(
        FakeCvRepository([CvProfile.empty().copyWith(id: 'a', title: 'Mine')]),
      ),
    ],
  );
  await tester.tap(find.byWidgetPredicate((w) => w is PopupMenuButton).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Delete CV').last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('signed in, the delete dialog says the cloud backup goes too', (
    tester,
  ) async {
    await _openDelete(tester, signedIn: true);
    expect(
      find.text(AppStrings.cvDeleteBodyWithBackup('Mine')),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });

  testWidgets('a guest is told the CV is deleted from this device', (
    tester,
  ) async {
    await _openDelete(tester, signedIn: false);
    expect(find.text(AppStrings.cvDeleteBodyLocal('Mine')), findsOneWidget);
  });
}
