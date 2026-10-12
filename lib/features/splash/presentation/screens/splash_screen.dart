import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/widgets/brand_logo_tile.dart';
import 'package:careermatebd/core/widgets/pager_dots.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Indigo brand splash: logo tile, wordmark, tagline, and progress dots. The
/// startup / redirect logic lives in the router; this screen is presentation
/// only.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  static const double _logoSize = 88;
  static const int _dotCount = 3;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const BrandLogoTile(
                        size: _logoSize,
                        background: AppColors.surface,
                        foreground: AppColors.primary,
                        elevated: true,
                      ),
                      const SizedBox(height: AppSpacing.s22),
                      Text(
                        AppStrings.brandName,
                        style: AppTextStyles.display.copyWith(
                          color: AppColors.onPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.s10),
                      Text(
                        AppStrings.splashTagline,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.onPrimary.withValues(alpha: 0.85),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s22 * 2),
                child: PagerDots(
                  count: _dotCount,
                  index: 0,
                  activeColor: AppColors.accent,
                  inactiveColor: AppColors.onPrimary.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
