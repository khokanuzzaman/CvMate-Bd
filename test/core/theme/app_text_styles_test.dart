import 'dart:io';

import 'package:careermatebd/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/screenshot_harness.dart';

void main() {
  // google_fonts needs a binding and must not touch the network.
  setUpAll(loadTestFonts);

  // Built lazily: reading a style touches google_fonts, which needs the
  // binding that setUpAll initialises.
  Map<String, TextStyle> styles() => {
    'display': AppTextStyles.display,
    'h1': AppTextStyles.h1,
    'h2': AppTextStyles.h2,
    'title': AppTextStyles.title,
    'appBar': AppTextStyles.appBar,
    'numeric': AppTextStyles.numeric,
    'body': AppTextStyles.body,
    'bodySm': AppTextStyles.bodySm,
    'caption': AppTextStyles.caption,
    'hint': AppTextStyles.hint,
    'label': AppTextStyles.label,
    'fieldLabel': AppTextStyles.fieldLabel,
    'button': AppTextStyles.button,
    'tileLabel': AppTextStyles.tileLabel,
    'itemTitle': AppTextStyles.itemTitle,
  };

  test('every text style falls back to Noto Sans Bengali', () {
    for (final entry in styles().entries) {
      expect(
        entry.value.fontFamilyFallback,
        contains(AppTextStyles.bengaliFontFamily),
        reason: entry.key,
      );
    }
  });

  test('the Material text theme inherits the fallback', () {
    final theme = AppTextStyles.textTheme();
    for (final style in [
      theme.headlineLarge,
      theme.titleLarge,
      theme.bodyLarge,
      theme.bodyMedium,
      theme.labelLarge,
    ]) {
      expect(style?.fontFamilyFallback, contains('NotoSansBengali'));
    }
  });

  test('the font is declared in pubspec and its files are bundled', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('family: ${AppTextStyles.bengaliFontFamily}'));
    for (final name in ['Regular', 'Bold']) {
      final path = 'assets/fonts/NotoSansBengali-$name.ttf';
      expect(pubspec, contains(path));
      expect(File(path).lengthSync(), greaterThan(100000), reason: path);
    }
    expect(File('assets/fonts/OFL.txt').existsSync(), isTrue);
  });
}
