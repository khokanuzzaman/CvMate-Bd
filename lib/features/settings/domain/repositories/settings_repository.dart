import 'package:careermatebd/features/settings/domain/entities/app_preferences.dart';

abstract class SettingsRepository {
  Future<AppPreferences> loadPreferences();

  Future<AppPreferences> savePreferences(AppPreferences preferences);
}
