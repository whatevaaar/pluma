import 'package:pluma/features/settings/data/settings_repository_impl.dart';
import 'package:pluma/features/settings/domain/app_settings.dart';
import 'package:pluma/features/settings/domain/settings_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_notifier.g.dart';

@riverpod
class SettingsNotifier extends _$SettingsNotifier {
  late SettingsRepository _repo;

  @override
  Stream<AppSettings> build() async* {
    _repo = await ref.watch(settingsRepositoryProvider.future);
    yield* _repo.watchSettings();
  }

  Future<void> saveSettings(AppSettings settings) =>
      _repo.saveSettings(settings);
}
