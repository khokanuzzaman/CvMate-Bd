import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/widgets/app_card.dart';
import 'package:careermatebd/features/ats_checker/domain/entities/ats_check_issue.dart';
import 'package:careermatebd/features/ats_checker/presentation/widgets/ats_severity_chip.dart';
import 'package:flutter/material.dart';

/// One card of issues, most severe first, each with its pill and a "Fix" button
/// that opens the builder step where the problem can be resolved.
class AtsIssueList extends StatelessWidget {
  const AtsIssueList({super.key, required this.issues, required this.onFix});

  final List<AtsCheckIssue> issues;
  final ValueChanged<AtsCheckIssue> onFix;

  @override
  Widget build(BuildContext context) {
    if (issues.isEmpty) {
      return AppCard(
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_outline_rounded,
              color: AppColors.success,
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Text(
                AppStrings.atsNoIssues,
                style: AppTextStyles.body.copyWith(color: AppColors.inkSoft),
              ),
            ),
          ],
        ),
      );
    }

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (index, issue) in issues.indexed) ...[
            if (index > 0) const Divider(height: 1, color: AppColors.line),
            _IssueRow(issue: issue, onFix: () => onFix(issue)),
          ],
        ],
      ),
    );
  }
}

class _IssueRow extends StatelessWidget {
  const _IssueRow({required this.issue, required this.onFix});

  final AtsCheckIssue issue;
  final VoidCallback onFix;

  @override
  Widget build(BuildContext context) {
    final example = issue.exampleImprovement?.trim() ?? '';

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AtsSeverityChip(severity: issue.severity),
          const SizedBox(width: AppSpacing.s10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(issue.problem, style: AppTextStyles.itemTitle),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  issue.suggestion,
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
                ),
                if (example.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s6),
                  Text(
                    AppStrings.atsExample(example),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.muted2,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s10),
          _FixButton(onTap: onFix),
        ],
      ),
    );
  }
}

class _FixButton extends StatelessWidget {
  const _FixButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: AppStrings.atsFix,
      child: Material(
        color: AppColors.accentSoft,
        borderRadius: AppRadii.pillRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.pillRadius,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: AppSpacing.minTouchTarget,
              minHeight: 36,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s14),
                child: Text(
                  AppStrings.atsFix,
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.accentInk,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
