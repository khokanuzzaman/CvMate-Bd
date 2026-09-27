import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Flow top bar — 40px back button (white card, `line` border) + Sora 700 @17
/// title + optional trailing icon action + optional step pill (`primarySoft`
/// bg, `primary` text). (DESIGN_TOKENS.md → AppTopBar)
class AppTopBar extends StatelessWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.onBack,
    this.trailingIcon,
    this.onTrailingTap,
    this.stepLabel,
  });

  final String title;
  final VoidCallback? onBack;
  final IconData? trailingIcon;
  final VoidCallback? onTrailingTap;
  final String? stepLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onBack != null) ...[
          _IconSquareButton(icon: Icons.chevron_left_rounded, onTap: onBack!),
          const SizedBox(width: AppSpacing.s12),
        ],
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.appBar,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (stepLabel != null) ...[
          const SizedBox(width: AppSpacing.s8),
          _StepPill(label: stepLabel!),
        ],
        if (trailingIcon != null) ...[
          const SizedBox(width: AppSpacing.s8),
          _IconSquareButton(
            icon: trailingIcon!,
            onTap: onTrailingTap ?? () {},
          ),
        ],
      ],
    );
  }
}

class _IconSquareButton extends StatelessWidget {
  const _IconSquareButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // Visual is 40px but keep a 48 min touch target.
      width: AppSpacing.minTouchTarget,
      height: AppSpacing.minTouchTarget,
      child: Center(
        child: Material(
          color: AppColors.surface,
          borderRadius: AppRadii.iconTileRadius,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadii.iconTileRadius,
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: AppRadii.iconTileRadius,
                border: Border.all(color: AppColors.line),
              ),
              child: Icon(icon, color: AppColors.ink, size: 22),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepPill extends StatelessWidget {
  const _StepPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s10,
        vertical: AppSpacing.s6,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: AppRadii.pillRadius,
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySm.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
