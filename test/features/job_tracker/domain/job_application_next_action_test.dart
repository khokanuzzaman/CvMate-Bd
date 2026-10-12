import 'package:careermatebd/features/job_tracker/domain/entities/job_application.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_application_next_action.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_application_status.dart';
import 'package:flutter_test/flutter_test.dart';

// A Wednesday, so "Thu" is tomorrow.
final DateTime _now = DateTime(2026, 10, 14, 9, 0);

JobApplication _app({
  JobApplicationStatus status = JobApplicationStatus.applied,
  int appliedDaysAgo = 2,
  DateTime? interviewDate,
  DateTime? followUpDate,
}) {
  return JobApplication.empty().copyWith(
    status: status,
    appliedDate: _now.subtract(Duration(days: appliedDaysAgo)),
    interviewDate: interviewDate,
    followUpDate: followUpDate,
  );
}

JobNextAction? _of(JobApplication application) =>
    JobNextAction.of(application, now: _now);

void main() {
  group('interview', () {
    test('an upcoming interview comes first', () {
      final interview = DateTime(2026, 10, 15, 10, 30);
      final action = _of(
        _app(
          status: JobApplicationStatus.interview,
          interviewDate: interview,
          followUpDate: DateTime(2026, 10, 1),
        ),
      )!;

      expect(action.kind, JobNextActionKind.interview);
      expect(action.interviewDate, interview);
    });

    test('an interview today still counts', () {
      final action = _of(
        _app(
          status: JobApplicationStatus.interview,
          interviewDate: DateTime(2026, 10, 14, 8, 0),
        ),
      )!;

      expect(action.kind, JobNextActionKind.interview);
    });

    test('a past interview is not an upcoming one', () {
      final action = _of(
        _app(
          status: JobApplicationStatus.interview,
          interviewDate: DateTime(2026, 10, 10),
        ),
      );

      expect(action, isNull);
    });
  });

  group('follow-up', () {
    test('a follow-up date that has arrived is due', () {
      final action = _of(_app(followUpDate: DateTime(2026, 10, 14)))!;

      expect(action.kind, JobNextActionKind.followUpDue);
    });

    test('a future follow-up date is not due yet', () {
      final action = _of(_app(followUpDate: DateTime(2026, 10, 20)))!;

      expect(action.kind, JobNextActionKind.applied);
    });
  });

  group('applied', () {
    test('counts the days since the application', () {
      final action = _of(_app(appliedDaysAgo: 8))!;

      expect(action.kind, JobNextActionKind.applied);
      expect(action.daysSinceApplied, 8);
    });

    test('a date in the future counts as zero days', () {
      final action = _of(_app(appliedDaysAgo: -3))!;

      expect(action.daysSinceApplied, 0);
    });

    test('shortlisted applications are tracked the same way', () {
      final action = _of(_app(status: JobApplicationStatus.shortlisted))!;

      expect(action.kind, JobNextActionKind.applied);
    });
  });

  group('nothing to suggest', () {
    test('drafts and finished applications have no next action', () {
      for (final status in [
        JobApplicationStatus.draft,
        JobApplicationStatus.offered,
        JobApplicationStatus.rejected,
        JobApplicationStatus.archived,
      ]) {
        expect(_of(_app(status: status)), isNull, reason: status.name);
      }
    });

    test('an interview with no date has none either', () {
      expect(_of(_app(status: JobApplicationStatus.interview)), isNull);
    });
  });
}
