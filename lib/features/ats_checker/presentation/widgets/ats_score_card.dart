import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/widgets/app_card.dart';
import 'package:careermatebd/core/widgets/score_ring.dart';
import 'package:careermatebd/features/ats_checker/presentation/utils/ats_score_band.dart';
import 'package:flutter/material.dart';

/// The overall score: ring plus a one-line verdict ("Good, with 3 fixes").
class AtsScoreCard extends StatelessWidget {
  const AtsScoreCard({super.key, required this.score, required this.fixes});

  final int score;
  final int fixes;

  @override
  Widget build(BuildContext context) {
    final band = AtsScoreBand.forScore(score);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.s20),
      child: Row(
        children: [
          ScoreRing(
            percent: score,
            size: 86,
            color: band.ringColor,
            showPercentSign: false,
          ),
          const SizedBox(width: AppSpacing.s18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(band.headline(fixes), style: AppTextStyles.title),
                const SizedBox(height: AppSpacing.s6),
                Text(
                  band.body,
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
