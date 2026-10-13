import 'dart:async';

import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/widgets/app_chip.dart';
import 'package:careermatebd/features/cover_letter/data/repositories/cover_letter_repository_impl.dart';
import 'package:careermatebd/features/cv_builder/data/repositories/cv_repository_impl.dart';
import 'package:careermatebd/features/job_tracker/data/repositories/job_application_repository_impl.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_application_status.dart';
import 'package:careermatebd/features/job_tracker/presentation/screens/job_application_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/clipboard_mock.dart';
import '../../../../helpers/core_flow_harness.dart';
import '../../../../helpers/design_cv.dart';
import '../../../../helpers/fake_cv_repository.dart';
import '../../../../helpers/fake_job_application_repository.dart';
import '../../../../helpers/routed_screen_harness.dart';

const String _trackerLabel = 'tracker-list';

Future<(RoutedScreen, FakeJobApplicationRepository)> _open(
  WidgetTester tester, {
  String id = 'job-applied',
}) async {
  final repository = FakeJobApplicationRepository([
    for (final application in designApplications())
      application.id == 'job-applied'
          ? application.copyWith(
              cvId: 'cv-frontend',
              notes: 'Call HR on Monday.',
            )
          : application,
  ]);
  final app = await pumpRoutedScreen(
    tester,
    path: RouteNames.jobTrackerPath,
    screen: const Scaffold(body: Text(_trackerLabel)),
    routes: {
      RouteNames.jobApplicationDetailsPath: JobApplicationDetailsScreen(
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
  unawaited(app.router.push(RouteNames.jobApplicationDetailsPath));
  await tester.pumpAndSettle();
  return (app, repository);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the application and what is linked to it', (tester) async {
    await _open(tester);

    expect(find.text('React Developer'), findsOneWidget);
    expect(find.text('Beta Soft'), findsOneWidget);
    expect(find.text('Applied date'), findsOneWidget);
    expect(find.text('Frontend Developer CV'), findsOneWidget);
    expect(find.text('No linked cover letter'), findsOneWidget);
    expect(find.text('Call HR on Monday.'), findsOneWidget);
    expect(find.text('Not added'), findsWidgets);
  });

  testWidgets('a status chip updates the status', (tester) async {
    final (_, repository) = await _open(tester);

    await _tap(tester, find.widgetWithText(AppChip, 'Interview'));

    expect(
      repository.store['job-applied']!.status,
      JobApplicationStatus.interview,
    );
    expect(find.text('Status updated to Interview.'), findsOneWidget);
    expect(
      tester.widget<AppChip>(find.widgetWithText(AppChip, 'Interview')).variant,
      AppChipVariant.selected,
    );
  });

  testWidgets('Archive archives and offers to restore', (tester) async {
    final (_, repository) = await _open(tester);

    await _tap(tester, find.text('Archive'));
    expect(
      repository.store['job-applied']!.status,
      JobApplicationStatus.archived,
    );

    await _tap(tester, find.text('Mark applied'));
    expect(
      repository.store['job-applied']!.status,
      JobApplicationStatus.applied,
    );
  });

  testWidgets('a template copies its message', (tester) async {
    final copied = mockClipboard(tester);
    await _open(tester);

    await _tap(tester, find.text('Follow-up email/message'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(copied.single, contains('following up on my application'));
    expect(copied.single, contains('React Developer'));
    expect(find.text('Follow-up email/message copied.'), findsOneWidget);
  });

  testWidgets('Edit opens the form for this application', (tester) async {
    await _open(tester);

    await _tap(tester, find.text('Edit'));

    expect(
      find.text(uriTextFor('/job-tracker/form?id=job-applied')),
      findsOneWidget,
    );
  });

  testWidgets('Delete asks first, then removes it and goes back', (
    tester,
  ) async {
    final (_, repository) = await _open(tester);

    await _tap(tester, find.text('Delete application'));
    expect(find.text('Delete application'), findsWidgets);
    await _tap(tester, find.text('Cancel'));
    expect(repository.store, contains('job-applied'));

    await _tap(tester, find.text('Delete application'));
    await _tap(tester, find.widgetWithText(FilledButton, 'Delete'));

    expect(repository.store, isNot(contains('job-applied')));
    expect(find.text(_trackerLabel), findsOneWidget);
  });

  testWidgets('an unknown application is reported, not crashed on', (
    tester,
  ) async {
    await _open(tester, id: 'missing');

    expect(find.text('Application not found'), findsOneWidget);
  });
}
