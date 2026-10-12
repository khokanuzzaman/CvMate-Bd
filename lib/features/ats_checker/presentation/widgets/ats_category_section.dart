import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/widgets/app_card.dart';
import 'package:careermatebd/features/ats_checker/domain/entities/ats_check_category.dart';
import 'package:careermatebd/features/ats_checker/domain/entities/ats_check_issue.dart';
import 'package:careermatebd/features/ats_checker/domain/entities/ats_check_report.dart';
import 'package:careermatebd/features/ats_checker/domain/entities/ats_job_match_report.dart';
import 'package:careermatebd/features/ats_checker/presentation/widgets/ats_issue_tile.dart';
import 'package:careermatebd/features/ats_checker/presentation/widgets/ats_tone.dart';
import 'package:flutter/material.dart';

/// "Results by category": one card per category with its score and issues.
class AtsCategorySection extends StatelessWidget {
  const AtsCategorySection({
    super.key,
    required this.report,
    required this.jobMatchReport,
  });

  final AtsCheckReport report;
  final AtsJobMatchReport? jobMatchReport;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(AppStrings.atsCategoriesTitle, style: AppTextStyles.title),
        const SizedBox(height: AppSpacing.s12),
        for (final category in AtsCheckCategory.values) ...[
          _CategoryCard(
            category: category,
            issues: category == AtsCheckCategory.jobMatch
                ? (jobMatchReport?.issues ?? const <AtsCheckIssue>[])
                : report.issuesFor(category),
            score: category == AtsCheckCategory.jobMatch
                ? jobMatchReport?.matchPercentage
                : (report.categoryScores[category] ?? 100),
          ),
          const SizedBox(height: AppSpacing.s12),
        ],
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.issues,
    required this.score,
  });

  final AtsCheckCategory category;
  final List<AtsCheckIssue> issues;
  final int? score;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(category.label, style: AppTextStyles.itemTitle),
              ),
              _ScorePill(score: score),
            ],
          ),
          const SizedBox(height: AppSpacing.s10),
          if (issues.isEmpty)
            Text(
              category == AtsCheckCategory.jobMatch
                  ? AppStrings.atsJobMatchPlaceholder
                  : AppStrings.atsNoIssues,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
            )
          else
            for (final (index, issue) in issues.indexed) ...[
              if (index > 0)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.s12),
                  child: Divider(height: 1, color: AppColors.line),
                ),
              AtsIssueTile(issue: issue),
            ],
        ],
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  const _ScorePill({required this.score});

  final int? score;

  @override
  Widget build(BuildContext context) {
    final value = score;
    final tone = value == null
        ? const AtsTone(
            background: AppColors.lineStrong,
            foreground: AppColors.muted,
          )
        : AtsTone.forScore(value, strongFrom: 80, fairFrom: 60);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: AppRadii.pillRadius,
      ),
      child: Text(
        value == null
            ? AppStrings.atsNotChecked
            : AppStrings.atsCategoryScore(value),
        style: AppTextStyles.caption.copyWith(
          color: tone.foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
