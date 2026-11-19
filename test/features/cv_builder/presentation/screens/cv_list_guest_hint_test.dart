import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/features/auth/data/repositories/firebase_auth_repository_impl.dart';
import 'package:careermatebd/features/cv_builder/data/repositories/cv_repository_impl.dart';
import 'package:careermatebd/features/cv_builder/presentation/screens/cv_list_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/design_cv.dart';
import '../../../../helpers/fake_auth_repository.dart';
import '../../../../helpers/fake_cv_repository.dart';
import '../../../../helpers/routed_screen_harness.dart';

Future<void> _pump(WidgetTester tester, FakeAuthRepository auth) async {
  await pumpRoutedScreen(
    tester,
    path: RouteNames.cvListPath,
    screen: const CvListScreen(),
    overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      cvRepositoryProvider.overrideWithValue(FakeCvRepository([designCv()])),
    ],
  );
}

void main() {
  testWidgets('a guest is told the CVs are only on this device and can sign '
      'in from there', (tester) async {
    final auth = FakeAuthRepository();
    addTearDown(auth.dispose);
    await _pump(tester, auth);

    expect(find.text(AppStrings.guestBackupHint), findsOneWidget);
    await tester.tap(find.text(AppStrings.guestBackupSignIn));
    await tester.pumpAndSettle();
    expect(find.text(placeholderFor(RouteNames.loginPath)), findsOneWidget);
  });

  testWidgets('a signed-in user sees no guest hint', (tester) async {
    final auth = FakeAuthRepository();
    addTearDown(auth.dispose);
    await auth.signInWithEmailAndPassword(email: 'a@b.c', password: 'x');
    await _pump(tester, auth);

    expect(find.text(AppStrings.guestBackupHint), findsNothing);
  });
}
