import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_shadows.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// A subscription option (Monthly / Yearly) the user can pick. [selected]
/// gives it the primary outline; [badge] is the small amber tag on its top
/// edge. [price] comes from the store.
class PaywallPlanCard extends StatelessWidget {
  const PaywallPlanCard({
    super.key,
    required this.name,
    required this.price,
    required this.unit,
    this.selected = false,
    this.onTap,
    this.badge,
    this.compact = false,
  });

  final String name;
  final String price;
  final String unit;
  final bool selected;
  final VoidCallback? onTap;
  final String? badge;

  /// Tighter padding for short screens.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: '$name $price$unit${badge == null ? '' : ', $badge'}',
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.s16,
                  compact ? AppSpacing.s14 : AppSpacing.s18,
                  AppSpacing.s16,
                  compact ? AppSpacing.s14 : AppSpacing.s18,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadii.cardRadius,
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.line,
                    width: selected ? 2 : 1,
                  ),
                  boxShadow: selected ? AppShadows.soft : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTextStyles.body.copyWith(
                        color: selected ? AppColors.primary : AppColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s6),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: price,
                            style: AppTextStyles.title.copyWith(
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
      ),
    );
  }
}
