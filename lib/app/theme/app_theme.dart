import 'package:careermatebd/app/theme/app_colors.dart';
import 'package:careermatebd/app/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData get lightTheme {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.secondary,
      onSecondary: AppColors.ink,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
    );

    return _buildTheme(
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      borderColor: AppColors.outlineSoft,
    );
  }

  static ThemeData get darkTheme {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primaryLight,
      onPrimary: AppColors.navyDeep,
      secondary: AppColors.secondaryLight,
      onSecondary: AppColors.navyDeep,
      error: AppColors.errorLight,
      onError: AppColors.navyDeep,
      surface: AppColors.navySurface,
      onSurface: AppColors.snow,
    );

    return _buildTheme(
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.navyDeep,
      borderColor: const Color(0xFF20374A),
    );
  }

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required Color scaffoldBackgroundColor,
    required Color borderColor,
  }) {
    final textTheme = AppTextStyles.textTheme(colorScheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        centerTitle: false,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: borderColor),
        ),
      ),
      dividerTheme: DividerThemeData(color: borderColor),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        hintStyle: textTheme.bodyMedium,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: borderColor,
        selectedColor: colorScheme.primary,
        secondarySelectedColor: colorScheme.secondary,
        labelStyle: textTheme.labelMedium ?? const TextStyle(),
        secondaryLabelStyle:
            textTheme.labelMedium?.copyWith(color: colorScheme.onPrimary) ??
            const TextStyle(),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        brightness: colorScheme.brightness,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.onSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.surface,
        ),
      ),
    );
  }
}
