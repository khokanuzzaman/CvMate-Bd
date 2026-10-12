import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/features/job_tracker/domain/entities/job_application_status.dart';
import 'package:flutter/material.dart';

/// A status as a pill, coloured from the design tokens: draft / archived are
/// quiet, applied is indigo, shortlisted and offered are green (offered solid),
/// interview is amber and rejected is `danger`.
class JobStatusChip extends StatelessWidget {
  const JobStatusChip({super.key, required this.status});

  final JobApplicationStatus status;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (status) {
      JobApplicationStatus.draft => (AppColors.lineStrong, AppColors.muted),
      JobApplicationStatus.applied => (
        AppColors.primarySoft,
        AppColors.primary,
      ),
      JobApplicationStatus.shortlisted => (
        AppColors.successSoft,
        AppColors.successText,
      ),
      JobApplicationStatus.interview => (
        AppColors.accentSoft,
        AppColors.accentInk,
      ),
      JobApplicationStatus.offered => (AppColors.success, AppColors.onPrimary),
      JobApplicationStatus.rejected => (
        AppColors.danger.withValues(alpha: 0.12),
        AppColors.danger,
      ),
      JobApplicationStatus.archived => (AppColors.line, AppColors.muted2),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadii.pillRadius,
      ),
      child: Text(
        status.label,
        style: AppTextStyles.caption.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
