import 'package:flutter/material.dart';

/// CvMate light-theme color tokens — the single source of truth for color.
///
/// Values are the exact hex codes from `doc/design/DESIGN_TOKENS.md` (light
/// theme). Widgets must reference these tokens, never raw hex.
///
/// TODO(dark-theme): design is light-only so far; derive a dark token set here
/// before shipping dark mode (see DESIGN_TOKENS.md TODO).
abstract final class AppColors {
  // Surfaces / ground
  static const Color bg = Color(0xFFF4F2FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFFAF9FE);
  static const Color previewBg = Color(0xFFEBE8F6);

  // Text
  static const Color ink = Color(0xFF1B1533);
  static const Color inkSoft = Color(0xFF2A2440);
  static const Color muted = Color(0xFF6E6890);
  static const Color muted2 = Color(0xFF8A85A6);
  static const Color placeholder = Color(0xFFA29DBB);

  // Lines
  static const Color line = Color(0xFFEAE6F6);
  static const Color lineStrong = Color(0xFFE2DDF1);

  // Brand indigo
  static const Color primary = Color(0xFF5A44D6);
  static const Color primaryDeep = Color(0xFF3D2FA0);
  static const Color primarySoft = Color(0xFFECE9FB);

  // Warm amber accent
  static const Color accent = Color(0xFFF2994A);
  static const Color accentSoft = Color(0xFFFCE8D2);
  static const Color onAccent = Color(0xFF3A2A12);
  static const Color accentInk = Color(0xFF9A5B15);

  // Success
  static const Color success = Color(0xFF16A06B);
  static const Color successText = Color(0xFF0F7A50);
  static const Color successSoft = Color(0xFFDDF3EA);

  // Danger
  static const Color danger = Color(0xFFE5533D);

  // Component-specific
  static const Color ringTrack = Color(0xFFEEEBF8);

  /// White text is OK on [primary]; on [accent] always use [onAccent].
  static const Color onPrimary = Color(0xFFFFFFFF);
}
