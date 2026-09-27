import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Primary action — filled `primary`, white 700 @15, radius 15, optional
/// trailing arrow. (DESIGN_TOKENS.md → PrimaryButton)
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.trailingIcon,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? trailingIcon;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return _SolidButton(
      label: label,
      onPressed: onPressed,
      trailingIcon: trailingIcon,
      expanded: expanded,
      background: AppColors.primary,
      foreground: AppColors.onPrimary,
    );
  }
}

/// Warm hero CTA — filled `accent`, text/icon `onAccent` (never white).
/// (DESIGN_TOKENS.md → AmberCtaButton)
class AmberCtaButton extends StatelessWidget {
  const AmberCtaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.trailingIcon,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? trailingIcon;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return _SolidButton(
      label: label,
      onPressed: onPressed,
      trailingIcon: trailingIcon,
      expanded: expanded,
      background: AppColors.accent,
      foreground: AppColors.onAccent,
    );
  }
}

/// Secondary action — surface bg, 1.5px `primary` border, `primary` text 700.
/// (DESIGN_TOKENS.md → SecondaryButton)
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.trailingIcon,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? trailingIcon;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final content = _buttonContent(
      label: label,
      trailingIcon: trailingIcon,
      foreground: AppColors.primary,
      expanded: expanded,
    );

    final button = Material(
      color: AppColors.surface,
      borderRadius: AppRadii.buttonRadius,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadii.buttonRadius,
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AppSpacing.minTouchTarget,
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
            decoration: BoxDecoration(
              borderRadius: AppRadii.buttonRadius,
              border: Border.all(color: AppColors.primary, width: 1.5),
            ),
            child: Center(child: content),
          ),
        ),
      ),
    );

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class _SolidButton extends StatelessWidget {
  const _SolidButton({
    required this.label,
    required this.onPressed,
    required this.background,
    required this.foreground,
    required this.expanded,
    this.trailingIcon,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color background;
  final Color foreground;
  final bool expanded;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    final button = Material(
      color: background,
      borderRadius: AppRadii.buttonRadius,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadii.buttonRadius,
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AppSpacing.minTouchTarget,
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
            child: Center(
              child: _buttonContent(
                label: label,
                trailingIcon: trailingIcon,
                foreground: foreground,
                expanded: expanded,
              ),
            ),
          ),
        ),
      ),
    );

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

Widget _buttonContent({
  required String label,
  required IconData? trailingIcon,
  required Color foreground,
  required bool expanded,
}) {
  return Row(
    mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Flexible(
        child: Text(
          label,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.button.copyWith(color: foreground),
        ),
      ),
      if (trailingIcon != null) ...[
        const SizedBox(width: AppSpacing.s8),
        Icon(trailingIcon, size: 18, color: foreground),
      ],
    ],
  );
}
