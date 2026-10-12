import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/widgets/app_card.dart';
import 'package:careermatebd/core/widgets/section_label.dart';
import 'package:careermatebd/features/job_tracker/presentation/controllers/job_tracker_controller.dart';
import 'package:flutter/material.dart';

/// Four tiles in two rows: total, follow-ups due, interviews and offers.
class JobTrackerSummaryTiles extends StatelessWidget {
  const JobTrackerSummaryTiles({super.key, required this.summary});

  final JobTrackerSummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _tile(
              AppStrings.trackerSummaryTotal,
              summary.total,
              AppStrings.trackerSummaryTotalNote,
            ),
            const SizedBox(width: AppSpacing.s12),
            _tile(
              AppStrings.trackerSummaryFollowUp,
              summary.pendingFollowUp,
              AppStrings.trackerSummaryFollowUpNote,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s12),
        Row(
          children: [
            _tile(
              AppStrings.trackerSummaryInterview,
              summary.interviews,
              AppStrings.trackerSummaryInterviewNote,
            ),
            const SizedBox(width: AppSpacing.s12),
            _tile(
              AppStrings.trackerSummaryOffers,
              summary.offers,
              AppStrings.trackerSummaryOffersNote,
            ),
          ],
        ),
      ],
    );
  }

  Widget _tile(String label, int value, String note) {
    return Expanded(
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionLabel(label),
            const SizedBox(height: AppSpacing.s6),
            Text(
              '$value',
              style: AppTextStyles.h2.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              note,
              style: AppTextStyles.caption.copyWith(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
