import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/features/ats_checker/domain/entities/ats_check_issue.dart';
import 'package:careermatebd/features/ats_checker/presentation/widgets/ats_severity_chip.dart';
import 'package:flutter/material.dart';

/// One ATS issue: the problem and its severity, the suggestion, and an example
/// improvement when there is one.
class AtsIssueTile extends StatelessWidget {
  const AtsIssueTile({super.key, required this.issue});

  final AtsCheckIssue issue;

  @override
  Widget build(BuildContext context) {
    final example = issue.exampleImprovement?.trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                issue.problem,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
            AtsSeverityChip(severity: issue.severity),
          ],
        ),
        const SizedBox(height: AppSpacing.s6),
        Text(issue.suggestion, style: AppTextStyles.bodySm),
        if (example.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.s12),
            decoration: const BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: AppRadii.inputRadius,
            ),
            child: Text(
              example,
              style: AppTextStyles.caption.copyWith(color: AppColors.muted),
            ),
          ),
        ],
      ],
    );
  }
}
