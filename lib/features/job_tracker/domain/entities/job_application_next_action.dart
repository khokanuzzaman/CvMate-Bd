import 'package:careermatebd/features/job_tracker/domain/entities/job_application.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_application_status.dart';

enum JobNextActionKind {
  /// An interview is coming up — prepare for it.
  interview,

  /// The follow-up date the user set has arrived.
  followUpDue,

  /// Sent, and waiting; a nudge once it has been a week.
  applied,
}

/// The most useful next step for an application, derived only from fields the
/// user already entered (interview date, follow-up date, applied date).
class JobNextAction {
  const JobNextAction._(this.kind, {this.interviewDate, this.daysSinceApplied});

  final JobNextActionKind kind;

  /// Set for [JobNextActionKind.interview].
  final DateTime? interviewDate;

  /// Set for [JobNextActionKind.applied].
  final int? daysSinceApplied;

  /// Null when there is nothing to suggest (drafts, finished applications, or
  /// an interview status with no upcoming date).
  static JobNextAction? of(JobApplication application, {DateTime? now}) {
    final today = _dateOnly(now ?? DateTime.now());
    final status = application.status;
    if (status == JobApplicationStatus.draft || status.isFinal) {
      return null;
    }

    final interview = application.interviewDate;
    if (interview != null && !_dateOnly(interview).isBefore(today)) {
      return JobNextAction._(
        JobNextActionKind.interview,
        interviewDate: interview,
      );
    }

    final followUp = application.followUpDate;
    if (followUp != null && !_dateOnly(followUp).isAfter(today)) {
      return const JobNextAction._(JobNextActionKind.followUpDue);
    }

    if (status == JobApplicationStatus.applied ||
        status == JobApplicationStatus.shortlisted) {
      final days = today.difference(_dateOnly(application.appliedDate)).inDays;
      return JobNextAction._(
        JobNextActionKind.applied,
        daysSinceApplied: days < 0 ? 0 : days,
      );
    }
    return null;
  }

  static DateTime _dateOnly(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }
}
