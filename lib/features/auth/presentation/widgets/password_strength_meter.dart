import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/widgets/progress_bar.dart';
import 'package:careermatebd/features/auth/domain/password_strength.dart';
import 'package:flutter/material.dart';

/// 3-segment strength meter under the register password field. Filled segments
/// are `danger` while weak and `success` once the password is acceptable.
class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.strength});

  final PasswordStrength strength;

  static const int _segments = 3;

  @override
  Widget build(BuildContext context) {
    final fill = strength.score >= PasswordStrength.fair.score
        ? AppColors.success
        : AppColors.danger;

    return Semantics(
      label: '${AppStrings.passwordStrengthLabel}: ${_describe(strength)}',
      child: ExcludeSemantics(
        child: SegmentedSteps(
          totalSteps: _segments,
          completedSteps: strength.score,
          height: 5,
          activeColor: fill,
        ),
      ),
    );
  }

  static String _describe(PasswordStrength strength) {
    return switch (strength) {
      PasswordStrength.empty => AppStrings.passwordStrengthEmpty,
      PasswordStrength.weak => AppStrings.passwordStrengthWeak,
      PasswordStrength.fair => AppStrings.passwordStrengthFair,
      PasswordStrength.strong => AppStrings.passwordStrengthStrong,
    };
  }
}
