import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Colours for a 0–100 score: `success` when strong, amber when fair, `danger`
/// when low. [strongFrom] / [fairFrom] are the lower bounds of each band.
class AtsTone {
  const AtsTone({required this.background, required this.foreground});

  final Color background;
  final Color foreground;

  factory AtsTone.forScore(
    int score, {
    required int strongFrom,
    required int fairFrom,
  }) {
    if (score >= strongFrom) {
      return const AtsTone(
        background: AppColors.successSoft,
        foreground: AppColors.successText,
      );
    }
    if (score >= fairFrom) {
      return const AtsTone(
        background: AppColors.accentSoft,
        foreground: AppColors.accentInk,
      );
    }
    return AtsTone(
      background: AppColors.danger.withValues(alpha: 0.12),
      foreground: AppColors.danger,
    );
  }
}
