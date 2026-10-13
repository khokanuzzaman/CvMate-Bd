import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/widgets/app_card.dart';
import 'package:careermatebd/features/ats_checker/domain/entities/ats_check_category.dart';
import 'package:careermatebd/features/ats_checker/presentation/utils/ats_score_band.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// The rule engine's per-section scores as small tiles — only the scores it
/// really reports (Job Match is excluded: it needs a job post and lives in the
/// Tailor flow).
class AtsSectionScores extends StatelessWidget {
  const AtsSectionScores({super.key, required this.scores});

  final Map<AtsCheckCategory, int> scores;

  static const int _columns = 4;

  @override
  Widget build(BuildContext context) {
    final categories = [
      for (final category in AtsCheckCategory.values)
        if (category != AtsCheckCategory.jobMatch &&
            scores.containsKey(category))
          category,
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.s8;
        final width = (constraints.maxWidth - gap * (_columns - 1)) / _columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final category in categories)
              SizedBox(
                width: width,
                child: _ScoreTile(
                  label: category.label,
                  score: scores[category]!,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ScoreTile extends StatelessWidget {
  const _ScoreTile({required this.label, required this.score});

  final String label;
  final int score;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label $score',
      excludeSemantics: true,
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s4,
          vertical: AppSpacing.s12,
        ),
        child: Column(
          children: [
            Text(
              '$score',
              style: AppTextStyles.numeric.copyWith(
                fontSize: 20,
                color: atsSectionScoreColor(score),
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(color: AppColors.muted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
