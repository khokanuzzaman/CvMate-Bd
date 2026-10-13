import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/widgets/adaptive_button_row.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:flutter/material.dart';

/// Sticky footer: a quiet Back button and the primary Continue / Preview CV.
class BuilderFooter extends StatelessWidget {
  const BuilderFooter({
    super.key,
    required this.primaryLabel,
    required this.onBack,
    required this.onPrimary,
  });

  final String primaryLabel;
  final VoidCallback onBack;
  final VoidCallback onPrimary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.s12,
        AppSpacing.screen,
        AppSpacing.s16,
      ),
      child: AdaptiveButtonRow(
        secondaryFlex: 32,
        primaryFlex: 68,
        secondary: SecondaryButton(
          label: AppStrings.builderBack,
          outlineColor: AppColors.lineStrong,
          onPressed: onBack,
        ),
        primary: PrimaryButton(
          label: primaryLabel,
          trailingIcon: Icons.arrow_forward_rounded,
          onPressed: onPrimary,
        ),
      ),
    );
  }
}
