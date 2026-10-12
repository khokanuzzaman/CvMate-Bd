import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/utils/date_formatter.dart';
import 'package:careermatebd/core/widgets/app_card.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_application.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_source.dart';
import 'package:careermatebd/features/job_tracker/presentation/widgets/job_status_chip.dart';
import 'package:careermatebd/features/job_tracker/presentation/widgets/job_tag.dart';
import 'package:flutter/material.dart';

/// One application in the list: role, company, status, key tags and a note
/// preview. Tapping opens the details.
class JobApplicationCard extends StatelessWidget {
  const JobApplicationCard({
    super.key,
    required this.application,
    required this.onTap,
  });

  final JobApplication application;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = application.jobTitle.trim();
    final company = application.companyName.trim();
    final notes = application.notes.trim();

    return AppCard(
      onTap: onTap,
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
                      style: AppTextStyles.itemTitle,
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      company.isEmpty
                          ? AppStrings.trackerUnknownCompany
                          : company,
                      style: AppTextStyles.bodySm.copyWith(
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
                label: AppStrings.trackerApplied(
                  DateFormatter.shortDate(application.appliedDate),
                ),
              ),
              if (application.interviewDate != null)
                JobTag(
                  label: AppStrings.trackerInterviewOn(
                    DateFormatter.shortDate(application.interviewDate!),
                  ),
                  tone: JobTagTone.indigo,
                ),
              if (application.hasLinkedCv)
                const JobTag(label: AppStrings.trackerLinkedCv),
              if (application.hasLinkedCoverLetter)
                const JobTag(label: AppStrings.trackerLinkedCoverLetter),
              if (application.needsFollowUp)
                const JobTag(
                  label: AppStrings.trackerFollowUpDue,
                  tone: JobTagTone.amber,
                ),
            ],
          ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s12),
            Text(
              notes,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(color: AppColors.muted),
            ),
          ],
        ],
      ),
    );
  }
}
