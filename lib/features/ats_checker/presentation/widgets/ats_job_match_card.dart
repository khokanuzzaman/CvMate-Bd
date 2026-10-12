import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/core/widgets/app_card.dart';
import 'package:careermatebd/core/widgets/app_chip.dart';
import 'package:careermatebd/core/widgets/app_text_field.dart';
import 'package:careermatebd/core/widgets/custom_loading_view.dart';
import 'package:careermatebd/core/widgets/score_ring.dart';
import 'package:careermatebd/features/ats_checker/domain/entities/ats_job_match_report.dart';
import 'package:careermatebd/features/ats_checker/presentation/controllers/ats_checker_state.dart';
import 'package:careermatebd/features/ats_checker/presentation/widgets/ats_issue_tile.dart';
import 'package:careermatebd/features/ats_checker/presentation/widgets/ats_keyword_group.dart';
import 'package:flutter/material.dart';

/// Job post match: paste a post, check it, then the match score, keyword groups
/// (matched / missing / detected skills) and the issues found.
class AtsJobMatchCard extends StatelessWidget {
  const AtsJobMatchCard({
    super.key,
    required this.state,
    required this.jobPostController,
    required this.onCheckMatch,
    required this.onCopySuggestions,
    required this.onApplyDetectedSkills,
  });

  final AtsCheckerState state;
  final TextEditingController jobPostController;
  final VoidCallback onCheckMatch;
  final VoidCallback? onCopySuggestions;
  final VoidCallback? onApplyDetectedSkills;

  static String bandLabel(int percent) {
    if (percent >= 75) {
      return AppStrings.atsMatchStrong;
    }
    return percent >= 50 ? AppStrings.atsMatchModerate : AppStrings.atsMatchLow;
  }

  @override
  Widget build(BuildContext context) {
    final match = state.jobMatchReport;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(AppStrings.atsMatchTitle, style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.s6),
          Text(
            AppStrings.atsMatchBody,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.s14),
          AppTextArea(
            controller: jobPostController,
            label: AppStrings.atsJobPostLabel,
            hintText: AppStrings.atsJobPostHint,
            minLines: 6,
            maxLines: 8,
          ),
          const SizedBox(height: AppSpacing.s14),
          PrimaryButton(
            label: state.isCheckingJobMatch
                ? AppStrings.atsChecking
                : state.hasCheckedJobMatch
                ? AppStrings.atsRecheck
                : AppStrings.atsCheckMatch,
            leadingIcon: Icons.fact_check_outlined,
            onPressed: state.isCheckingJobMatch ? null : onCheckMatch,
          ),
          if (state.isCheckingJobMatch)
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.s16),
              child: CustomLoadingView(message: AppStrings.atsChecking),
            )
          else if (!state.hasJobPost)
            _Hint(AppStrings.atsPasteFirst)
          else if (!state.hasCheckedJobMatch)
            _Hint(AppStrings.atsReadyToCheck)
          else if (match != null)
            _Result(
              match: match,
              onCopySuggestions: onCopySuggestions,
              onApplyDetectedSkills: onApplyDetectedSkills,
            ),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s14),
      child: Text(
        text,
        style: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
      ),
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({
    required this.match,
    required this.onCopySuggestions,
    required this.onApplyDetectedSkills,
  });

  final AtsJobMatchReport match;
  final VoidCallback? onCopySuggestions;
  final VoidCallback? onApplyDetectedSkills;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.s18),
        Row(
          children: [
            ScoreRing(percent: match.matchPercentage, size: 76, stroke: 8),
            const SizedBox(width: AppSpacing.s16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.atsMatchScore,
                    style: AppTextStyles.itemTitle,
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    AtsJobMatchCard.bandLabel(match.matchPercentage),
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s12),
        Container(
          padding: const EdgeInsets.all(AppSpacing.s12),
          decoration: const BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: AppRadii.inputRadius,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.verified_user_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.s10),
              Expanded(
                child: Text(
                  AppStrings.atsHonestNote,
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.primaryDeep,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (match.suggestedSectionsToImprove.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s16),
          AtsKeywordGroup(
            label: AppStrings.atsSectionsToImprove,
            keywords: match.suggestedSectionsToImprove,
            emptyLabel: AppStrings.atsNoSections,
          ),
        ],
        const SizedBox(height: AppSpacing.s16),
        AtsKeywordGroup(
          label: AppStrings.atsExtracted,
          keywords: match.extractedKeywords,
          emptyLabel: AppStrings.atsNoKeywords,
        ),
        const SizedBox(height: AppSpacing.s16),
        AtsKeywordGroup(
          label: AppStrings.atsMatched,
          keywords: match.matchedKeywords,
          emptyLabel: AppStrings.atsNoMatched,
          variant: AppChipVariant.matched,
        ),
        const SizedBox(height: AppSpacing.s16),
        AtsKeywordGroup(
          label: AppStrings.atsMissing,
          keywords: match.missingKeywords,
          emptyLabel: AppStrings.atsNoMissing,
          variant: AppChipVariant.missing,
        ),
        const SizedBox(height: AppSpacing.s16),
        AtsKeywordGroup(
          label: AppStrings.atsDetected,
          keywords: match.suggestedSkillsToAdd,
          emptyLabel: AppStrings.atsNoDetected,
        ),
        if (onApplyDetectedSkills != null) ...[
          const SizedBox(height: AppSpacing.s12),
          SecondaryButton(
            label: AppStrings.atsApplySkills,
            leadingIcon: Icons.playlist_add_check_outlined,
            onPressed: onApplyDetectedSkills,
          ),
        ],
        if (onCopySuggestions != null) ...[
          const SizedBox(height: AppSpacing.s10),
          SecondaryButton(
            label: AppStrings.atsCopySuggestions,
            leadingIcon: Icons.copy_all_outlined,
            outlineColor: AppColors.lineStrong,
            onPressed: onCopySuggestions,
          ),
        ],
        if (match.issues.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s18),
          for (final (index, issue) in match.issues.indexed) ...[
            if (index > 0)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.s12),
                child: Divider(height: 1, color: AppColors.line),
              ),
            AtsIssueTile(issue: issue),
          ],
        ],
      ],
    );
  }
}
