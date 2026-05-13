import 'package:careermatebd/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:careermatebd/features/settings/domain/entities/app_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appPreferencesControllerProvider =
    AsyncNotifierProvider<AppPreferencesController, AppPreferences>(
      AppPreferencesController.new,
    );

class AppPreferencesController extends AsyncNotifier<AppPreferences> {
  @override
  Future<AppPreferences> build() {
    return ref.read(settingsRepositoryProvider).loadPreferences();
  }

  Future<String?> updateThemeMode(ThemeMode themeMode) async {
    final current = state.asData?.value ?? const AppPreferences.defaults();
    final next = current.copyWith(themeMode: themeMode);
    state = AsyncData(next);

    try {
      final saved = await ref
          .read(settingsRepositoryProvider)
          .savePreferences(next);
      state = AsyncData(saved);
      return 'Theme preference saved.';
    } catch (_) {
      state = AsyncData(current);
      return 'Could not save theme preference.';
    }
  }

  Future<String?> updateLanguagePreference(
    AppLanguagePreference languagePreference,
  ) async {
    final current = state.asData?.value ?? const AppPreferences.defaults();
    final next = current.copyWith(languagePreference: languagePreference);
    state = AsyncData(next);

    try {
      final saved = await ref
          .read(settingsRepositoryProvider)
          .savePreferences(next);
      state = AsyncData(saved);
      return 'Language preference saved.';
    } catch (_) {
      state = AsyncData(current);
      return 'Could not save language preference.';
    }
  }
}
