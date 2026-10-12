import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// CvMate logo mark — rounded square with the crosshair glyph. Defaults to the
/// small indigo tile used beside the wordmark; the splash uses a large white
/// tile ([background] white, [foreground] primary, [elevated]).
class BrandLogoTile extends StatelessWidget {
  const BrandLogoTile({
    super.key,
    this.size = 38,
    this.background = AppColors.primary,
    this.foreground = AppColors.onPrimary,
    this.elevated = false,
  });

  final double size;
  final Color background;
  final Color foreground;

  /// Adds a soft dark halo, used when the tile sits on the indigo splash.
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(size * 0.3),
          boxShadow: elevated
              ? [
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: 0.28),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                    spreadRadius: -6,
                  ),
                ]
              : null,
        ),
        child: Icon(Icons.gps_fixed, color: foreground, size: size * 0.5),
      ),
    );
  }
}
