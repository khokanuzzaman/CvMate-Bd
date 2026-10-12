import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

enum JobTagTone { neutral, amber, indigo }

/// A small non-interactive tag (source, date, "Follow-up due"…).
class JobTag extends StatelessWidget {
  const JobTag({
    super.key,
    required this.label,
    this.tone = JobTagTone.neutral,
  });

  final String label;
  final JobTagTone tone;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (tone) {
      JobTagTone.neutral => (AppColors.surfaceAlt, AppColors.muted),
      JobTagTone.amber => (AppColors.accentSoft, AppColors.accentInk),
      JobTagTone.indigo => (AppColors.primarySoft, AppColors.primaryDeep),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s10,
        vertical: AppSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadii.pillRadius,
        border: tone == JobTagTone.neutral
            ? Border.all(color: AppColors.lineStrong)
            : null,
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
