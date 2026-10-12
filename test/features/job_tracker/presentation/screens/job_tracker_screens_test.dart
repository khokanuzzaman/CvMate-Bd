import 'dart:async';

import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/utils/date_formatter.dart';
import 'package:careermatebd/core/widgets/app_chip.dart';
import 'package:careermatebd/features/cover_letter/domain/entities/cover_letter_draft.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_application.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_application_message_templates.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_application_status.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_source.dart';
import 'package:careermatebd/features/job_tracker/presentation/controllers/job_tracker_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/core_flow_harness.dart';
import '../../../../helpers/design_cv.dart';
import '../../../../helpers/fake_cv_repository.dart';

JobApplication _job(
  String id, {
  String company = 'Acme Ltd.',
  String title = 'Frontend Developer',
  JobApplicationStatus status = JobApplicationStatus.applied,
  JobSource source = JobSource.linkedIn,
  DateTime? interviewDate,
  DateTime? followUpDate,
  String notes = '',
  String? cvId,
  String? coverLetterId,
  DateTime? updatedAt,
}) {
  return JobApplication.empty().copyWith(
    id: id,
    companyName: company,
    jobTitle: title,
    status: status,
    jobSource: source,
    appliedDate: DateTime(2026, 9, 1),
    interviewDate: interviewDate,
    followUpDate: followUpDate,
    notes: notes,
    cvId: cvId,
    coverLetterId: coverLetterId,
    createdAt: DateTime(2026, 9, 1),
    updatedAt: updatedAt ?? DateTime(2026, 9, 2),
  );
}

CoverLetterDraft _letter() => CoverLetterDraft.empty().copyWith(
  id: 'letter-1',
  targetCompany: 'Acme Ltd.',
  jobTitle: 'Frontend Developer',
  content: 'Dear Acme,\n\nA saved letter.',
);

