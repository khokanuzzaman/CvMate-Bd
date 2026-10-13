import 'dart:async';

import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/widgets/app_chip.dart';
import 'package:careermatebd/features/cover_letter/data/repositories/cover_letter_repository_impl.dart';
import 'package:careermatebd/features/cv_builder/data/repositories/cv_repository_impl.dart';
import 'package:careermatebd/features/job_tracker/data/repositories/job_application_repository_impl.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_application_status.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_source.dart';
import 'package:careermatebd/features/job_tracker/presentation/controllers/job_application_form_controller.dart';
import 'package:careermatebd/features/job_tracker/presentation/screens/job_application_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/core_flow_harness.dart';
import '../../../../helpers/design_cv.dart';
import '../../../../helpers/fake_cv_repository.dart';
import '../../../../helpers/fake_job_application_repository.dart';
import '../../../../helpers/routed_screen_harness.dart';

const String _trackerLabel = 'tracker-list';

Future<(RoutedScreen, FakeJobApplicationRepository)> _open(
  WidgetTester tester, {
  String? id,
}) async {
  final repository = FakeJobApplicationRepository(designApplications());
  final app = await pumpRoutedScreen(
    tester,
    path: RouteNames.jobTrackerPath,
    screen: const Scaffold(body: Text(_trackerLabel)),
    surface: const Size(390, 2600),
    routes: {
      RouteNames.jobApplicationFormPath: JobApplicationFormScreen(
        applicationId: id,
      ),
    },
    overrides: [
      jobApplicationRepositoryProvider.overrideWithValue(repository),
      cvRepositoryProvider.overrideWithValue(FakeCvRepository([designCv()])),
      coverLetterRepositoryProvider.overrideWithValue(
        FakeCoverLetterRepository(),
      ),
    ],
  );
  unawaited(app.router.push(RouteNames.jobApplicationFormPath));
  await tester.pumpAndSettle();
  return (app, repository);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Finder _chip(String label) => find.widgetWithText(AppChip, label);

void main() {
  group('add', () {
    testWidgets('starts with the default source and status', (tester) async {
      await _open(tester);

      expect(find.text('Add application'), findsOneWidget);
      expect(find.text('Save application'), findsOneWidget);
      expect(
        tester.widget<AppChip>(_chip('Bdjobs')).variant,
        AppChipVariant.selected,
      );
      expect(
        tester.widget<AppChip>(_chip('Draft')).variant,
        AppChipVariant.selected,
      );
    });

    testWidgets('saving without a company or title explains what is missing', (
      tester,
    ) async {
      final (_, repository) = await _open(tester);
      final before = repository.store.length;

      await _tap(tester, find.text('Save application'));

      // Shown inline and as a snackbar.
      expect(find.text('Company name is required.'), findsWidgets);
      expect(repository.store, hasLength(before));
      expect(find.text('Add application'), findsOneWidget);
    });

    testWidgets('saves what was entered and returns to the tracker', (
      tester,
    ) async {
      final (_, repository) = await _open(tester);
      final before = repository.store.keys.toSet();

      await tester.enterText(find.byType(TextField).at(0), 'Daraz');
      await tester.enterText(find.byType(TextField).at(1), 'Product Designer');
      await _tap(tester, _chip('LinkedIn'));
      await _tap(tester, _chip('Applied'));
      await tester.pumpAndSettle();
      await _tap(tester, find.text('Save application'));

      final added = repository.store.values.singleWhere(
        (application) => !before.contains(application.id),
      );
      expect(added.companyName, 'Daraz');
      expect(added.jobTitle, 'Product Designer');
      expect(added.jobSource, JobSource.linkedIn);
      expect(added.status, JobApplicationStatus.applied);
      expect(find.text(_trackerLabel), findsOneWidget);
    });

    testWidgets('picks and clears an interview date', (tester) async {
      final (app, _) = await _open(tester);

      await _tap(tester, find.text('Interview date'));
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(
        app.container.read(jobApplicationFormControllerProvider).interviewDate,
        isNotNull,
      );

      await _tap(tester, find.byTooltip('Clear date'));
      expect(
        app.container.read(jobApplicationFormControllerProvider).interviewDate,
        isNull,
      );
    });
  });

  group('edit', () {
    testWidgets('loads the saved values and saves the changes', (tester) async {
      final (_, repository) = await _open(tester, id: 'job-applied');

      expect(find.text('Edit application'), findsOneWidget);
      expect(find.text('Beta Soft'), findsOneWidget);
      expect(find.text('React Developer'), findsOneWidget);
      expect(
        tester.widget<AppChip>(_chip('Applied')).variant,
        AppChipVariant.selected,
      );

      await tester.enterText(find.byType(TextField).at(1), 'Senior React Dev');
      await _tap(tester, _chip('Interview'));
      await _tap(tester, find.text('Save application'));

      final saved = repository.store['job-applied']!;
      expect(saved.jobTitle, 'Senior React Dev');
      expect(saved.status, JobApplicationStatus.interview);
      expect(saved.companyName, 'Beta Soft');
      expect(repository.store, hasLength(3));
      expect(find.text(_trackerLabel), findsOneWidget);
    });
  });

  testWidgets('Back leaves without saving', (tester) async {
    final (_, repository) = await _open(tester);
    final before = repository.store.length;

    await _tap(tester, find.byIcon(Icons.chevron_left_rounded));

    expect(find.text(_trackerLabel), findsOneWidget);
    expect(repository.store, hasLength(before));
  });
}
