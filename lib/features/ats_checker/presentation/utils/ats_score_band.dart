import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:flutter/painting.dart';

/// How the rule engine's 0–100 score reads to the user.
enum AtsScoreBand {
  strong,
  good,
  needsWork;

  static AtsScoreBand forScore(int score) {
    if (score >= 80) {
      return strong;
    }
    return score >= 60 ? good : needsWork;
  }

  String headline(int fixes) => AppStrings.atsHeadline(switch (this) {
    AtsScoreBand.strong => AppStrings.atsHeadlineStrong,
    AtsScoreBand.good => AppStrings.atsHeadlineGood,
    AtsScoreBand.needsWork => AppStrings.atsHeadlineNeedsWork,
  }, fixes);

  String get body => switch (this) {
    AtsScoreBand.strong => AppStrings.atsBodyStrong,
    AtsScoreBand.good => AppStrings.atsBodyGood,
    AtsScoreBand.needsWork => AppStrings.atsBodyNeedsWork,
  };

  /// Colour of the ring's arc.
  Color get ringColor =>
      this == AtsScoreBand.needsWork ? AppColors.accent : AppColors.success;
}

/// Colour of a per-section score number: green from 80, amber from 60.
Color atsSectionScoreColor(int score) {
  if (score >= 80) {
    return AppColors.successText;
  }
  return score >= 60 ? AppColors.accentInk : AppColors.danger;
}
