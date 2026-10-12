import 'package:careermatebd/features/settings/domain/entities/app_preferences.dart';
import 'package:careermatebd/features/settings/domain/repositories/settings_repository.dart';

/// In-memory [SettingsRepository] so profile tests need no Hive.
class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository([AppPreferences? initial])
    : preferences = initial ?? const AppPreferences.defaults();

  AppPreferences preferences;
  int saveCount = 0;

  @override
  Future<AppPreferences> loadPreferences() async => preferences;

  @override
  Future<AppPreferences> savePreferences(AppPreferences value) async {
    preferences = value;
    saveCount++;
    return value;
  }
}
