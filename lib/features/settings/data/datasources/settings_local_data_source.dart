import 'dart:convert';

import 'package:careermatebd/features/settings/domain/entities/app_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final settingsLocalDataSourceProvider = Provider<SettingsLocalDataSource>((
  ref,
) {
  return const SettingsLocalDataSource();
});

class SettingsLocalDataSource {
  const SettingsLocalDataSource();

  static const String _boxName = 'app_preferences_box';
  static const String _preferencesKey = 'app_preferences';

  Future<AppPreferences> loadPreferences() async {
    final box = await _openBox();
    final raw = box.get(_preferencesKey);
    if (raw == null || raw.trim().isEmpty) {
      return const AppPreferences.defaults();
    }

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return AppPreferences(
        themeMode: _themeModeFromCode(map['themeMode'] as String? ?? 'system'),
        languagePreference: AppLanguagePreferenceX.fromCode(
          map['languagePreference'] as String? ?? 'english',
        ),
      );
    } catch (_) {
      return const AppPreferences.defaults();
    }
  }

  Future<void> savePreferences(AppPreferences preferences) async {
    final box = await _openBox();
    await box.put(
      _preferencesKey,
      jsonEncode({
        'themeMode': _themeModeToCode(preferences.themeMode),
        'languagePreference': preferences.languagePreference.code,
      }),
    );
  }

  Future<Box<String>> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<String>(_boxName);
    }

    return Hive.openBox<String>(_boxName);
  }

  ThemeMode _themeModeFromCode(String value) {
    return switch (value.trim().toLowerCase()) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  String _themeModeToCode(ThemeMode themeMode) {
    return switch (themeMode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
  }
}
