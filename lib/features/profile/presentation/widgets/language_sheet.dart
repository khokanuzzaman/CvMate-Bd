import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/features/settings/domain/entities/app_preferences.dart';
import 'package:flutter/material.dart';

/// Bottom sheet to choose the saved language preference; resolves to the pick
/// (or null when dismissed).
Future<AppLanguagePreference?> showLanguageSheet(
  BuildContext context, {
  required AppLanguagePreference selected,
}) {
  return showModalBottomSheet<AppLanguagePreference>(
    context: context,
    backgroundColor: AppColors.surface,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
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
            Text(AppStrings.profileAppLanguage, style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.s4),
            Text(
              AppStrings.profileLanguageNote,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.s8),
            for (final language in AppLanguagePreference.values)
              InkWell(
                onTap: () => Navigator.of(context).pop(language),
                borderRadius: AppRadii.inputRadius,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: AppSpacing.minTouchTarget,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          language.label,
                          style: AppTextStyles.itemTitle,
                        ),
                      ),
                      if (language == selected)
                        const Icon(
                          Icons.check_rounded,
                          color: AppColors.primary,
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
