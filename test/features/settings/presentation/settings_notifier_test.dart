import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluma/features/settings/data/settings_repository_impl.dart';
import 'package:pluma/features/settings/domain/app_settings.dart';
import 'package:pluma/features/settings/presentation/settings_notifier.dart';

import '../../../shared/fakes/fake_settings_repository.dart';

ProviderContainer _makeContainer(FakeSettingsRepository fake) {
  return ProviderContainer(
    overrides: [
      settingsRepositoryProvider.overrideWith((_) async => fake),
    ],
  );
}

/// Subscribes to [settingsProvider] to keep it alive, then returns the first
/// emitted value. The subscription is released via [addTearDown].
Future<AppSettings> _readSettings(ProviderContainer container) async {
  // A listener is required: StreamNotifier disposes itself if nobody is
  // subscribed while the async build() is still running.
  final sub = container.listen<AsyncValue<AppSettings>>(
    settingsProvider,
    (_, __) {},
  );
  final value = await container.read(settingsProvider.future);
  sub.close();
  return value;
}

void main() {
  group('SettingsNotifier', () {
    test('initializes with default settings', () async {
      final fake = FakeSettingsRepository();
      final container = _makeContainer(fake);
      addTearDown(container.dispose);

      final settings = await _readSettings(container);

      expect(settings.themeMode, ThemeMode.system);
      expect(settings.editorFont, EditorFont.merriweather);
      expect(settings.editorFontSize, 17.0);
      expect(settings.typewriterMode, isFalse);
      expect(settings.writingTheme, WritingTheme.default_);
    });

    test('initializes with pre-existing settings', () async {
      const initial = AppSettings(
        themeMode: ThemeMode.dark,
        typewriterMode: true,
        editorFontSize: 20.0,
      );
      final fake = FakeSettingsRepository(initial: initial);
      final container = _makeContainer(fake);
      addTearDown(container.dispose);

      final settings = await _readSettings(container);

      expect(settings.themeMode, ThemeMode.dark);
      expect(settings.typewriterMode, isTrue);
      expect(settings.editorFontSize, 20.0);
    });

    test('setThemeMode persists the new theme mode', () async {
      final fake = FakeSettingsRepository();
      final container = _makeContainer(fake);
      addTearDown(container.dispose);

      await _readSettings(container);
      await container
          .read(settingsProvider.notifier)
          .setThemeMode(ThemeMode.dark);

      final saved = await fake.getSettings();
      expect(saved.themeMode, ThemeMode.dark);
    });

    test('setWritingTheme persists the new theme', () async {
      final fake = FakeSettingsRepository();
      final container = _makeContainer(fake);
      addTearDown(container.dispose);

      await _readSettings(container);
      await container
          .read(settingsProvider.notifier)
          .setWritingTheme(WritingTheme.sepia);

      final saved = await fake.getSettings();
      expect(saved.writingTheme, WritingTheme.sepia);
    });

    test('setEditorFont persists the new font', () async {
      final fake = FakeSettingsRepository();
      final container = _makeContainer(fake);
      addTearDown(container.dispose);

      await _readSettings(container);
      await container
          .read(settingsProvider.notifier)
          .setEditorFont(EditorFont.georgia);

      final saved = await fake.getSettings();
      expect(saved.editorFont, EditorFont.georgia);
    });

    test('setEditorFontSize persists new size', () async {
      final fake = FakeSettingsRepository();
      final container = _makeContainer(fake);
      addTearDown(container.dispose);

      await _readSettings(container);
      await container
          .read(settingsProvider.notifier)
          .setEditorFontSize(22.0);

      final saved = await fake.getSettings();
      expect(saved.editorFontSize, 22.0);
    });

    test('setTypewriterMode toggles correctly', () async {
      final fake = FakeSettingsRepository();
      final container = _makeContainer(fake);
      addTearDown(container.dispose);

      await _readSettings(container);
      final notifier = container.read(settingsProvider.notifier);

      await notifier.setTypewriterMode(true);
      expect((await fake.getSettings()).typewriterMode, isTrue);

      await notifier.setTypewriterMode(false);
      expect((await fake.getSettings()).typewriterMode, isFalse);
    });

    test('setDailyWordTarget persists new target', () async {
      final fake = FakeSettingsRepository();
      final container = _makeContainer(fake);
      addTearDown(container.dispose);

      await _readSettings(container);
      await container
          .read(settingsProvider.notifier)
          .setDailyWordTarget(1000);

      final saved = await fake.getSettings();
      expect(saved.dailyWordTarget, 1000);
    });

    test('setEditorLineHeight persists new height', () async {
      final fake = FakeSettingsRepository();
      final container = _makeContainer(fake);
      addTearDown(container.dispose);

      await _readSettings(container);
      await container
          .read(settingsProvider.notifier)
          .setEditorLineHeight(2.0);

      final saved = await fake.getSettings();
      expect(saved.editorLineHeight, 2.0);
    });
  });
}
