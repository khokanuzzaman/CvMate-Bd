import 'package:careermatebd/core/utils/validators.dart';
import 'package:careermatebd/features/cover_letter/data/repositories/cover_letter_repository_impl.dart';
import 'package:careermatebd/features/cover_letter/domain/entities/cover_letter_draft.dart';
import 'package:careermatebd/features/cv_builder/data/repositories/cv_repository_impl.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/presentation/controllers/cv_builder_controller.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_application.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_application_status.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_source.dart';
import 'package:careermatebd/features/job_tracker/presentation/controllers/job_application_form_state.dart';
import 'package:careermatebd/features/job_tracker/presentation/controllers/job_tracker_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final jobApplicationFormControllerProvider =
    NotifierProvider<JobApplicationFormController, JobApplicationFormState>(
      JobApplicationFormController.new,
    );

class JobApplicationFormController extends Notifier<JobApplicationFormState> {
  @override
  JobApplicationFormState build() => JobApplicationFormState.initial();

  Future<void> initialize({String? applicationId, bool force = false}) async {
    if (state.hasInitialized &&
        !force &&
        state.applicationId == applicationId) {
      return;
    }

    state = state.copyWith(isLoading: true, clearErrorMessage: true);

    try {
      final cvs = await ref.read(cvRepositoryProvider).getAllCvs();
      final coverLetters = await ref
          .read(coverLetterRepositoryProvider)
          .getAllDrafts();

      if (applicationId == null) {
        final activeDraftState = ref.read(cvBuilderControllerProvider);
        final activeCvId = activeDraftState.hasActiveDraft
            ? activeDraftState.draft.id
            : null;

        state = JobApplicationFormState.initial().copyWith(
          hasInitialized: true,
          isLoading: false,
          availableCvs: cvs,
          availableCoverLetters: coverLetters,
          selectedCvId: _findCvId(cvs, activeCvId),
        );
        return;
      }

      final application = await ref
          .read(jobTrackerControllerProvider.notifier)
          .getApplicationById(applicationId);
      if (application == null) {
        state = state.copyWith(
          hasInitialized: true,
          isLoading: false,
          errorMessage: 'Could not load this job application.',
        );
        return;
      }

      state = JobApplicationFormState.initial().copyWith(
        hasInitialized: true,
        isLoading: false,
        applicationId: application.id,
        createdAt: application.createdAt,
        availableCvs: cvs,
        availableCoverLetters: coverLetters,
        selectedCvId: _findCvId(cvs, application.cvId),
        selectedCoverLetterId: _findCoverLetterId(
          coverLetters,
          application.coverLetterId,
        ),
        companyName: application.companyName,
        jobTitle: application.jobTitle,
        jobSource: application.jobSource,
        jobPostLink: application.jobPostLink ?? '',
        appliedDate: application.appliedDate,
        deadlineDate: application.deadlineDate,
        interviewDate: application.interviewDate,
        followUpDate: application.followUpDate,
        status: application.status,
        salaryRange: application.salaryRange ?? '',
        contactPerson: application.contactPerson ?? '',
        contactEmail: application.contactEmail ?? '',
        notes: application.notes,
      );
    } catch (_) {
      state = state.copyWith(
        hasInitialized: true,
        isLoading: false,
        errorMessage: 'Could not load job application form data.',
      );
    }
  }

  void selectCv(String? cvId) {
    if (cvId == state.selectedCvId) {
      return;
    }
    state = state.copyWith(selectedCvId: cvId, clearErrorMessage: true);
  }

  void selectCoverLetter(String? draftId) {
    if (draftId == state.selectedCoverLetterId) {
      return;
    }
    state = state.copyWith(
      selectedCoverLetterId: draftId,
      clearErrorMessage: true,
    );
  }

  void updateCompanyName(String value) {
    if (value == state.companyName) {
      return;
    }
    state = state.copyWith(companyName: value, clearErrorMessage: true);
  }

  void updateJobTitle(String value) {
    if (value == state.jobTitle) {
      return;
    }
    state = state.copyWith(jobTitle: value, clearErrorMessage: true);
  }

  void updateJobSource(JobSource value) {
    if (value == state.jobSource) {
      return;
    }
    state = state.copyWith(jobSource: value, clearErrorMessage: true);
  }

  void updateJobPostLink(String value) {
    if (value == state.jobPostLink) {
      return;
    }
    state = state.copyWith(jobPostLink: value, clearErrorMessage: true);
  }

