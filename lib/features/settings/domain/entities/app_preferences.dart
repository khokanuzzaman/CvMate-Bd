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
    this.aiConsent = false,
    this.shareUsageAnalytics = true,
  });

  const AppPreferences.defaults()
    : themeMode = ThemeMode.system,
      languagePreference = AppLanguagePreference.english,
      aiConsent = false,
      shareUsageAnalytics = true;

  final ThemeMode themeMode;
  final AppLanguagePreference languagePreference;

  /// Whether the user allowed AI features to send CV text to the AI server
  /// and Anthropic (App Store guideline 5.1.2). Off until they choose.
  final bool aiConsent;

  /// "Share usage analytics": Firebase Analytics and Crashlytics. On by
  /// default (no content is ever sent); the user can turn it off any time.
  final bool shareUsageAnalytics;

  AppPreferences copyWith({
    ThemeMode? themeMode,
    AppLanguagePreference? languagePreference,
    bool? aiConsent,
    bool? shareUsageAnalytics,
  }) {
    return AppPreferences(
      themeMode: themeMode ?? this.themeMode,
      languagePreference: languagePreference ?? this.languagePreference,
      aiConsent: aiConsent ?? this.aiConsent,
      shareUsageAnalytics: shareUsageAnalytics ?? this.shareUsageAnalytics,
    );
  }
}
