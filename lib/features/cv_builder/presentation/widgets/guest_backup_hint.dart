import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/app/router/route_names.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Tells a signed-out user that their CVs live only on this device, with a
/// way to sign in and turn on the backup.
class GuestBackupHint extends StatelessWidget {
  const GuestBackupHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s14,
        AppSpacing.s8,
        AppSpacing.s8,
        AppSpacing.s8,
      ),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 20,
            color: AppColors.accentInk,
          ),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Text(
              AppStrings.guestBackupHint,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.onAccent),
            ),
          ),
          TextButton(
            onPressed: () => context.push(RouteNames.loginPath),
            child: const Text(AppStrings.guestBackupSignIn),
          ),
        ],
      ),
    );
  }
}
