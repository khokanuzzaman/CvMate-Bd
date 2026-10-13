import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/utils/date_formatter.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_application_next_action.dart';

/// The one-line hint shown on an application card, e.g.
/// "Interview Thu · Prep now" or "Applied 8 days ago · Send a follow-up".
String jobNextActionText(JobNextAction action, {DateTime? now}) {
  return switch (action.kind) {
    JobNextActionKind.interview => AppStrings.trackerHintInterview(
      _when(action.interviewDate!, now ?? DateTime.now()),
    ),
    JobNextActionKind.followUpDue => AppStrings.trackerHintFollowUpDue,
    JobNextActionKind.applied => AppStrings.trackerHintApplied(
      action.daysSinceApplied!,
    ),
  };
}

/// "today", "tomorrow", a weekday within the coming week, else the date; the
/// time is appended only when the date carries one.
String _when(DateTime date, DateTime now) {
  final local = date.toLocal();
  final days = DateTime(
    local.year,
    local.month,
    local.day,
  ).difference(DateTime(now.year, now.month, now.day)).inDays;
  final day = switch (days) {
    0 => AppStrings.trackerToday,
    1 => AppStrings.trackerTomorrow,
    < 7 => DateFormatter.weekdayShort(local),
    _ => DateFormatter.shortDate(local),
  };
  final hasTime = local.hour != 0 || local.minute != 0;
  return hasTime ? '$day, ${DateFormatter.shortTime(local)}' : day;
}
