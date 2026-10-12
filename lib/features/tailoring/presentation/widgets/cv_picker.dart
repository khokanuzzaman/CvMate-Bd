import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/widgets/app_card.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_profile.dart';
import 'package:careermatebd/features/cv_builder/domain/entities/cv_template.dart';
import 'package:flutter/material.dart';

/// "Which CV?" card: the selected CV and its template, with a chevron. Tapping
/// opens [showCvPickerSheet]; [onTap] is null while a step is running.
class CvPickerCard extends StatelessWidget {
  const CvPickerCard({super.key, required this.cv, required this.onTap});

  final CvProfile? cv;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final selected = cv;
    return Semantics(
      button: true,
      label: AppStrings.tailorChooseCv,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s14,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: AppRadii.iconTileRadius,
              ),
              child: const Icon(
                Icons.description_outlined,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.s14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selected?.displayTitle ?? '',
                    style: AppTextStyles.itemTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (selected != null)
                    Text(
                      AppStrings.tailorTemplateSubtitle(
                        selected.template.label,
                      ),
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.muted2,
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet listing [cvs]; resolves to the chosen CV's id (or null).
Future<String?> showCvPickerSheet(
  BuildContext context, {
  required List<CvProfile> cvs,
  required String? selectedId,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.surface,
    showDragHandle: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card)),
    ),
    builder: (context) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.6,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            0,
            AppSpacing.screen,
            AppSpacing.s16,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s8),
              child: Text(
                AppStrings.tailorChooseCv,
                style: AppTextStyles.title,
              ),
            ),
            for (final cv in cvs)
              _CvOption(
                cv: cv,
                selected: cv.id == selectedId,
                onTap: () => Navigator.of(context).pop(cv.id),
              ),
          ],
        ),
      ),
    ),
  );
}

class _CvOption extends StatelessWidget {
  const _CvOption({
    required this.cv,
    required this.selected,
    required this.onTap,
  });

  final CvProfile cv;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.inputRadius,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.minTouchTarget,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cv.displayTitle, style: AppTextStyles.itemTitle),
                      Text(
                        AppStrings.tailorTemplateSubtitle(cv.template.label),
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_rounded, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
