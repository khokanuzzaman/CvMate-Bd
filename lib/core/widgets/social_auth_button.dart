import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Outlined "Continue with …" provider button — surface bg, 1.5px `lineStrong`
/// border, ink label, and a `primarySoft` circle holding a `primary` "G".
/// Pass a null [onPressed] to render it disabled; [disabledHint] is then shown
/// as a tooltip so the state doesn't look broken.
class SocialAuthButton extends StatelessWidget {
  const SocialAuthButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.disabledHint,
  });

  final String label;
  final VoidCallback? onPressed;
  final String? disabledHint;

  static const double _minHeight = 52;
  static const double _badgeSize = 30;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    final button = SizedBox(
      width: double.infinity,
      child: Material(
        color: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadii.buttonRadius,
          side: BorderSide(color: AppColors.lineStrong, width: 1.5),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: AppRadii.buttonRadius,
          child: Opacity(
            opacity: enabled ? 1 : 0.55,
            child: Container(
              constraints: const BoxConstraints(minHeight: _minHeight),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: _badgeSize,
                    height: _badgeSize,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      'G',
                      style: AppTextStyles.numeric.copyWith(
                        fontSize: 14,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.button.copyWith(
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (enabled || disabledHint == null) {
      return button;
    }
    return Tooltip(message: disabledHint!, child: button);
  }
}
