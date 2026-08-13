import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/settings_repository_impl.dart';
import '../domain/app_settings.dart';
import '../domain/settings_repository.dart';

part 'settings_notifier.g.dart';

@riverpod
class SettingsNotifier extends _$SettingsNotifier {
  late SettingsRepository _repo;

  @override
  Stream<AppSettings> build() async* {
    _repo = await ref.watch(settingsRepositoryProvider.future);
    yield* _repo.watchSettings();
  }

  Future<void> update(AppSettings settings) => _repo.saveSettings(settings);
}
