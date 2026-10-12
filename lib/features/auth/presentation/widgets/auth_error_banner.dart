import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Inline error shown above the form when sign-in / sign-up fails.
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.s14),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.08),
          borderRadius: AppRadii.inputRadius,
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
        ),
        child: Text(
          message,
          style: AppTextStyles.bodySm.copyWith(color: AppColors.danger),
        ),
      ),
    );
  }
}
