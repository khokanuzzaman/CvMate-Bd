import 'package:careermatebd/core/utils/date_formatter.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_application.dart';

enum JobApplicationMessageTemplateType {
  followUp,
  interviewConfirmation,
  statusInquiry,
}

extension JobApplicationMessageTemplateTypeX
    on JobApplicationMessageTemplateType {
  String get label => switch (this) {
    JobApplicationMessageTemplateType.followUp => 'Follow-up email/message',
    JobApplicationMessageTemplateType.interviewConfirmation =>
      'Interview confirmation reply',
    JobApplicationMessageTemplateType.statusInquiry =>
      'Application status inquiry',
  };
}

class JobApplicationMessageTemplates {
  const JobApplicationMessageTemplates._();

  static String build(
    JobApplicationMessageTemplateType type,
    JobApplication application,
  ) {
    final contactName = application.contactPerson?.trim();
    final greeting = (contactName == null || contactName.isEmpty)
        ? 'Hello'
        : 'Hello $contactName';
    final role = application.jobTitle.trim().isEmpty
        ? 'the role'
        : application.jobTitle.trim();
    final company = application.companyName.trim().isEmpty
        ? 'your company'
        : application.companyName.trim();

    return switch (type) {
      JobApplicationMessageTemplateType.followUp =>
        '$greeting,\n\nI hope you are well. I am following up on my application for the $role position at $company, which I submitted on ${DateFormatter.shortDate(application.appliedDate)}. I remain interested in the opportunity and would appreciate any update regarding the next steps.\n\nThank you for your time.\n',
      JobApplicationMessageTemplateType.interviewConfirmation =>
        '$greeting,\n\nThank you for the interview invitation for the $role position at $company. I confirm my availability${application.interviewDate == null ? '' : ' for ${DateFormatter.shortDate(application.interviewDate!)}'}. Please let me know if there is anything specific I should prepare in advance.\n\nBest regards,\n',
      JobApplicationMessageTemplateType.statusInquiry =>
        '$greeting,\n\nI wanted to ask whether there is any update on the status of my application for the $role position at $company. I would be grateful for any update you can share.\n\nThank you.\n',
    };
  }
}
