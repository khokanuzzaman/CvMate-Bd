import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/features/auth/data/repositories/firebase_auth_repository_impl.dart';
import 'package:careermatebd/features/cv_builder/data/repositories/cv_repository_impl.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:careermatebd/features/cv_builder/presentation/screens/cv_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_auth_repository.dart';
import '../../../../helpers/fake_cv_repository.dart';
import '../../../../helpers/routed_screen_harness.dart';

const _stylePage = 'style-page';

CvProfile _cv(String id, String title) =>
    CvProfile.empty().copyWith(id: id, title: title);

Future<RoutedScreen> _open(WidgetTester tester, FakeCvRepository repository) {
  final auth = FakeAuthRepository();
  addTearDown(auth.dispose);
  return pumpRoutedScreen(
    tester,
    path: RouteNames.cvListPath,
    screen: const CvListScreen(),
    surface: const Size(390, 1600),
    routes: {RouteNames.cvStylePath: const Text(_stylePage)},
    overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      cvRepositoryProvider.overrideWithValue(repository),
    ],
  );
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists the saved CVs; Create new CV saves a draft and opens '
      'the style step', (tester) async {
    final repository = FakeCvRepository([
      _cv('a', 'Frontend CV'),
      _cv('b', 'Flutter CV'),
    ]);
    final app = await _open(tester, repository);

    expect(find.text('Frontend CV'), findsOneWidget);
    expect(find.text('Flutter CV'), findsOneWidget);
    expect(find.textContaining('2 saved CVs'), findsOneWidget);

    await _tap(tester, find.text('Create new CV'));

    expect(find.text(_stylePage), findsOneWidget);
    expect(repository.store, hasLength(3));
    expect(
      app.container.read(cvBuilderControllerProvider).hasActiveDraft,
      isTrue,
    );
  });

  testWidgets('Delete asks first: Cancel keeps the CV, Delete removes it', (
    tester,
  ) async {
    final repository = FakeCvRepository([_cv('a', 'Frontend CV')]);
    await _open(tester, repository);

    Future<void> openDelete() async {
      await _tap(
        tester,
        find.byWidgetPredicate((w) => w is PopupMenuButton).first,
      );
      await _tap(tester, find.text('Delete CV').last);
    }

    await openDelete();
    await _tap(tester, find.text('Cancel'));
    expect(repository.store.keys, ['a']);

    await openDelete();
    await _tap(tester, find.widgetWithText(FilledButton, 'Delete'));
    expect(repository.store, isEmpty);
    expect(find.text('CV deleted.'), findsOneWidget);
    expect(find.text('No CV created yet'), findsOneWidget);
  });
}