  void updateAppliedDate(DateTime value) {
    state = state.copyWith(appliedDate: value, clearErrorMessage: true);
  }

  void updateDeadlineDate(DateTime? value) {
    state = state.copyWith(deadlineDate: value, clearErrorMessage: true);
  }

  void updateInterviewDate(DateTime? value) {
    state = state.copyWith(interviewDate: value, clearErrorMessage: true);
  }

  void updateFollowUpDate(DateTime? value) {
    state = state.copyWith(followUpDate: value, clearErrorMessage: true);
  }

  void updateStatus(JobApplicationStatus value) {
    if (value == state.status) {
      return;
    }
    state = state.copyWith(status: value, clearErrorMessage: true);
  }

  void updateSalaryRange(String value) {
    if (value == state.salaryRange) {
      return;
    }
    state = state.copyWith(salaryRange: value, clearErrorMessage: true);
  }

  void updateContactPerson(String value) {
    if (value == state.contactPerson) {
      return;
    }
    state = state.copyWith(contactPerson: value, clearErrorMessage: true);
  }

  void updateContactEmail(String value) {
    if (value == state.contactEmail) {
      return;
    }
    state = state.copyWith(contactEmail: value, clearErrorMessage: true);
  }

  void updateNotes(String value) {
    if (value == state.notes) {
      return;
    }
    state = state.copyWith(notes: value, clearErrorMessage: true);
  }

  Future<String?> save() async {
    final validationError = _validate();
    if (validationError != null) {
      state = state.copyWith(errorMessage: validationError);
      return state.errorMessage;
    }

    final isUpdating = state.isEditing;
    state = state.copyWith(isSaving: true, clearErrorMessage: true);
    final now = DateTime.now();
    final application = JobApplication(
      id: state.applicationId ?? now.microsecondsSinceEpoch.toString(),
      cvId: state.selectedCvId,
      coverLetterId: state.selectedCoverLetterId,
      companyName: state.companyName.trim(),
      jobTitle: state.jobTitle.trim(),
      jobSource: state.jobSource,
      jobPostLink: _optionalText(state.jobPostLink),
      appliedDate: state.appliedDate,
      deadlineDate: state.deadlineDate,
      interviewDate: state.interviewDate,
      followUpDate: state.followUpDate,
      status: state.status,
      salaryRange: _optionalText(state.salaryRange),
      contactPerson: _optionalText(state.contactPerson),
      contactEmail: _optionalText(state.contactEmail),
      notes: state.notes.trim(),
      createdAt: state.createdAt ?? now,
      updatedAt: now,
    );

    try {
      final saved = await ref
          .read(jobTrackerControllerProvider.notifier)
          .saveApplication(application);
      state = state.copyWith(
        isSaving: false,
        applicationId: saved.id,
        createdAt: saved.createdAt,
        clearErrorMessage: true,
      );
      return isUpdating ? 'Application updated.' : 'Application saved.';
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Could not save this application.',
      );
      return state.errorMessage;
    }
  }

  String? _validate() {
    final company = Validators.requiredText(
      state.companyName,
      fieldName: 'Company name',
    );
    if (company != null) {
      return company;
    }

    final title = Validators.requiredText(
      state.jobTitle,
      fieldName: 'Job title',
    );
    if (title != null) {
      return title;
    }

    final jobPostLink = Validators.optionalUrl(state.jobPostLink);
    if (jobPostLink != null) {
      return jobPostLink;
    }

    final contactEmail = Validators.optionalEmail(state.contactEmail);
    if (contactEmail != null) {
      return contactEmail;
    }

    if (state.deadlineDate != null &&
        state.deadlineDate!.isBefore(_normalizeDate(state.appliedDate))) {
      return 'Deadline date cannot be earlier than the applied date.';
    }

    return null;
  }

  DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  String? _optionalText(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  String? _findCvId(List<CvProfile> cvs, String? id) {
    if (id == null) {
      return null;
    }
    for (final cv in cvs) {
      if (cv.id == id) {
        return cv.id;
      }
    }
    return null;
  }

  String? _findCoverLetterId(List<CoverLetterDraft> drafts, String? id) {
    if (id == null) {
      return null;
    }
    for (final draft in drafts) {
      if (draft.id == id) {
        return draft.id;
      }
    }
    return null;
  }
}
