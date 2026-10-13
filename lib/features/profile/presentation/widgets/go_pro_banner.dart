import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// The indigo "Go Pro" banner with the amber "See plans" button.
class GoProBanner extends StatelessWidget {
  const GoProBanner({super.key, required this.onSeePlans});

  final VoidCallback onSeePlans;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: AppRadii.cardRadius,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.goProTitle,
                  style: AppTextStyles.title.copyWith(
                    color: AppColors.onPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  AppStrings.goProBody,
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.onPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Material(
            color: AppColors.accent,
            borderRadius: AppRadii.pillRadius,
            child: InkWell(
              onTap: onSeePlans,
              borderRadius: AppRadii.pillRadius,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: AppSpacing.minTouchTarget,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s14,
                  ),
                  child: Center(
                    widthFactor: 1,
                    child: Text(
                      AppStrings.goProCta,
                      style: AppTextStyles.button.copyWith(
                        color: AppColors.onAccent,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
