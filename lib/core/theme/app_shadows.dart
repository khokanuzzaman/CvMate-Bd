import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:flutter/widgets.dart';

/// Elevation tokens from `doc/design/DESIGN_TOKENS.md`.
/// Soft shadow only — no heavy drop shadows or glows, except the amber nav button.
abstract final class AppShadows {
  /// Standard soft card shadow: rgba(40,30,90,0.16), blur 30, offset (0,14),
  /// spread -20.
  static const List<BoxShadow> soft = [
    BoxShadow(
      color: Color(0x29281E5A), // rgba(40,30,90,0.16)
      blurRadius: 30,
      offset: Offset(0, 14),
      spreadRadius: -20,
    ),
  ];

  /// Warm halo behind the center raised amber nav action.
  static final List<BoxShadow> navGlow = [
    BoxShadow(
      color: AppColors.accent.withValues(alpha: 0.45),
      blurRadius: 18,
      spreadRadius: 1,
    ),
  ];
}
