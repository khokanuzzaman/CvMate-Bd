import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/widgets/app_buttons.dart';
import 'package:careermatebd/features/profile/presentation/widgets/profile_dialogs.dart';
import 'package:flutter/material.dart';

/// The one-time AI consent sheet. Resolves to true only on "Allow AI";
/// dismissing it counts as "Not now".
Future<bool> showAiConsentSheet(BuildContext context) async {
  final allowed = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: AppColors.surface,
    showDragHandle: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card)),
    ),
    builder: (context) => const AiConsentSheet(),
  );
  return allowed ?? false;
}

class AiConsentSheet extends StatelessWidget {
  const AiConsentSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          0,
          AppSpacing.screen,
          AppSpacing.s16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome_outlined, color: AppColors.primary),
                const SizedBox(width: AppSpacing.s8),
                Expanded(
                  child: Text(
                    AppStrings.aiConsentTitle,
                    style: AppTextStyles.title,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s12),
            Text(AppStrings.aiConsentBody, style: AppTextStyles.body),
            const SizedBox(height: AppSpacing.s4),
            TextButton(
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              onPressed: () => showPrivacyTermsDialog(context),
              child: const Text(AppStrings.aiConsentPrivacyLink),
            ),
            const SizedBox(height: AppSpacing.s12),
            PrimaryButton(
              label: AppStrings.aiConsentAllow,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: AppSpacing.s8),
            SecondaryButton(
              label: AppStrings.aiConsentNotNow,
              outlineColor: AppColors.lineStrong,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}
