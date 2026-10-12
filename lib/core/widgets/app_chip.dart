import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Chip variants from DESIGN_TOKENS.md.
enum AppChipVariant { neutral, selected, matched, missing, removable }

/// Pill chip. (DESIGN_TOKENS.md → AppChip)
/// - neutral: `surfaceAlt` bg, `lineStrong` border, `primaryDeep` text
/// - selected: `primary` bg, white text
/// - matched: `successSoft` bg, `successText` text
/// - missing: `accentSoft` bg, `accentInk` text, leading "+"
/// - removable: neutral style with a trailing "×" that calls [onRemove]
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.variant = AppChipVariant.neutral,
    this.onTap,
    this.onRemove,
  });

  final String label;
  final AppChipVariant variant;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  Color get _background => switch (variant) {
    AppChipVariant.neutral => AppColors.surfaceAlt,
    AppChipVariant.removable => AppColors.surfaceAlt,
    AppChipVariant.selected => AppColors.primary,
    AppChipVariant.matched => AppColors.successSoft,
    AppChipVariant.missing => AppColors.accentSoft,
  };

  Color get _foreground => switch (variant) {
    AppChipVariant.neutral => AppColors.primaryDeep,
    AppChipVariant.removable => AppColors.primaryDeep,
    AppChipVariant.selected => AppColors.onPrimary,
    AppChipVariant.matched => AppColors.successText,
    AppChipVariant.missing => AppColors.accentInk,
  };

  Color? get _border => switch (variant) {
    AppChipVariant.neutral => AppColors.lineStrong,
    AppChipVariant.removable => AppColors.lineStrong,
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (variant == AppChipVariant.missing) ...[
          Icon(Icons.add, size: 16, color: _foreground),
          const SizedBox(width: AppSpacing.s6),
        ],
        // Flexible + ellipsis so a long keyword shrinks the chip instead of
        // overflowing it.
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySm.copyWith(
              color: _foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (variant == AppChipVariant.removable) ...[
          const SizedBox(width: AppSpacing.s6),
          GestureDetector(
            onTap: onRemove,
            behavior: HitTestBehavior.opaque,
            child: Icon(Icons.close, size: 16, color: _foreground),
          ),
        ],
      ],
    );

    final border = _border;
    final chip = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s14,
        vertical: AppSpacing.s8,
      ),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: AppRadii.pillRadius,
        border: border == null ? null : Border.all(color: border),
      ),
      child: content,
    );

    if (onTap == null) {
      return chip;
    }

    // A tappable chip keeps its look but its whole 48dp-high row is the target.
    return Semantics(
      button: true,
      selected: variant == AppChipVariant.selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.minTouchTarget,
          ),
          child: Center(widthFactor: 1, child: chip),
        ),
      ),
    );
  }
}
