import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_application_status.dart';
import 'package:flutter/material.dart';

/// The status pill on application cards and the details header.
class JobStatusChip extends StatelessWidget {
  const JobStatusChip({super.key, required this.status});

  final JobApplicationStatus status;

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s6,
      ),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: AppRadii.pillRadius,
        border: style.border == null ? null : Border.all(color: style.border!),
      ),
      child: Text(
        status.label,
        style: AppTextStyles.bodySm.copyWith(
          color: style.foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  static ({Color background, Color foreground, Color? border}) _styleFor(
    JobApplicationStatus status,
  ) {
    return switch (status) {
      JobApplicationStatus.interview || JobApplicationStatus.shortlisted => (
        background: AppColors.primarySoft,
        foreground: AppColors.primaryDeep,
        border: null,
      ),
      JobApplicationStatus.offered => (
        background: AppColors.successSoft,
        foreground: AppColors.successText,
        border: null,
      ),
      JobApplicationStatus.rejected => (
        background: AppColors.danger.withValues(alpha: 0.12),
        foreground: AppColors.danger,
        border: null,
      ),
      JobApplicationStatus.applied ||
      JobApplicationStatus.draft ||
      JobApplicationStatus.archived => (
        background: AppColors.surfaceAlt,
        foreground: AppColors.muted,
        border: AppColors.lineStrong,
      ),
    };
  }
}
