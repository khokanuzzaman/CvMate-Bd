import 'package:careermatebd/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:careermatebd/features/settings/domain/entities/app_preferences.dart';
import 'package:careermatebd/features/settings/domain/repositories/settings_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final localDataSource = ref.watch(settingsLocalDataSourceProvider);
  return SettingsRepositoryImpl(localDataSource);
});

class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl(this._localDataSource);

  final SettingsLocalDataSource _localDataSource;

  @override
  Future<AppPreferences> loadPreferences() {
    return _localDataSource.loadPreferences();
  }

  @override
  Future<AppPreferences> savePreferences(AppPreferences preferences) async {
    await _localDataSource.savePreferences(preferences);
    return preferences;
  }
}
