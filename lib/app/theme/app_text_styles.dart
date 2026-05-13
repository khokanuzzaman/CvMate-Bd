import 'package:careermatebd/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

abstract final class AppTextStyles {
  static TextTheme textTheme(ColorScheme colorScheme) {
    final mutedColor = colorScheme.brightness == Brightness.dark
        ? AppColors.mutedSnow
        : AppColors.mutedInk;

    return TextTheme(
      displaySmall: TextStyle(
        fontSize: 34,
        height: 1.08,
        fontWeight: FontWeight.w800,
        color: colorScheme.onSurface,
      ),
      headlineLarge: TextStyle(
        fontSize: 28,
        height: 1.15,
        fontWeight: FontWeight.w800,
        color: colorScheme.onSurface,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        height: 1.2,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        height: 1.25,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        height: 1.3,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 1.55,
        color: colorScheme.onSurface,
      ),
      bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: mutedColor),
      labelLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
      labelMedium: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: mutedColor,
      ),
    );
  }
}
