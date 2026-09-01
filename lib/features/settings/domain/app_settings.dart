import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_settings.freezed.dart';
part 'app_settings.g.dart';

enum EditorFont { merriweather, georgia, jetbrainsMono }

enum WritingTheme {
  default_,
  // Author-inspired palettes (Werdsmith-style literary themes).
  shakespeare,
  villaurrutia,
  davila,
  // Classic surface themes.
  sepia,
  forest,
  midnight,
}

extension EditorFontX on EditorFont {
  String get fontFamily => switch (this) {
        EditorFont.merriweather => 'Merriweather',
        EditorFont.georgia => 'Georgia',
        EditorFont.jetbrainsMono => 'monospace',
      };

  String get displayName => switch (this) {
        EditorFont.merriweather => 'Merriweather',
        EditorFont.georgia => 'Georgia',
        EditorFont.jetbrainsMono => 'Mono',
      };
}

extension WritingThemeX on WritingTheme {
  String get displayName => switch (this) {
        WritingTheme.default_ => 'Por defecto',
        WritingTheme.shakespeare => 'Shakespeare',
        WritingTheme.villaurrutia => 'Villaurrutia',
        WritingTheme.davila => 'Dávila',
        WritingTheme.sepia => 'Sepia',
        WritingTheme.forest => 'Bosque',
        WritingTheme.midnight => 'Noche',
      };
}

@freezed
abstract class AppSettings with _$AppSettings {
  const factory AppSettings({
    @Default(ThemeMode.system) ThemeMode themeMode,
    @Default(EditorFont.merriweather) EditorFont editorFont,
    @Default(17.0) double editorFontSize,
    @Default(1.6) double editorLineHeight,
    // Max content column width in logical pixels; null = full width
    @Default(680.0) double? editorColumnWidth,
    @Default(WritingTheme.default_) WritingTheme writingTheme,
    @Default(500) int dailyWordTarget,
    @Default(true) bool typographicQuotes,
    @Default(true) bool autocorrect,
    @Default(false) bool typewriterMode,
    @Default(true) bool showWordCount,
    // Daily writing reminder (local notification).
    @Default(false) bool reminderEnabled,
    // Time of day for the reminder, "HH:mm" (24h).
    @Default('20:00') String reminderTime,
  }) = _AppSettings;

  const AppSettings._();

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);

  /// Hour component (0–23) of [reminderTime]; falls back to 20 if malformed.
  int get reminderHour => int.tryParse(reminderTime.split(':').first) ?? 20;

  /// Minute component (0–59) of [reminderTime]; falls back to 0 if malformed.
  int get reminderMinute {
    final parts = reminderTime.split(':');
    return parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  }
}
