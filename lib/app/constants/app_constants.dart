abstract final class AppConstants {
  static const Duration splashDuration = Duration(milliseconds: 1400);
  static const double contentMaxWidth = 760;
  static const double defaultPadding = 20;
  static const double cardRadius = 24;

  /// The largest system text scale the app honours (accessibility sizes beyond
  /// it are clamped; see `TextScaleClamp`).
  static const double maxTextScaleFactor = 1.5;

  /// Above this text scale, side-by-side button pairs stack vertically and
  /// segmented controls wrap (see `AdaptiveButtonRow`, `SegmentedToggle`).
  static const double largeTextScaleFactor = 1.3;
}