Future<CoreFlowApp> _open(
  WidgetTester tester, {
  List<JobApplication> jobs = const [],
  String path = RouteNames.jobTrackerPath,
  FakeCoverLetterRepository? letters,
}) async {
  final app = await pumpCoreFlow(
    tester,
    repository: FakeCvRepository([designCv()]),
    jobApplications: FakeJobApplicationRepository(jobs),
    letters: letters,
    surface: const Size(390, 3000),
  );
  unawaited(app.router.push(path));
  await tester.pumpAndSettle();
  return app;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

AppChipVariant _variant(WidgetTester tester, String label) =>
    tester.widget<AppChip>(find.widgetWithText(AppChip, label)).variant;

List<String> _mockClipboard(WidgetTester tester) {
  final copied = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'Clipboard.setData') {
        copied.add((call.arguments as Map)['text'] as String);
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return copied;
}

void main() {
  group('list', () {
    testWidgets('with no applications it invites adding one', (tester) async {
      await _open(tester);

      expect(find.text(AppStrings.trackerEmptyTitle), findsOneWidget);
      await _tap(tester, find.text(AppStrings.trackerAddApplication));
      expect(find.text(AppStrings.jobFormAddTitle), findsOneWidget);
    });

    testWidgets('shows the summary and each application', (tester) async {
      final app = await _open(
        tester,
        jobs: [
          _job('1', interviewDate: DateTime(2026, 10, 20)),
          _job(
            '2',
            company: 'Beta Soft',
            title: 'Designer',
            status: JobApplicationStatus.interview,
            followUpDate: DateTime(2026, 9, 10),
          ),
          _job(
            '3',
            company: 'Gamma',
            title: 'Analyst',
            status: JobApplicationStatus.offered,
          ),
        ],
      );
      final summary = app.container.read(jobTrackerSummaryProvider);

      expect(summary.total, 3);
      expect(summary.interviews, 1);
      expect(summary.offers, 1);
      expect(summary.pendingFollowUp, 1);
      expect(
        find.text(AppStrings.trackerSummaryTotal.toUpperCase()),
        findsOneWidget,
      );
      expect(find.text('Frontend Developer'), findsOneWidget);
      expect(find.text('Beta Soft'), findsOneWidget);
      expect(find.text('Offered'), findsWidgets);
      expect(find.text(AppStrings.trackerFollowUpDue), findsOneWidget);
      expect(
        find.text(
          AppStrings.trackerInterviewOn(
            DateFormatter.shortDate(DateTime(2026, 10, 20)),
          ),
        ),
        findsOneWidget,
      );
      expect(find.text(JobSource.linkedIn.label), findsWidgets);
    });

    testWidgets('search narrows the list and Clear filters restores it', (
      tester,
    ) async {
      await _open(
        tester,
        jobs: [
          _job('1'),
          _job('2', company: 'Beta Soft', title: 'Designer'),
        ],
      );

      await tester.enterText(find.byType(TextField).first, 'beta');
      await tester.pumpAndSettle();
      expect(find.text('Designer'), findsOneWidget);
      expect(find.text('Frontend Developer'), findsNothing);

      await tester.enterText(find.byType(TextField).first, 'zzz');
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.trackerNoMatchTitle), findsOneWidget);

      await _tap(tester, find.text(AppStrings.trackerClearFilters).last);
      expect(find.text('Designer'), findsOneWidget);
      expect(find.text('Frontend Developer'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        isEmpty,
      );
    });

    testWidgets('a status chip filters by that status', (tester) async {
      await _open(
        tester,
        jobs: [
          _job('1'),
          _job(
            '2',
            company: 'Beta Soft',
            title: 'Designer',
            status: JobApplicationStatus.interview,
          ),
        ],
      );
      expect(
        _variant(tester, AppStrings.trackerFilterAll),
        AppChipVariant.selected,
      );

      await _tap(
        tester,
        find.widgetWithText(AppChip, JobApplicationStatus.interview.label),
      );

      expect(find.text('Designer'), findsOneWidget);
      expect(find.text('Frontend Developer'), findsNothing);
      expect(
        _variant(tester, JobApplicationStatus.interview.label),
        AppChipVariant.selected,
      );
    });

    testWidgets('Add job opens the form, and a card opens the details', (
      tester,
    ) async {
      await _open(tester, jobs: [_job('1')]);

      await _tap(tester, find.text('Frontend Developer'));
      expect(find.text(AppStrings.jobDetailsTitle), findsOneWidget);
    });
  });

  group('form', () {
    testWidgets('needs a company and a title', (tester) async {
      final app = await _open(tester, path: RouteNames.jobApplicationFormPath);

      await _tap(tester, find.text(AppStrings.jobFormSave));

      expect(find.textContaining('Company name is required'), findsWidgets);
      expect(app.jobs.saveCount, 0);
    });

    testWidgets('saves a new application and returns to the list', (
      tester,
    ) async {
      final app = await _open(tester);
      await _tap(tester, find.text(AppStrings.trackerAddJob));

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'BRAC Bank');
      await tester.enterText(fields.at(1), 'Management Trainee');
      await tester.pumpAndSettle();
      await _tap(tester, find.text(JobSource.bdjobs.label));
      await _tap(tester, find.text(JobApplicationStatus.applied.label));
      await _tap(tester, find.text(AppStrings.jobFormNoLinkedCv));
      await _tap(tester, find.text('Frontend Developer CV').last);

      await _tap(tester, find.text(AppStrings.jobFormSave));

      final saved = app.jobs.applications.single;
      expect(saved.companyName, 'BRAC Bank');
      expect(saved.jobTitle, 'Management Trainee');
      expect(saved.jobSource, JobSource.bdjobs);
      expect(saved.status, JobApplicationStatus.applied);
      expect(saved.cvId, 'cv-frontend');
      expect(find.text('Application saved.'), findsOneWidget);
      expect(find.text('Management Trainee'), findsOneWidget);
    });

    testWidgets('picks and clears an optional date', (tester) async {
      await _open(tester, path: RouteNames.jobApplicationFormPath);
      expect(find.byTooltip(AppStrings.jobFormClearDate), findsNothing);

      await _tap(
        tester,
        find.bySemanticsLabel(
          '${AppStrings.jobFormDeadlineDate}, ${AppStrings.jobFormOptional}',
        ),
      );
      await _tap(tester, find.text('OK'));
      expect(find.byTooltip(AppStrings.jobFormClearDate), findsOneWidget);

      await _tap(tester, find.byTooltip(AppStrings.jobFormClearDate));
      expect(find.byTooltip(AppStrings.jobFormClearDate), findsNothing);
    });

    testWidgets('links a cover letter draft', (tester) async {
      final app = await _open(
        tester,
        letters: FakeCoverLetterRepository([_letter()]),
        path: RouteNames.jobApplicationFormPath,
      );
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Acme');
      await tester.enterText(fields.at(1), 'Frontend Developer');
      await tester.pumpAndSettle();

      await _tap(tester, find.text(AppStrings.jobFormNoLinkedCoverLetter));
      await _tap(tester, find.text(_letter().displayTitle).last);
      await _tap(tester, find.text(AppStrings.jobFormSave));

      expect(app.jobs.applications.single.coverLetterId, 'letter-1');
    });

    testWidgets('edits an existing application with its values filled in', (
      tester,
    ) async {
      final app = await _open(
        tester,
        jobs: [_job('1', notes: 'Call on Monday.')],
        path: '${RouteNames.jobApplicationFormPath}?id=1',
      );

      expect(find.text(AppStrings.jobFormEditTitle), findsOneWidget);
      expect(find.text('Acme Ltd.'), findsOneWidget);
      expect(find.text('Call on Monday.'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(1), 'Senior Frontend');
      await tester.pumpAndSettle();
      await _tap(tester, find.text(AppStrings.jobFormSave));

      expect(app.jobs.byId('1')!.jobTitle, 'Senior Frontend');
      expect(app.jobs.applications, hasLength(1));
    });
  });

  group('details', () {
    JobApplication full() => _job(
      '1',
      interviewDate: DateTime(2026, 10, 20),
      notes: 'Bring a portfolio.',
      cvId: 'cv-frontend',
      coverLetterId: 'letter-1',
    );

    testWidgets('shows the dates, links and notes', (tester) async {
      await _open(
        tester,
        jobs: [full()],
        letters: FakeCoverLetterRepository([_letter()]),
        path: '${RouteNames.jobApplicationDetailsPath}?id=1',
      );

      expect(find.text('Frontend Developer'), findsOneWidget);
      expect(find.text('Acme Ltd.'), findsOneWidget);
      expect(
        find.text(DateFormatter.shortDate(DateTime(2026, 10, 20))),
        findsOneWidget,
      );
      expect(find.text('Frontend Developer CV'), findsOneWidget);
      expect(find.text(_letter().displayTitle), findsOneWidget);
      expect(find.text('Bring a portfolio.'), findsOneWidget);
      expect(find.text(AppStrings.jobDetailsNotAdded), findsWidgets);
    });

    testWidgets('a missing linked CV is called out', (tester) async {
      await _open(
        tester,
        jobs: [_job('1', cvId: 'gone')],
        path: '${RouteNames.jobApplicationDetailsPath}?id=1',
      );

      expect(find.text(AppStrings.jobDetailsLinkedCvMissing), findsOneWidget);
    });

    testWidgets('tapping a status updates it', (tester) async {
      final app = await _open(
        tester,
        jobs: [_job('1')],
        path: '${RouteNames.jobApplicationDetailsPath}?id=1',
      );

      await _tap(
        tester,
        find.widgetWithText(AppChip, JobApplicationStatus.offered.label),
      );

      expect(app.jobs.byId('1')!.status, JobApplicationStatus.offered);
      expect(
        find.text(AppStrings.jobDetailsStatusUpdated('Offered')),
        findsOneWidget,
      );
    });

    testWidgets('copies a message template with a snackbar', (tester) async {
      final copied = _mockClipboard(tester);
      await _open(
        tester,
        jobs: [_job('1')],
        path: '${RouteNames.jobApplicationDetailsPath}?id=1',
      );

      await _tap(
        tester,
        find.text(JobApplicationMessageTemplateType.followUp.label),
      );

      expect(copied.single, contains('Acme Ltd.'));
      expect(copied.single, contains('Frontend Developer'));
      expect(
        find.text(
          AppStrings.jobDetailsTemplateCopied(
            JobApplicationMessageTemplateType.followUp.label,
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Archive then Mark as Applied', (tester) async {
      final app = await _open(
        tester,
        jobs: [_job('1')],
        path: '${RouteNames.jobApplicationDetailsPath}?id=1',
      );

      await _tap(tester, find.text(AppStrings.jobDetailsArchive));
      expect(app.jobs.byId('1')!.status, JobApplicationStatus.archived);
      expect(find.text(AppStrings.jobDetailsRestore), findsOneWidget);

      await _tap(tester, find.text(AppStrings.jobDetailsRestore));
      expect(app.jobs.byId('1')!.status, JobApplicationStatus.applied);
    });

    testWidgets('Delete asks first, then removes and returns to the list', (
      tester,
    ) async {
      final app = await _open(tester, jobs: [_job('1')]);
      await _tap(tester, find.text('Frontend Developer'));

      await _tap(tester, find.text(AppStrings.jobDetailsDelete));
      await _tap(tester, find.text(AppStrings.jobDetailsCancel));
      expect(app.jobs.applications, hasLength(1));

      await _tap(tester, find.text(AppStrings.jobDetailsDelete));
      await _tap(
        tester,
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(AppStrings.jobDetailsDelete),
        ),
      );

      expect(app.jobs.applications, isEmpty);
      expect(find.text('Application deleted.'), findsOneWidget);
      expect(find.text(AppStrings.trackerEmptyTitle), findsOneWidget);
    });

    testWidgets('without an id it says the application was not found', (
      tester,
    ) async {
      await _open(tester, path: RouteNames.jobApplicationDetailsPath);

      expect(find.text(AppStrings.jobDetailsNotFoundTitle), findsOneWidget);
    });

    testWidgets('an unknown id says the application was not found', (
      tester,
    ) async {
      await _open(
        tester,
        path: '${RouteNames.jobApplicationDetailsPath}?id=nope',
      );

      expect(find.text(AppStrings.jobDetailsMissingBody), findsOneWidget);
    });
  });
}
