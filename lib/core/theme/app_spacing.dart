/// Spacing scale (logical px) from `doc/design/DESIGN_TOKENS.md`.
/// Scale: 4, 6, 8, 10, 12, 14, 16, 18, 20, 22.
abstract final class AppSpacing {
  static const double s4 = 4;
  static const double s6 = 6;
  static const double s8 = 8;
  static const double s10 = 10;
  static const double s12 = 12;
  static const double s14 = 14;
  static const double s16 = 16;
  static const double s18 = 18;
  static const double s20 = 20;
  static const double s22 = 22;

  /// Screen horizontal padding (usually 18).
  static const double screen = s18;

  /// Default card inner padding (16).
  static const double card = s16;

  /// Minimum interactive touch target.
  static const double minTouchTarget = 48;
}
