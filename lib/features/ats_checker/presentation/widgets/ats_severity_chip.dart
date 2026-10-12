import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/shared/models/ai/ai_models.dart';
import 'package:flutter/material.dart';

/// The HIGH / MED / LOW pill beside an ATS issue.
class AtsSeverityChip extends StatelessWidget {
  const AtsSeverityChip({super.key, required this.severity});

  final AtsSuggestionSeverity severity;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, label) = switch (severity) {
      AtsSuggestionSeverity.high => (
        AppColors.danger,
        AppColors.onPrimary,
        AppStrings.atsSeverityHigh,
      ),
      AtsSuggestionSeverity.medium => (
        AppColors.accent,
        AppColors.onAccent,
        AppStrings.atsSeverityMed,
      ),
      AtsSuggestionSeverity.low => (
        AppColors.primarySoft,
        AppColors.primaryDeep,
        AppStrings.atsSeverityLow,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s10,
        vertical: AppSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadii.pillRadius,
      ),
      child: Text(
        label,
        style: AppTextStyles.hint.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
