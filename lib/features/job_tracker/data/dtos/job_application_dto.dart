import 'dart:convert';

import 'package:careermatebd/features/job_tracker/domain/entities/job_application.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_application_status.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_source.dart';

class JobApplicationDto {
  const JobApplicationDto(this.application);

  final JobApplication application;

  factory JobApplicationDto.fromJson(String source) {
    final map = jsonDecode(source) as Map<String, dynamic>;
    return JobApplicationDto(_fromMap(map));
  }

  String toJson() => jsonEncode(_toMap(application));

  static JobApplication _fromMap(Map<String, dynamic> map) {
    return JobApplication(
      id: map['id'] as String? ?? '',
      cvId: _optionalString(map['cvId']),
      coverLetterId: _optionalString(map['coverLetterId']),
      companyName: map['companyName'] as String? ?? '',
      jobTitle: map['jobTitle'] as String? ?? '',
      jobSource: JobSource.values.firstWhere(
        (value) => value.name == map['jobSource'],
        orElse: () => JobSource.bdjobs,
      ),
      jobPostLink: _optionalString(map['jobPostLink']),
      appliedDate:
          DateTime.tryParse(map['appliedDate'] as String? ?? '') ??
          DateTime.now(),
      deadlineDate: _optionalDate(map['deadlineDate']),
      interviewDate: _optionalDate(map['interviewDate']),
      followUpDate: _optionalDate(map['followUpDate']),
      status: JobApplicationStatus.values.firstWhere(
        (value) => value.name == map['status'],
        orElse: () => JobApplicationStatus.draft,
      ),
      salaryRange: _optionalString(map['salaryRange']),
      contactPerson: _optionalString(map['contactPerson']),
      contactEmail: _optionalString(map['contactEmail']),
      notes: map['notes'] as String? ?? '',
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  static Map<String, dynamic> _toMap(JobApplication value) {
    return {
      'id': value.id,
      'cvId': value.cvId,
      'coverLetterId': value.coverLetterId,
      'companyName': value.companyName,
      'jobTitle': value.jobTitle,
      'jobSource': value.jobSource.name,
      'jobPostLink': value.jobPostLink,
      'appliedDate': value.appliedDate.toIso8601String(),
      'deadlineDate': value.deadlineDate?.toIso8601String(),
      'interviewDate': value.interviewDate?.toIso8601String(),
      'followUpDate': value.followUpDate?.toIso8601String(),
      'status': value.status.name,
      'salaryRange': value.salaryRange,
      'contactPerson': value.contactPerson,
      'contactEmail': value.contactEmail,
      'notes': value.notes,
      'createdAt': value.createdAt.toIso8601String(),
      'updatedAt': value.updatedAt.toIso8601String(),
    };
  }

  static String? _optionalString(Object? value) {
    if (value == null) {
      return null;
    }

    final normalized = value.toString().trim();
    return normalized.isEmpty ? null : normalized;
  }

  static DateTime? _optionalDate(Object? value) {
    final raw = _optionalString(value);
    if (raw == null) {
      return null;
    }

    return DateTime.tryParse(raw);
  }
}
