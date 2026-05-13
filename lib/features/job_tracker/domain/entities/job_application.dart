import 'package:careermatebd/features/job_tracker/domain/entities/job_application_status.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_source.dart';

const Object _jobApplicationUnset = Object();

class JobApplication {
  const JobApplication({
    required this.id,
    required this.cvId,
    required this.coverLetterId,
    required this.companyName,
    required this.jobTitle,
    required this.jobSource,
    required this.jobPostLink,
    required this.appliedDate,
    required this.deadlineDate,
    required this.interviewDate,
    required this.followUpDate,
    required this.status,
    required this.salaryRange,
    required this.contactPerson,
    required this.contactEmail,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? cvId;
  final String? coverLetterId;
  final String companyName;
  final String jobTitle;
  final JobSource jobSource;
  final String? jobPostLink;
  final DateTime appliedDate;
  final DateTime? deadlineDate;
  final DateTime? interviewDate;
  final DateTime? followUpDate;
  final JobApplicationStatus status;
  final String? salaryRange;
  final String? contactPerson;
  final String? contactEmail;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory JobApplication.empty() {
    final now = DateTime.now();
    return JobApplication(
      id: now.microsecondsSinceEpoch.toString(),
      cvId: null,
      coverLetterId: null,
      companyName: '',
      jobTitle: '',
      jobSource: JobSource.bdjobs,
      jobPostLink: null,
      appliedDate: now,
      deadlineDate: null,
      interviewDate: null,
      followUpDate: null,
      status: JobApplicationStatus.draft,
      salaryRange: null,
      contactPerson: null,
      contactEmail: null,
      notes: '',
      createdAt: now,
      updatedAt: now,
    );
  }

  JobApplication copyWith({
    String? id,
    Object? cvId = _jobApplicationUnset,
    Object? coverLetterId = _jobApplicationUnset,
    String? companyName,
    String? jobTitle,
    JobSource? jobSource,
    Object? jobPostLink = _jobApplicationUnset,
    DateTime? appliedDate,
    Object? deadlineDate = _jobApplicationUnset,
    Object? interviewDate = _jobApplicationUnset,
    Object? followUpDate = _jobApplicationUnset,
    JobApplicationStatus? status,
    Object? salaryRange = _jobApplicationUnset,
    Object? contactPerson = _jobApplicationUnset,
    Object? contactEmail = _jobApplicationUnset,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JobApplication(
      id: id ?? this.id,
      cvId: identical(cvId, _jobApplicationUnset) ? this.cvId : cvId as String?,
      coverLetterId: identical(coverLetterId, _jobApplicationUnset)
          ? this.coverLetterId
          : coverLetterId as String?,
      companyName: companyName ?? this.companyName,
      jobTitle: jobTitle ?? this.jobTitle,
      jobSource: jobSource ?? this.jobSource,
      jobPostLink: identical(jobPostLink, _jobApplicationUnset)
          ? this.jobPostLink
          : jobPostLink as String?,
      appliedDate: appliedDate ?? this.appliedDate,
      deadlineDate: identical(deadlineDate, _jobApplicationUnset)
          ? this.deadlineDate
          : deadlineDate as DateTime?,
      interviewDate: identical(interviewDate, _jobApplicationUnset)
          ? this.interviewDate
          : interviewDate as DateTime?,
      followUpDate: identical(followUpDate, _jobApplicationUnset)
          ? this.followUpDate
          : followUpDate as DateTime?,
      status: status ?? this.status,
      salaryRange: identical(salaryRange, _jobApplicationUnset)
          ? this.salaryRange
          : salaryRange as String?,
      contactPerson: identical(contactPerson, _jobApplicationUnset)
          ? this.contactPerson
          : contactPerson as String?,
      contactEmail: identical(contactEmail, _jobApplicationUnset)
          ? this.contactEmail
          : contactEmail as String?,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get displayTitle {
    final title = jobTitle.trim();
    final company = companyName.trim();
    if (title.isNotEmpty && company.isNotEmpty) {
      return '$title at $company';
    }
    if (title.isNotEmpty) {
      return title;
    }
    if (company.isNotEmpty) {
      return company;
    }
    return 'Untitled application';
  }

  bool get hasLinkedCv => cvId != null && cvId!.trim().isNotEmpty;
  bool get hasLinkedCoverLetter =>
      coverLetterId != null && coverLetterId!.trim().isNotEmpty;

  bool get needsFollowUp {
    if (followUpDate == null || status.isFinal) {
      return false;
    }

    final today = DateTime.now();
    final dueDate = DateTime(
      followUpDate!.year,
      followUpDate!.month,
      followUpDate!.day,
    );
    final currentDate = DateTime(today.year, today.month, today.day);
    return !dueDate.isAfter(currentDate);
  }
}
