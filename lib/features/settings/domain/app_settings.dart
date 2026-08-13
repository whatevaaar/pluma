import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_settings.freezed.dart';
part 'app_settings.g.dart';

enum EditorFont { merriweather, georgia, jetbrainsMono }

enum WritingTheme { default_, sepia, forest, midnight }

@freezed
class AppSettings with _$AppSettings {
  const factory AppSettings({
    @Default(ThemeMode.system) ThemeMode themeMode,
    @Default(EditorFont.merriweather) EditorFont editorFont,
    @Default(17.0) double editorFontSize,
    @Default(1.75) double editorLineHeight,
    // Max content column width in logical pixels; null = full width
    @Default(680.0) double? editorColumnWidth,
    @Default(WritingTheme.default_) WritingTheme writingTheme,
    @Default(500) int dailyWordTarget,
    @Default(true) bool typographicQuotes,
    @Default(true) bool autocorrect,
    @Default(false) bool typwriterMode,
    @Default(true) bool showWordCount,
  }) = _AppSettings;

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);
}
