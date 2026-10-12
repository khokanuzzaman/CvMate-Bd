import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/widgets/app_chip.dart';
import 'package:careermatebd/core/widgets/section_label.dart';
import 'package:flutter/material.dart';

/// A labelled group of keyword chips, or [emptyLabel] when there are none.
class AtsKeywordGroup extends StatelessWidget {
  const AtsKeywordGroup({
    super.key,
    required this.label,
    required this.keywords,
    required this.emptyLabel,
    this.variant = AppChipVariant.neutral,
  });

  final String label;
  final List<String> keywords;
  final String emptyLabel;
  final AppChipVariant variant;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(label),
        const SizedBox(height: AppSpacing.s8),
        if (keywords.isEmpty)
          Text(
            emptyLabel,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
          )
        else
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [
              for (final keyword in keywords)
                AppChip(label: keyword, variant: variant),
            ],
          ),
      ],
    );
  }
}
