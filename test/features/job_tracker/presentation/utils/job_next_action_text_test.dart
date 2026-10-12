import 'package:careermatebd/features/job_tracker/domain/entities/job_application.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_application_next_action.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_application_status.dart';
import 'package:careermatebd/features/job_tracker/presentation/utils/job_next_action_text.dart';
import 'package:flutter_test/flutter_test.dart';

// Wednesday 14 Oct 2026.
final DateTime _now = DateTime(2026, 10, 14, 9, 0);

String _interview(DateTime date) {
  final action = JobNextAction.of(
    JobApplication.empty().copyWith(
      status: JobApplicationStatus.interview,
      interviewDate: date,
    ),
    now: _now,
  )!;
  return jobNextActionText(action, now: _now);
}

String _applied(int daysAgo, {DateTime? followUp}) {
  final action = JobNextAction.of(
    JobApplication.empty().copyWith(
      status: JobApplicationStatus.applied,
      appliedDate: _now.subtract(Duration(days: daysAgo)),
      followUpDate: followUp,
    ),
    now: _now,
  )!;
  return jobNextActionText(action, now: _now);
}

void main() {
  group('interview', () {
    test('names the weekday and the time', () {
      expect(
        _interview(DateTime(2026, 10, 16, 10, 30)),
        'Interview Fri, 10:30 AM · Prep now',
      );
    });

    test('leaves the time out when the date has none', () {
      expect(_interview(DateTime(2026, 10, 16)), 'Interview Fri · Prep now');
    });

    test('says today and tomorrow', () {
      expect(_interview(DateTime(2026, 10, 14)), 'Interview today · Prep now');
      expect(
        _interview(DateTime(2026, 10, 15, 15, 0)),
        'Interview tomorrow, 3:00 PM · Prep now',
      );
    });

    test('uses the date beyond a week', () {
      expect(
        _interview(DateTime(2026, 10, 28)),
        'Interview 28 Oct 2026 · Prep now',
      );
    });
  });

  group('applied', () {
    test('counts days', () {
      expect(_applied(0), 'Applied today');
      expect(_applied(1), 'Applied 1 day ago');
      expect(_applied(3), 'Applied 3 days ago');
    });

    test('suggests a follow-up from a week on', () {
      expect(_applied(6), 'Applied 6 days ago');
      expect(_applied(8), 'Applied 8 days ago · Send a follow-up');
    });
  });

  test('a due follow-up is called out', () {
    expect(
      _applied(2, followUp: DateTime(2026, 10, 13)),
      'Follow-up due · Send a follow-up',
    );
  });
}
