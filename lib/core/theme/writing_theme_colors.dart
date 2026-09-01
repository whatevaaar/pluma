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
    required this.cursor,
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
              cursor: AppColors.accentDark,
            )
          : const WritingThemeColors(
              background: AppColors.surfaceLight,
              onBackground: AppColors.onSurfaceLight,
              appBarBackground: AppColors.surfaceLight,
              cursor: AppColors.accent,
            ),

      // Shakespeare — aged vellum and venetian-red ink. Elizabethan, classic.
      WritingTheme.shakespeare => const WritingThemeColors(
          background: Color(0xFFECE3CE),
          onBackground: Color(0xFF3A2E24),
          appBarBackground: Color(0xFFE1D5BB),
          cursor: Color(0xFF9B2D20),
        ),

      // Xavier Villaurrutia — "Nostalgia de la muerte". A nocturne in blue:
      // near-black midnight blue with pale moonlight text.
      WritingTheme.villaurrutia => const WritingThemeColors(
          background: Color(0xFF0F1320),
          onBackground: Color(0xFFC6CADF),
          appBarBackground: Color(0xFF161B2E),
          cursor: Color(0xFF8A9BF0),
        ),

      // Amparo Dávila — unsettling gothic tales. Plum-black penumbra with a
      // faded rose-grey text and a muted crimson caret.
      WritingTheme.davila => const WritingThemeColors(
          background: Color(0xFF1A1416),
          onBackground: Color(0xFFD7C9CE),
          appBarBackground: Color(0xFF241A1D),
          cursor: Color(0xFFC05867),
        ),

      // Warm parchment — best for daylight reading
      WritingTheme.sepia => const WritingThemeColors(
          background: Color(0xFFF5ECD7),
          onBackground: Color(0xFF4A3728),
          appBarBackground: Color(0xFFEDE0C4),
          cursor: Color(0xFFA6572E),
        ),

      // Dark evergreen — easy on eyes in dim lighting
      WritingTheme.forest => const WritingThemeColors(
          background: Color(0xFF1A2B1A),
          onBackground: Color(0xFFCEE5C8),
          appBarBackground: Color(0xFF1F3520),
          cursor: Color(0xFF88D07E),
        ),

      // Near-black with blue-grey text — classic dark theme for writers
      WritingTheme.midnight => const WritingThemeColors(
          background: Color(0xFF0D1117),
          onBackground: Color(0xFFC9D1D9),
          appBarBackground: Color(0xFF161B22),
          cursor: Color(0xFF58A6FF),
        ),
    };
  }

  final Color background;
  final Color onBackground;
  final Color appBarBackground;

  /// Caret / text-selection accent. Chosen per palette for strong contrast
  /// against [background] so the insertion point is always clearly visible.
  final Color cursor;

  /// Translucent selection highlight derived from [cursor].
  Color get selection => cursor.withValues(alpha: 0.28);
}
