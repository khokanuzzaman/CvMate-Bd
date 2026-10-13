import 'package:careermatebd/app/constants/app_strings.dart';
import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Light / Dark / Auto. Only Light is wired today (the app has no dark tokens
/// yet), so Dark and Auto are shown disabled and the row says they are coming.
class ThemeSelector extends StatelessWidget {
  const ThemeSelector({super.key, required this.onLight});

  final VoidCallback onLight;

  @override
  Widget build(BuildContext context) {
    // Scales down rather than overflowing the card at very large text sizes.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s4),
        decoration: const BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: AppRadii.pillRadius,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Segment(
              label: AppStrings.themeLight,
              selected: true,
              onTap: onLight,
            ),
            const _Segment(label: AppStrings.themeDark),
            const _Segment(label: AppStrings.themeAuto),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.label, this.selected = false, this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      enabled: selected,
      label: selected ? label : '$label, ${AppStrings.profileComingSoon}',
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 36),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : Colors.transparent,
              borderRadius: AppRadii.pillRadius,
            ),
            child: Text(
              label,
              style: AppTextStyles.bodySm.copyWith(
                color: selected ? AppColors.onPrimary : AppColors.placeholder,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
