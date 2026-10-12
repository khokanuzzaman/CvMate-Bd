import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/utils/date_formatter.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/core/widgets/app_card.dart';
import 'package:careermatebd/core/widgets/choice_chips.dart';
import 'package:careermatebd/core/widgets/custom_empty_state.dart';
import 'package:careermatebd/core/widgets/section_label.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_application.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_application_message_templates.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_application_status.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_source.dart';
import 'package:careermatebd/features/job_tracker/presentation/widgets/job_status_chip.dart';
import 'package:careermatebd/features/job_tracker/presentation/widgets/job_tag.dart';
import 'package:flutter/material.dart';

/// Role, company, status and the source / created / follow-up tags.
class JobDetailsHeader extends StatelessWidget {
  const JobDetailsHeader({super.key, required this.application});

  final JobApplication application;

  @override
  Widget build(BuildContext context) {
    final title = application.jobTitle.trim();
    final company = application.companyName.trim();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.isEmpty ? AppStrings.trackerUntitledRole : title,
                      style: AppTextStyles.title,
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      company.isEmpty
                          ? AppStrings.trackerUnknownCompany
                          : company,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              JobStatusChip(status: application.status),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [
              JobTag(label: application.jobSource.label),
              JobTag(
                label: AppStrings.jobDetailsCreated(
                  DateFormatter.shortDate(application.createdAt),
                ),
              ),
              if (application.needsFollowUp)
                const JobTag(
                  label: AppStrings.trackerFollowUpDue,
                  tone: JobTagTone.amber,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tap a status to move the application there.
class JobDetailsStatusCard extends StatelessWidget {
  const JobDetailsStatusCard({
    super.key,
    required this.status,
    required this.onChanged,
  });

  final JobApplicationStatus status;
  final ValueChanged<JobApplicationStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel(AppStrings.jobDetailsUpdateStatus),
          const SizedBox(height: AppSpacing.s4),
          ChoiceChips<JobApplicationStatus>(
            options: JobApplicationStatus.values,
            value: status,
            labelOf: (item) => item.label,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// Dates and contact details as label / value rows.
class JobDetailsInfoCard extends StatelessWidget {
  const JobDetailsInfoCard({super.key, required this.application});

  final JobApplication application;

  String _date(DateTime? value) => value == null
      ? AppStrings.jobDetailsNotAdded
      : DateFormatter.shortDate(value);

  String _text(String? value) => value == null || value.trim().isEmpty
      ? AppStrings.jobDetailsNotAdded
      : value;

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      rows: [
        (AppStrings.jobDetailsApplied, _date(application.appliedDate)),
        (AppStrings.jobDetailsDeadline, _date(application.deadlineDate)),
        (AppStrings.jobDetailsInterview, _date(application.interviewDate)),
        (AppStrings.jobDetailsFollowUp, _date(application.followUpDate)),
        (AppStrings.jobDetailsLink, _text(application.jobPostLink)),
        (AppStrings.jobDetailsSalary, _text(application.salaryRange)),
        (AppStrings.jobDetailsContact, _text(application.contactPerson)),
        (AppStrings.jobDetailsEmail, _text(application.contactEmail)),
      ],
    );
  }
}

/// The linked CV and cover letter, or why they are missing.
class JobDetailsLinkedCard extends StatelessWidget {
  const JobDetailsLinkedCard({
    super.key,
    required this.application,
    required this.linkedCvTitle,
    required this.linkedCoverLetterTitle,
  });

  final JobApplication application;
  final String? linkedCvTitle;
  final String? linkedCoverLetterTitle;

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      rows: [
        (
          AppStrings.jobDetailsLinkedCv,
          linkedCvTitle ??
              (application.hasLinkedCv
                  ? AppStrings.jobDetailsLinkedCvMissing
                  : AppStrings.jobDetailsNoLinkedCv),
        ),
        (
          AppStrings.jobDetailsLinkedCoverLetter,
          linkedCoverLetterTitle ??
              (application.hasLinkedCoverLetter
                  ? AppStrings.jobDetailsLinkedCoverLetterMissing
                  : AppStrings.jobDetailsNoLinkedCoverLetter),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          for (final (index, row) in rows.indexed) ...[
            if (index > 0)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.s10),
                child: Divider(height: 1, color: AppColors.line),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 128,
                  child: Text(
                    row.$1,
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Text(
                    row.$2,
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// The notes, or a prompt to add some.
class JobDetailsNotesCard extends StatelessWidget {
  const JobDetailsNotesCard({super.key, required this.notes});

  final String notes;

  @override
  Widget build(BuildContext context) {
    if (notes.trim().isEmpty) {
      return const AppCard(
        child: CustomEmptyState(
          title: AppStrings.jobDetailsNoNotesTitle,
          message: AppStrings.jobDetailsNoNotesBody,
          icon: Icons.note_alt_outlined,
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel(AppStrings.jobDetailsNotes),
          const SizedBox(height: AppSpacing.s8),
          Text(notes, style: AppTextStyles.body),
        ],
      ),
    );
  }
}

/// Copyable follow-up / confirmation / status-check messages.
class JobDetailsTemplatesCard extends StatelessWidget {
  const JobDetailsTemplatesCard({super.key, required this.onCopy});

  final ValueChanged<JobApplicationMessageTemplateType> onCopy;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(AppStrings.jobDetailsTemplates, style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.s6),
          Text(
            AppStrings.jobDetailsTemplatesBody,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.s12),
          for (final type in JobApplicationMessageTemplateType.values) ...[
            SecondaryButton(
              label: type.label,
              leadingIcon: Icons.copy_outlined,
              outlineColor: AppColors.lineStrong,
              onPressed: () => onCopy(type),
            ),
            const SizedBox(height: AppSpacing.s8),
          ],
        ],
      ),
    );
  }
}
