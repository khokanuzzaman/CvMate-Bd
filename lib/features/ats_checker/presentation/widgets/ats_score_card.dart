import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/core/widgets/app_card.dart';
import 'package:careermatebd/core/widgets/cv_picker.dart';
import 'package:careermatebd/core/widgets/score_ring.dart';
import 'package:careermatebd/features/ats_checker/domain/entities/ats_check_report.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:flutter/material.dart';

/// The CV score (ring, band headline, honest note), the CV picker and the
/// shortcuts to the builder and AI Improve.
class AtsScoreCard extends StatelessWidget {
  const AtsScoreCard({
    super.key,
    required this.report,
    required this.cv,
    required this.onPickCv,
    required this.onOpenBuilder,
    required this.onOpenAiImprove,
  });

  final AtsCheckReport report;
  final CvProfile? cv;
  final VoidCallback onPickCv;
  final VoidCallback onOpenBuilder;
  final VoidCallback onOpenAiImprove;

  static String headline(int score) {
    if (score >= 80) {
      return AppStrings.atsScoreStrong;
    }
    return score >= 60 ? AppStrings.atsScoreFair : AppStrings.atsScoreLow;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.s20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ScoreRing(percent: report.score, size: 92),
                  const SizedBox(width: AppSpacing.s18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          headline(report.score),
                          style: AppTextStyles.appBar,
                        ),
                        const SizedBox(height: AppSpacing.s4),
                        Text(
                          AppStrings.atsScoreOutOf(report.score),
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s6),
                        _WordsPill(count: report.wordCount),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s14),
              Text(
                AppStrings.atsScoreNote,
                style: AppTextStyles.caption.copyWith(color: AppColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        CvPickerCard(cv: cv, onTap: onPickCv),
        const SizedBox(height: AppSpacing.s12),
        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                label: AppStrings.atsOpenBuilder,
                leadingIcon: Icons.description_outlined,
                outlineColor: AppColors.lineStrong,
                onPressed: onOpenBuilder,
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: SecondaryButton(
                label: AppStrings.atsOpenAiImprove,
                leadingIcon: Icons.auto_fix_high_outlined,
                outlineColor: AppColors.lineStrong,
                onPressed: onOpenAiImprove,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WordsPill extends StatelessWidget {
  const _WordsPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s10,
        vertical: AppSpacing.s4,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: AppRadii.pillRadius,
      ),
      child: Text(
        AppStrings.atsWords(count),
        style: AppTextStyles.caption.copyWith(
          color: AppColors.primaryDeep,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
