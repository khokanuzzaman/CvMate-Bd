import 'package:careermatebd/features/job_tracker/domain/entities/job_application.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_application_status.dart';
import 'package:careermatebd/features/job_tracker/presentation/controllers/job_tracker_controller.dart';
import 'package:flutter_test/flutter_test.dart';

JobApplication _app(JobApplicationStatus status) =>
    JobApplication.empty().copyWith(status: status);

void main() {
  test('counts sent, interview, offered and closed applications', () {
    final summary = JobTrackerSummary.fromApplications([
      _app(JobApplicationStatus.draft),
      _app(JobApplicationStatus.applied),
      _app(JobApplicationStatus.applied),
      _app(JobApplicationStatus.shortlisted),
      _app(JobApplicationStatus.interview),
      _app(JobApplicationStatus.offered),
      _app(JobApplicationStatus.rejected),
      _app(JobApplicationStatus.archived),
    ]);

    expect(summary.total, 8);
    expect(summary.submitted, 7); // everything but the draft
    expect(summary.interviews, 1);
    expect(summary.offers, 1);
    expect(summary.closed, 2); // rejected + archived
    expect(summary.shortlisted, 1);
  });

  test('an empty tracker is all zeros', () {
    final summary = JobTrackerSummary.fromApplications(const []);

    expect(summary.total, 0);
    expect(summary.submitted, 0);
    expect(summary.closed, 0);
  });
}
