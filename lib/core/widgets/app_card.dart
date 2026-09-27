import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:careermatebd/core/theme/app_radii.dart';
import 'package:careermatebd/core/theme/app_spacing.dart';
import 'package:careermatebd/core/theme/app_shadows.dart';
import 'package:flutter/material.dart';

/// Surface card — `surface` bg, 1px `line` border, radius 18–20, optional soft
/// shadow. (DESIGN_TOKENS.md → AppCard)
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.card),
    this.onTap,
    this.shadow = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: AppColors.surface,
      borderRadius: AppRadii.cardRadius,
      border: Border.all(color: AppColors.line),
      boxShadow: shadow ? AppShadows.soft : null,
    );

    if (onTap == null) {
      return Container(
        padding: padding,
        decoration: decoration,
        child: child,
      );
    }

    return DecoratedBox(
      decoration: decoration,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.cardRadius,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
