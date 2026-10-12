import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/utils/date_formatter.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/widgets/app_card.dart';
import 'package:careermatebd/core/widgets/app_text_field.dart';
import 'package:careermatebd/core/widgets/choice_chips.dart';
import 'package:careermatebd/core/widgets/cv_picker.dart';
import 'package:careermatebd/core/widgets/picker_field.dart';
import 'package:careermatebd/core/widgets/section_label.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_application_status.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_source.dart';
import 'package:careermatebd/features/job_tracker/presentation/controllers/job_application_form_state.dart';
import 'package:flutter/material.dart';

/// Text controllers for the form's text fields, owned by the screen.
class JobFormControllers {
  const JobFormControllers({
    required this.company,
    required this.jobTitle,
    required this.jobPostLink,
    required this.salaryRange,
    required this.contactPerson,
    required this.contactEmail,
    required this.notes,
  });

  final TextEditingController company;
  final TextEditingController jobTitle;
  final TextEditingController jobPostLink;
  final TextEditingController salaryRange;
  final TextEditingController contactPerson;
  final TextEditingController contactEmail;
  final TextEditingController notes;
}

/// A form section: an uppercase label above a card.
class JobFormSection extends StatelessWidget {
  const JobFormSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(alignment: Alignment.centerLeft, child: SectionLabel(title)),
        const SizedBox(height: AppSpacing.s8),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ],
    );
  }
}

/// Company, job title and where the job was found.
class JobFormBasics extends StatelessWidget {
  const JobFormBasics({
    super.key,
    required this.state,
    required this.form,
    required this.onSourceChanged,
  });

  final JobApplicationFormState state;
  final JobFormControllers form;
  final ValueChanged<JobSource> onSourceChanged;

