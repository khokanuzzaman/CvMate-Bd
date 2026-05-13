import 'package:flutter/material.dart';

enum AppLanguagePreference { english, bangla }

extension AppLanguagePreferenceX on AppLanguagePreference {
  String get code => switch (this) {
    AppLanguagePreference.english => 'english',
    AppLanguagePreference.bangla => 'bangla',
  };

  String get label => switch (this) {
    AppLanguagePreference.english => 'English',
    AppLanguagePreference.bangla => 'Bangla',
  };

  static AppLanguagePreference fromCode(String value) {
    return switch (value.trim().toLowerCase()) {
      'bangla' => AppLanguagePreference.bangla,
      _ => AppLanguagePreference.english,
    };
  }
}

class AppPreferences {
  const AppPreferences({
    required this.themeMode,
    required this.languagePreference,
  });

  const AppPreferences.defaults()
    : themeMode = ThemeMode.system,
      languagePreference = AppLanguagePreference.english;

  final ThemeMode themeMode;
  final AppLanguagePreference languagePreference;

  AppPreferences copyWith({
    ThemeMode? themeMode,
    AppLanguagePreference? languagePreference,
  }) {
    return AppPreferences(
      themeMode: themeMode ?? this.themeMode,
      languagePreference: languagePreference ?? this.languagePreference,
    );
  }
}
