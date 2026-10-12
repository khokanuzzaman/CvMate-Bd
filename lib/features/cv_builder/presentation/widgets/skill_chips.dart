import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/widgets/dashed_border.dart';
import 'package:flutter/material.dart';

/// A skill in the CV: a filled `primary` pill with a trailing × that removes
/// it. The × area is 48×48dp so it is easy to hit.
class SkillChip extends StatelessWidget {
  const SkillChip({super.key, required this.name, required this.onRemove});

  final String name;
  final VoidCallback onRemove;

  static const double _pillHeight = 32;
  static const double _removeWidth = AppSpacing.minTouchTarget;

  @override
  Widget build(BuildContext context) {
    const verticalSlack =
        (AppSpacing.minTouchTarget - _pillHeight) / 2; // keeps the row 48 high

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: verticalSlack),
          child: Container(
            height: _pillHeight,
            padding: const EdgeInsets.only(
              left: AppSpacing.s14,
              right: AppSpacing.s4,
            ),
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.horizontal(
                left: Radius.circular(AppRadii.pill),
              ),
            ),
            child: Text(
              name,
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        Semantics(
          button: true,
          label: AppStrings.builderRemoveSkill(name),
          child: InkWell(
            onTap: onRemove,
            borderRadius: AppRadii.pillRadius,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: verticalSlack),
              child: Container(
                width: _removeWidth,
                height: _pillHeight,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.horizontal(
                    right: Radius.circular(AppRadii.pill),
                  ),
                ),
                child: const ExcludeSemantics(
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A suggested skill: dashed outline with a leading "+". Tapping adds it.
class SuggestedSkillChip extends StatelessWidget {
  const SuggestedSkillChip({
    super.key,
    required this.name,
    required this.onAdd,
  });

  final String name;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: AppStrings.builderAddSkillNamed(name),
      child: InkWell(
        onTap: onAdd,
        borderRadius: AppRadii.pillRadius,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.minTouchTarget,
          ),
          child: Center(
            widthFactor: 1,
            child: DashedBorder(
              color: AppColors.placeholder.withValues(alpha: 0.6),
              radius: AppRadii.pill,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s14,
                  vertical: AppSpacing.s8,
                ),
                child: ExcludeSemantics(
                  child: Text(
                    '+$name',
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
