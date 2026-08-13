import 'app_settings.dart';

abstract interface class SettingsRepository {
  /// Emits settings on every change.
  Stream<AppSettings> watchSettings();

  Future<AppSettings> getSettings();

  Future<void> saveSettings(AppSettings settings);
}
