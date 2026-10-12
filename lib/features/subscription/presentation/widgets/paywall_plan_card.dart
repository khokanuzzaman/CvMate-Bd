import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_shadows.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// A display-only price option (Monthly / Yearly). [highlighted] gives it the
/// primary outline; [badge] is the small amber tag on its top edge.
class PaywallPlanCard extends StatelessWidget {
  const PaywallPlanCard({
    super.key,
    required this.name,
    required this.price,
    required this.unit,
    this.highlighted = false,
    this.badge,
  });

  final String name;
  final String price;
  final String unit;
  final bool highlighted;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$name $price$unit',
      child: ExcludeSemantics(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s16,
                AppSpacing.s18,
                AppSpacing.s16,
                AppSpacing.s18,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadii.cardRadius,
                border: Border.all(
                  color: highlighted ? AppColors.primary : AppColors.line,
                  width: highlighted ? 2 : 1,
                ),
                boxShadow: highlighted ? AppShadows.soft : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTextStyles.body.copyWith(
                      color: highlighted ? AppColors.primary : AppColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s6),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: price,
                          style: AppTextStyles.h2.copyWith(
                            color: AppColors.ink,
                          ),
                        ),
                        TextSpan(
                          text: unit,
                          style: AppTextStyles.bodySm.copyWith(
                            color: AppColors.muted2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (badge != null)
              Positioned(
                top: -12,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s12,
                    vertical: AppSpacing.s4,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: AppRadii.pillRadius,
                  ),
                  child: Text(
                    badge!,
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.onAccent,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
