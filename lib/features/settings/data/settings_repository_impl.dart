import 'dart:async';
import 'dart:convert';

import 'package:hive_ce/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/app_constants.dart';
import '../domain/app_settings.dart';
import '../domain/settings_repository.dart';

part 'settings_repository_impl.g.dart';

const _settingsKey = 'settings';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._box);

  final Box _box;
  final _controller = StreamController<AppSettings>.broadcast();

  @override
  Stream<AppSettings> watchSettings() async* {
    yield await getSettings();
    yield* _controller.stream;
  }

  @override
  Future<AppSettings> getSettings() async {
    final raw = _box.get(_settingsKey);
    if (raw == null) return const AppSettings();
    final json = jsonDecode(raw as String) as Map<String, dynamic>;
    return AppSettings.fromJson(json);
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    await _box.put(_settingsKey, jsonEncode(settings.toJson()));
    _controller.add(settings);
  }

  void dispose() => _controller.close();
}

@riverpod
Future<SettingsRepository> settingsRepository(Ref ref) async {
  final box = await Hive.openBox(AppConstants.settingsBoxName);
  final repo = SettingsRepositoryImpl(box);
  ref.onDispose(repo.dispose);
  return repo;
}
