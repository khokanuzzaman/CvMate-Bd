import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:flutter/material.dart';

/// Continuous progress bar — track `lineStrong`, fill `primary` (or `success`
/// at 100%), full radius. (DESIGN_TOKENS.md → ProgressBar)
class ProgressBar extends StatelessWidget {
  const ProgressBar({super.key, required this.value, this.height = 6});

  /// 0.0–1.0.
  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    final fill = clamped >= 1.0 ? AppColors.success : AppColors.primary;

    return ClipRRect(
      borderRadius: AppRadii.pillRadius,
      child: Stack(
        children: [
          Container(height: height, color: AppColors.lineStrong),
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: clamped,
            child: Container(height: height, color: fill),
          ),
        ],
      ),
    );
  }
}

/// Stepper track — equal segments with a gap; the first [completedSteps] are
/// filled `primary`, the rest are `lineStrong`. (DESIGN_TOKENS.md → Steps)
class SegmentedSteps extends StatelessWidget {
  const SegmentedSteps({
    super.key,
    required this.totalSteps,
    required this.completedSteps,
    this.height = 6,
    this.gap = 6,
  });

  final int totalSteps;
  final int completedSteps;
  final double height;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < totalSteps; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < totalSteps - 1 ? gap : 0),
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  color: i < completedSteps
                      ? AppColors.primary
                      : AppColors.lineStrong,
                  borderRadius: AppRadii.pillRadius,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
