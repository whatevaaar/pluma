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

  /// Short evocative descriptor shown under the theme name.
  String get tagline => switch (this) {
        WritingTheme.default_ => 'Limpio y neutro',
        WritingTheme.shakespeare => 'Vitela y tinta',
        WritingTheme.villaurrutia => 'Nocturno de azul',
        WritingTheme.davila => 'Penumbra inquietante',
        WritingTheme.sepia => 'Pergamino cálido',
        WritingTheme.forest => 'Bosque profundo',
        WritingTheme.midnight => 'Medianoche',
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
  }) = _AppSettings;

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);
}
