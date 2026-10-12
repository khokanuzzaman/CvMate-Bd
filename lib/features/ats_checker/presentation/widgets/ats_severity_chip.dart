import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/shared/models/ai/ai_models.dart';
import 'package:flutter/material.dart';

/// How serious an ATS issue is: High (`danger`), Medium (amber), Low (indigo).
class AtsSeverityChip extends StatelessWidget {
  const AtsSeverityChip({super.key, required this.severity});

  final AtsSuggestionSeverity severity;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, label) = switch (severity) {
      AtsSuggestionSeverity.high => (
        AppColors.danger.withValues(alpha: 0.12),
        AppColors.danger,
        AppStrings.severityHigh,
      ),
      AtsSuggestionSeverity.medium => (
        AppColors.accentSoft,
        AppColors.accentInk,
        AppStrings.severityMedium,
      ),
      AtsSuggestionSeverity.low => (
        AppColors.primarySoft,
        AppColors.primary,
        AppStrings.severityLow,
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
        style: AppTextStyles.caption.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
