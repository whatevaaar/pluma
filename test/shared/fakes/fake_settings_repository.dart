import 'dart:async';

import 'package:pluma/features/settings/domain/app_settings.dart';
import 'package:pluma/features/settings/domain/settings_repository.dart';

class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository({AppSettings initial = const AppSettings()})
      : _current = initial;

  AppSettings _current;
  final _controller = StreamController<AppSettings>.broadcast();

  @override
  Stream<AppSettings> watchSettings() async* {
    yield _current;
    yield* _controller.stream;
  }

  @override
  Future<AppSettings> getSettings() async => _current;

  @override
  Future<void> saveSettings(AppSettings settings) async {
    _current = settings;
    _controller.add(settings);
  }

  void dispose() => _controller.close();
}
