import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:careermatebd/core/widgets/dashed_border.dart';
import 'package:flutter/material.dart';

/// Dashed "+ Add another …" button shown under a list of entry cards.
class BuilderAddButton extends StatelessWidget {
  const BuilderAddButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: DashedBorder(
        color: AppColors.placeholder.withValues(alpha: 0.6),
        radius: AppRadii.card,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onPressed,
            borderRadius: AppRadii.cardRadius,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppSpacing.minTouchTarget + AppSpacing.s8,
              ),
              child: Center(
                child: ExcludeSemantics(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_rounded,
                        size: 22,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.s10),
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.s8,
                          ),
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
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
