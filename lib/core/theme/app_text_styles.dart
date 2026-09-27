import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography tokens from `doc/design/DESIGN_TOKENS.md`.
///
/// Display / headings: Sora (600, 700). Body / UI: Plus Jakarta Sans
/// (400, 500, 600, 700). Loaded via `google_fonts`. Widgets should use these
/// getters (or the mapped [textTheme]) rather than ad-hoc [TextStyle]s.
abstract final class AppTextStyles {
  // Display / headings — Sora.
  static TextStyle get h1 => GoogleFonts.sora(
    fontSize: 26,
    height: 1.15,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );

  static TextStyle get h2 => GoogleFonts.sora(
    fontSize: 23,
    height: 1.2,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );

  static TextStyle get title => GoogleFonts.sora(
    fontSize: 20,
    height: 1.25,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );

  static TextStyle get appBar => GoogleFonts.sora(
    fontSize: 17,
    height: 1.25,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );

  /// Big numbers / scores use Sora 700 as well.
  static TextStyle get numeric => GoogleFonts.sora(
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );

  // Body / UI — Plus Jakarta Sans.
  static TextStyle get body => GoogleFonts.plusJakartaSans(
    fontSize: 14,
    height: 1.5,
    fontWeight: FontWeight.w500,
    color: AppColors.inkSoft,
  );

  static TextStyle get bodySm => GoogleFonts.plusJakartaSans(
    fontSize: 13.5,
    height: 1.45,
    fontWeight: FontWeight.w500,
    color: AppColors.inkSoft,
  );

  static TextStyle get caption => GoogleFonts.plusJakartaSans(
    fontSize: 12,
    height: 1.4,
    fontWeight: FontWeight.w400,
    color: AppColors.muted,
  );

  static TextStyle get hint => GoogleFonts.plusJakartaSans(
    fontSize: 11.5,
    height: 1.35,
    fontWeight: FontWeight.w400,
    color: AppColors.muted2,
  );

  /// UPPERCASE section label, letter-spacing .06em (≈0.69 @11.5). Uppercasing is
  /// applied by the widget (e.g. SectionLabel), not baked into the token.
  static TextStyle get label => GoogleFonts.plusJakartaSans(
    fontSize: 11.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.69,
    color: AppColors.muted,
  );

  /// Field input label (12 / 600, muted).
  static TextStyle get fieldLabel => GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.muted,
  );

  /// Button text — Plus Jakarta 700 @15.
  static TextStyle get button => GoogleFonts.plusJakartaSans(
    fontSize: 15,
    fontWeight: FontWeight.w700,
  );

  /// QuickActionTile caption — 12 / 600, centered, ink.
  static TextStyle get tileLabel => GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
  );

  /// List-item title (e.g. CvListTile) — Plus Jakarta 700, ink.
  static TextStyle get itemTitle => GoogleFonts.plusJakartaSans(
    fontSize: 15.5,
    height: 1.25,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );

  /// Maps the design type scale onto Material text slots so
  /// `Theme.of(context).textTheme` and default [Text] widgets stay on-brand.
  static TextTheme textTheme() {
    return TextTheme(
      headlineLarge: h1,
      headlineMedium: h2,
      titleLarge: title,
      titleMedium: appBar,
      bodyLarge: body,
      bodyMedium: bodySm,
      bodySmall: caption,
      labelLarge: label,
      labelSmall: hint,
    );
  }
}
