import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/widgets/app_card.dart';
import 'package:careermatebd/features/job_tracker/presentation/controllers/job_tracker_controller.dart';
import 'package:flutter/material.dart';

/// Four counts across the top: Applied, Interview, Offer, Closed.
class JobStatTiles extends StatelessWidget {
  const JobStatTiles({super.key, required this.summary});

  final JobTrackerSummary summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Tile(
          value: summary.submitted,
          label: AppStrings.trackerStatApplied,
          color: AppColors.ink,
        ),
        const SizedBox(width: AppSpacing.s8),
        _Tile(
          value: summary.interviews,
          label: AppStrings.trackerStatInterview,
          color: AppColors.primary,
        ),
        const SizedBox(width: AppSpacing.s8),
        _Tile(
          value: summary.offers,
          label: AppStrings.trackerStatOffer,
          color: AppColors.successText,
        ),
        const SizedBox(width: AppSpacing.s8),
        _Tile(
          value: summary.closed,
          label: AppStrings.trackerStatClosed,
          color: AppColors.muted2,
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.value, required this.label, required this.color});

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        label: '$label $value',
        excludeSemantics: true,
        child: AppCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s4,
            vertical: AppSpacing.s12,
          ),
          child: Column(
            children: [
              Text(
                '$value',
                style: AppTextStyles.numeric.copyWith(
                  fontSize: 22,
                  color: color,
                ),
              ),
              const SizedBox(height: AppSpacing.s4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
