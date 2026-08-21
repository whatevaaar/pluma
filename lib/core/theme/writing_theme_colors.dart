import 'package:flutter/material.dart';
import 'package:pluma/core/theme/app_colors.dart';
import 'package:pluma/features/settings/domain/app_settings.dart';

/// Surface colors that define each writing theme.
///
/// These are applied inside `EditorScreen` only — the rest of the app
/// continues using the global Material [ThemeData].
class WritingThemeColors {
  const WritingThemeColors({
    required this.background,
    required this.onBackground,
    required this.appBarBackground,
  });

  factory WritingThemeColors.resolve(
    WritingTheme theme,
    Brightness brightness,
  ) {
    return switch (theme) {
      WritingTheme.default_ => brightness == Brightness.dark
          ? const WritingThemeColors(
              background: AppColors.surfaceDark,
              onBackground: AppColors.onSurfaceDark,
              appBarBackground: AppColors.surfaceDark,
            )
          : const WritingThemeColors(
              background: AppColors.surfaceLight,
              onBackground: AppColors.onSurfaceLight,
              appBarBackground: AppColors.surfaceLight,
            ),

      // Warm parchment — best for daylight reading
      WritingTheme.sepia => const WritingThemeColors(
          background: Color(0xFFF5ECD7),
          onBackground: Color(0xFF4A3728),
          appBarBackground: Color(0xFFEDE0C4),
        ),

      // Dark evergreen — easy on eyes in dim lighting
      WritingTheme.forest => const WritingThemeColors(
          background: Color(0xFF1A2B1A),
          onBackground: Color(0xFFCEE5C8),
          appBarBackground: Color(0xFF1F3520),
        ),

      // Near-black with blue-grey text — classic dark theme for writers
      WritingTheme.midnight => const WritingThemeColors(
          background: Color(0xFF0D1117),
          onBackground: Color(0xFFC9D1D9),
          appBarBackground: Color(0xFF161B22),
        ),
    };
  }

  final Color background;
  final Color onBackground;
  final Color appBarBackground;
}
