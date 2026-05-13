import 'package:careermatebd/features/cover_letter/domain/entities/cover_letter_draft.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_application_status.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_source.dart';

const Object _jobFormUnset = Object();

class JobApplicationFormState {
  const JobApplicationFormState({
    required this.hasInitialized,
    required this.isLoading,
    required this.isSaving,
    required this.applicationId,
    required this.createdAt,
    required this.availableCvs,
    required this.availableCoverLetters,
    required this.selectedCvId,
    required this.selectedCoverLetterId,
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
    required this.errorMessage,
  });

  factory JobApplicationFormState.initial() => JobApplicationFormState(
    hasInitialized: false,
    isLoading: false,
    isSaving: false,
    applicationId: null,
    createdAt: null,
    availableCvs: const [],
    availableCoverLetters: const [],
    selectedCvId: null,
    selectedCoverLetterId: null,
    companyName: '',
    jobTitle: '',
    jobSource: JobSource.bdjobs,
    jobPostLink: '',
    appliedDate: DateTime.now(),
    deadlineDate: null,
    interviewDate: null,
    followUpDate: null,
    status: JobApplicationStatus.draft,
    salaryRange: '',
    contactPerson: '',
    contactEmail: '',
    notes: '',
    errorMessage: null,
  );

  final bool hasInitialized;
  final bool isLoading;
  final bool isSaving;
  final String? applicationId;
  final DateTime? createdAt;
  final List<CvProfile> availableCvs;
  final List<CoverLetterDraft> availableCoverLetters;
  final String? selectedCvId;
  final String? selectedCoverLetterId;
  final String companyName;
  final String jobTitle;
  final JobSource jobSource;
  final String jobPostLink;
  final DateTime appliedDate;
  final DateTime? deadlineDate;
  final DateTime? interviewDate;
  final DateTime? followUpDate;
  final JobApplicationStatus status;
  final String salaryRange;
  final String contactPerson;
  final String contactEmail;
  final String notes;
  final String? errorMessage;

  bool get isEditing => applicationId != null;

  JobApplicationFormState copyWith({
    bool? hasInitialized,
    bool? isLoading,
    bool? isSaving,
    Object? applicationId = _jobFormUnset,
    Object? createdAt = _jobFormUnset,
    List<CvProfile>? availableCvs,
    List<CoverLetterDraft>? availableCoverLetters,
    Object? selectedCvId = _jobFormUnset,
    Object? selectedCoverLetterId = _jobFormUnset,
    String? companyName,
    String? jobTitle,
    JobSource? jobSource,
    String? jobPostLink,
    DateTime? appliedDate,
    Object? deadlineDate = _jobFormUnset,
    Object? interviewDate = _jobFormUnset,
    Object? followUpDate = _jobFormUnset,
    JobApplicationStatus? status,
    String? salaryRange,
    String? contactPerson,
    String? contactEmail,
    String? notes,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return JobApplicationFormState(
      hasInitialized: hasInitialized ?? this.hasInitialized,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      applicationId: identical(applicationId, _jobFormUnset)
          ? this.applicationId
          : applicationId as String?,
      createdAt: identical(createdAt, _jobFormUnset)
          ? this.createdAt
          : createdAt as DateTime?,
      availableCvs: availableCvs ?? this.availableCvs,
      availableCoverLetters:
          availableCoverLetters ?? this.availableCoverLetters,
      selectedCvId: identical(selectedCvId, _jobFormUnset)
          ? this.selectedCvId
          : selectedCvId as String?,
      selectedCoverLetterId: identical(selectedCoverLetterId, _jobFormUnset)
          ? this.selectedCoverLetterId
          : selectedCoverLetterId as String?,
      companyName: companyName ?? this.companyName,
      jobTitle: jobTitle ?? this.jobTitle,
      jobSource: jobSource ?? this.jobSource,
      jobPostLink: jobPostLink ?? this.jobPostLink,
      appliedDate: appliedDate ?? this.appliedDate,
      deadlineDate: identical(deadlineDate, _jobFormUnset)
          ? this.deadlineDate
          : deadlineDate as DateTime?,
      interviewDate: identical(interviewDate, _jobFormUnset)
          ? this.interviewDate
          : interviewDate as DateTime?,
      followUpDate: identical(followUpDate, _jobFormUnset)
          ? this.followUpDate
          : followUpDate as DateTime?,
      status: status ?? this.status,
      salaryRange: salaryRange ?? this.salaryRange,
      contactPerson: contactPerson ?? this.contactPerson,
      contactEmail: contactEmail ?? this.contactEmail,
      notes: notes ?? this.notes,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}