  @override
  Widget build(BuildContext context) {
    return JobFormSection(
      title: AppStrings.jobFormBasics,
      children: [
        AppTextField(
          controller: form.company,
          label: AppStrings.jobFormCompany,
          hintText: AppStrings.jobFormCompanyHint,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.s14),
        AppTextField(
          controller: form.jobTitle,
          label: AppStrings.jobFormJobTitle,
          hintText: AppStrings.jobFormJobTitleHint,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.s14),
        const _FieldLabel(AppStrings.jobFormSource),
        const SizedBox(height: AppSpacing.s4),
        ChoiceChips<JobSource>(
          options: JobSource.values,
          value: state.jobSource,
          labelOf: (source) => source.label,
          onChanged: onSourceChanged,
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppTextStyles.fieldLabel);
}

/// The CV and cover letter used for the application.
class JobFormLinks extends StatelessWidget {
  const JobFormLinks({
    super.key,
    required this.state,
    required this.onPickCv,
    required this.onPickCoverLetter,
  });

  final JobApplicationFormState state;
  final VoidCallback onPickCv;
  final VoidCallback onPickCoverLetter;

  @override
  Widget build(BuildContext context) {
    String? coverLetterTitle;
    for (final draft in state.availableCoverLetters) {
      if (draft.id == state.selectedCoverLetterId) {
        coverLetterTitle = draft.displayTitle;
      }
    }

    return JobFormSection(
      title: AppStrings.jobFormLinked,
      children: [
        Text(
          AppStrings.jobFormLinkedBody,
          style: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: AppSpacing.s12),
        const _FieldLabel(AppStrings.jobFormLinkedCv),
        const SizedBox(height: AppSpacing.s6),
        CvPickerCard(
          cv: _selectedCv(),
          emptyLabel: AppStrings.jobFormNoLinkedCv,
          onTap: onPickCv,
        ),
        const SizedBox(height: AppSpacing.s14),
        PickerField(
          label: AppStrings.jobFormLinkedCoverLetter,
          value: coverLetterTitle ?? AppStrings.jobFormNoLinkedCoverLetter,
          hasValue: coverLetterTitle != null,
          onTap: onPickCoverLetter,
        ),
      ],
    );
  }

  CvProfile? _selectedCv() {
    for (final cv in state.availableCvs) {
      if (cv.id == state.selectedCvId) {
        return cv;
      }
    }
    return null;
  }
}

/// Status and the four dates.
class JobFormTimeline extends StatelessWidget {
  const JobFormTimeline({
    super.key,
    required this.state,
    required this.onStatusChanged,
    required this.onPickApplied,
    required this.onPickDeadline,
    required this.onClearDeadline,
    required this.onPickInterview,
    required this.onClearInterview,
    required this.onPickFollowUp,
    required this.onClearFollowUp,
  });

  final JobApplicationFormState state;
  final ValueChanged<JobApplicationStatus> onStatusChanged;
  final VoidCallback onPickApplied;
  final VoidCallback onPickDeadline;
  final VoidCallback onClearDeadline;
  final VoidCallback onPickInterview;
  final VoidCallback onClearInterview;
  final VoidCallback onPickFollowUp;
  final VoidCallback onClearFollowUp;

  @override
  Widget build(BuildContext context) {
    return JobFormSection(
      title: AppStrings.jobFormTimeline,
      children: [
        const _FieldLabel(AppStrings.jobFormStatus),
        const SizedBox(height: AppSpacing.s4),
        ChoiceChips<JobApplicationStatus>(
          options: JobApplicationStatus.values,
          value: state.status,
          labelOf: (status) => status.label,
          onChanged: onStatusChanged,
        ),
        const SizedBox(height: AppSpacing.s8),
        PickerField(
          label: AppStrings.jobFormAppliedDate,
          value: DateFormatter.shortDate(state.appliedDate),
          icon: Icons.calendar_today_outlined,
          onTap: onPickApplied,
        ),
        const SizedBox(height: AppSpacing.s12),
        _optionalDate(
          AppStrings.jobFormDeadlineDate,
          state.deadlineDate,
          onPickDeadline,
          onClearDeadline,
        ),
        const SizedBox(height: AppSpacing.s12),
        _optionalDate(
          AppStrings.jobFormInterviewDate,
          state.interviewDate,
          onPickInterview,
          onClearInterview,
        ),
        const SizedBox(height: AppSpacing.s12),
        _optionalDate(
          AppStrings.jobFormFollowUpDate,
          state.followUpDate,
          onPickFollowUp,
          onClearFollowUp,
        ),
      ],
    );
  }

  Widget _optionalDate(
    String label,
    DateTime? value,
    VoidCallback onPick,
    VoidCallback onClear,
  ) {
    return PickerField(
      label: label,
      value: value == null
          ? AppStrings.jobFormOptional
          : DateFormatter.shortDate(value),
      hasValue: value != null,
      icon: Icons.calendar_today_outlined,
      onTap: onPick,
      onClear: value == null ? null : onClear,
      clearTooltip: AppStrings.jobFormClearDate,
    );
  }
}

/// Link, salary, contact and notes.
class JobFormReference extends StatelessWidget {
  const JobFormReference({super.key, required this.form});

  final JobFormControllers form;

  @override
  Widget build(BuildContext context) {
    return JobFormSection(
      title: AppStrings.jobFormReference,
      children: [
        AppTextField(
          controller: form.jobPostLink,
          label: AppStrings.jobFormLink,
          hintText: AppStrings.jobFormOptional,
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: AppSpacing.s14),
        AppTextField(
          controller: form.salaryRange,
          label: AppStrings.jobFormSalary,
          hintText: AppStrings.jobFormOptional,
        ),
        const SizedBox(height: AppSpacing.s14),
        AppTextField(
          controller: form.contactPerson,
          label: AppStrings.jobFormContactPerson,
          hintText: AppStrings.jobFormOptional,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: AppSpacing.s14),
        AppTextField(
          controller: form.contactEmail,
          label: AppStrings.jobFormContactEmail,
          hintText: AppStrings.jobFormOptional,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: AppSpacing.s14),
        AppTextArea(
          controller: form.notes,
          label: AppStrings.jobFormNotes,
          hintText: AppStrings.jobFormNotesHint,
          minLines: 4,
          maxLines: 6,
        ),
      ],
    );
  }
}
