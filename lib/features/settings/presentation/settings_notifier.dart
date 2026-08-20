import 'package:flutter/material.dart';
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

  // --- Individual setters ---

  Future<void> setThemeMode(ThemeMode mode) {
    final s = state.value ?? const AppSettings();
    return saveSettings(s.copyWith(themeMode: mode));
  }

  Future<void> setWritingTheme(WritingTheme theme) {
    final s = state.value ?? const AppSettings();
    return saveSettings(s.copyWith(writingTheme: theme));
  }

  Future<void> setEditorFont(EditorFont font) {
    final s = state.value ?? const AppSettings();
    return saveSettings(s.copyWith(editorFont: font));
  }

  Future<void> setEditorFontSize(double size) {
    final s = state.value ?? const AppSettings();
    return saveSettings(s.copyWith(editorFontSize: size));
  }

  Future<void> setEditorLineHeight(double height) {
    final s = state.value ?? const AppSettings();
    return saveSettings(s.copyWith(editorLineHeight: height));
  }

  Future<void> setEditorColumnWidth(double? width) {
    final s = state.value ?? const AppSettings();
    return saveSettings(s.copyWith(editorColumnWidth: width));
  }

  Future<void> setTypewriterMode(bool enabled) {
    final s = state.value ?? const AppSettings();
    return saveSettings(s.copyWith(typewriterMode: enabled));
  }

  Future<void> setDailyWordTarget(int target) {
    final s = state.value ?? const AppSettings();
    return saveSettings(s.copyWith(dailyWordTarget: target));
  }

  Future<void> setTypographicQuotes(bool enabled) {
    final s = state.value ?? const AppSettings();
    return saveSettings(s.copyWith(typographicQuotes: enabled));
  }

  Future<void> setAutocorrect(bool enabled) {
    final s = state.value ?? const AppSettings();
    return saveSettings(s.copyWith(autocorrect: enabled));
  }

  Future<void> setShowWordCount(bool enabled) {
    final s = state.value ?? const AppSettings();
    return saveSettings(s.copyWith(showWordCount: enabled));
  }
}
