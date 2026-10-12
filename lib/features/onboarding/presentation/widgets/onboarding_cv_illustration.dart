import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_shadows.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Value-prop hero: a tilted skeleton CV card with an amber "ATS match" badge
/// overlapping its edge. Decorative only, so it is hidden from semantics.
class OnboardingCvIllustration extends StatelessWidget {
  const OnboardingCvIllustration({super.key, required this.height});

  final double height;

  /// Card width / height, from the approved design.
  static const double _aspectRatio = 0.77;

  /// Counter-clockwise tilt (radians) shared by the card and the badge.
  static const double _tilt = -0.1;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        child: Center(
          child: AspectRatio(
            aspectRatio: _aspectRatio,
            child: Transform.rotate(
              angle: _tilt,
              child: const Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(child: _SkeletonCvCard()),
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment(1.14, -0.36),
                      child: _AtsMatchBadge(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SkeletonCvCard extends StatelessWidget {
  const _SkeletonCvCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card + 8),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 40,
            offset: const Offset(0, 24),
            spreadRadius: -12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Bar(widthFactor: 0.26, height: 8, color: AppColors.inkSoft),
          const SizedBox(height: AppSpacing.s8),
          _Bar(
            widthFactor: 0.42,
            height: 6,
            color: AppColors.primary.withValues(alpha: 0.25),
          ),
          const SizedBox(height: AppSpacing.s14),
          const SizedBox(
            height: 1,
            width: double.infinity,
            child: ColoredBox(color: AppColors.line),
          ),
          const SizedBox(height: AppSpacing.s14),
          const _Bar(widthFactor: 1, height: 7, color: AppColors.primarySoft),
          const SizedBox(height: AppSpacing.s10),
          const _Bar(widthFactor: 0.9, height: 7, color: AppColors.primarySoft),
          const SizedBox(height: AppSpacing.s10),
          const _Bar(
            widthFactor: 0.68,
            height: 7,
            color: AppColors.primarySoft,
          ),
          const SizedBox(height: AppSpacing.s14),
          const Row(
            children: [
              _Chip(width: 44),
              SizedBox(width: AppSpacing.s8),
              _Chip(width: 30),
              SizedBox(width: AppSpacing.s8),
              _Chip(width: 56),
            ],
          ),
          const SizedBox(height: AppSpacing.s14),
          const _Bar(widthFactor: 1, height: 7, color: AppColors.primarySoft),
          const SizedBox(height: AppSpacing.s10),
          const _Bar(
            widthFactor: 0.58,
            height: 7,
            color: AppColors.primarySoft,
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.widthFactor,
    required this.height,
    required this.color,
  });

  final double widthFactor;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: AppRadii.pillRadius,
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 18,
      decoration: const BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: AppRadii.pillRadius,
      ),
    );
  }
}

class _AtsMatchBadge extends StatelessWidget {
  const _AtsMatchBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s14,
        vertical: AppSpacing.s10,
      ),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.navGlow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.onboardingAtsMatchLabel.toUpperCase(),
            style: AppTextStyles.label.copyWith(color: AppColors.onAccent),
          ),
          Text(
            AppStrings.onboardingAtsMatchValue,
            style: AppTextStyles.numeric.copyWith(
              fontSize: 26,
              color: AppColors.onAccent,
            ),
          ),
        ],
      ),
    );
  }
}
