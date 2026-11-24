import 'package:careermatebd/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Status bar and navigation bar styles. Every screen is light except the
/// splash, so [onLight] is the app default (theme app bars and a root
/// region in `CareerMateApp`); a dark screen wraps itself in an
/// `AnnotatedRegion` with [onDark].
abstract final class AppSystemUi {
  /// Dark icons on a light background.
  static const SystemUiOverlayStyle onLight = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    // Android: icon colour. iOS: the background the bar sits on.
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.bg,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarDividerColor: Colors.transparent,
  );

  /// Light icons on a dark (brand) background.
  static const SystemUiOverlayStyle onDark = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: AppColors.primary,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarDividerColor: Colors.transparent,
  );
}
