import 'package:flutter/material.dart';
import 'package:pluma/core/theme/app_colors.dart';
import 'package:pluma/features/settings/domain/app_settings.dart';

/// A complete surface palette for a writing theme.
///
/// This is the single source of truth for a theme's colors. It drives both the
/// editor writing surface AND — via `AppTheme.forWriting` — the whole app's
/// Material `ThemeData` when a non-default theme is selected.
class WritingThemeColors {
  const WritingThemeColors({
    required this.brightness,
    required this.background,
    required this.onBackground,
    required this.onBackgroundVariant,
    required this.appBarBackground,
    required this.surfaceVariant,
    required this.accent,
    required this.cursor,
  });

  factory WritingThemeColors.resolve(
    WritingTheme theme,
    Brightness brightness,
  ) {
    return switch (theme) {
      WritingTheme.default_ => brightness == Brightness.dark
          ? const WritingThemeColors(
              brightness: Brightness.dark,
              background: AppColors.surfaceDark,
              onBackground: AppColors.onSurfaceDark,
              onBackgroundVariant: AppColors.onSurfaceVariantDark,
              appBarBackground: AppColors.surfaceDark,
              surfaceVariant: AppColors.surfaceVariantDark,
              accent: AppColors.accentDark,
              cursor: AppColors.accentDark,
            )
          : const WritingThemeColors(
              brightness: Brightness.light,
              background: AppColors.surfaceLight,
              onBackground: AppColors.onSurfaceLight,
              onBackgroundVariant: AppColors.onSurfaceVariantLight,
              appBarBackground: AppColors.surfaceLight,
              surfaceVariant: AppColors.surfaceVariantLight,
              accent: AppColors.accent,
              cursor: AppColors.accent,
            ),

      // Shakespeare — aged vellum and venetian-red ink. Elizabethan, classic.
      WritingTheme.shakespeare => const WritingThemeColors(
          brightness: Brightness.light,
          background: Color(0xFFECE3CE),
          onBackground: Color(0xFF3A2E24),
          onBackgroundVariant: Color(0xFF6B5A48),
          appBarBackground: Color(0xFFE1D5BB),
          surfaceVariant: Color(0xFFE4D9C0),
          accent: Color(0xFF9B2D20),
          cursor: Color(0xFF9B2D20),
        ),

      // Xavier Villaurrutia — "Nostalgia de la muerte". A nocturne in blue:
      // near-black midnight blue with pale moonlight text.
      WritingTheme.villaurrutia => const WritingThemeColors(
          brightness: Brightness.dark,
          background: Color(0xFF0F1320),
          onBackground: Color(0xFFC6CADF),
          onBackgroundVariant: Color(0xFF8990A8),
          appBarBackground: Color(0xFF161B2E),
          surfaceVariant: Color(0xFF1B2136),
          accent: Color(0xFF8A9BF0),
          cursor: Color(0xFF8A9BF0),
        ),

      // Amparo Dávila — unsettling gothic tales. Plum-black penumbra with a
      // faded rose-grey text and a muted crimson accent.
      WritingTheme.davila => const WritingThemeColors(
          brightness: Brightness.dark,
          background: Color(0xFF1A1416),
          onBackground: Color(0xFFD7C9CE),
          onBackgroundVariant: Color(0xFF9A8B90),
          appBarBackground: Color(0xFF241A1D),
          surfaceVariant: Color(0xFF2A2023),
          accent: Color(0xFFC05867),
          cursor: Color(0xFFC05867),
        ),

      // Warm parchment — best for daylight reading
      WritingTheme.sepia => const WritingThemeColors(
          brightness: Brightness.light,
          background: Color(0xFFF5ECD7),
          onBackground: Color(0xFF4A3728),
          onBackgroundVariant: Color(0xFF7A6B54),
          appBarBackground: Color(0xFFEDE0C4),
          surfaceVariant: Color(0xFFEDE0C4),
          accent: Color(0xFFA6572E),
          cursor: Color(0xFFA6572E),
        ),

      // Dark evergreen — easy on eyes in dim lighting
      WritingTheme.forest => const WritingThemeColors(
          brightness: Brightness.dark,
          background: Color(0xFF1A2B1A),
          onBackground: Color(0xFFCEE5C8),
          onBackgroundVariant: Color(0xFF8FA889),
          appBarBackground: Color(0xFF1F3520),
          surfaceVariant: Color(0xFF223A22),
          accent: Color(0xFF88D07E),
          cursor: Color(0xFF88D07E),
        ),

      // Near-black with blue-grey text — classic dark theme for writers
      WritingTheme.midnight => const WritingThemeColors(
          brightness: Brightness.dark,
          background: Color(0xFF0D1117),
          onBackground: Color(0xFFC9D1D9),
          onBackgroundVariant: Color(0xFF8B949E),
          appBarBackground: Color(0xFF161B22),
          surfaceVariant: Color(0xFF161B22),
          accent: Color(0xFF58A6FF),
          cursor: Color(0xFF58A6FF),
        ),
    };
  }

  /// The inherent brightness of this palette. Named palettes are fixed; only
  /// [WritingTheme.default_] varies with the user's light/dark preference.
  final Brightness brightness;

  final Color background;
  final Color onBackground;

  /// Muted text tone for secondary labels (maps to `onSurfaceVariant`).
  final Color onBackgroundVariant;

  final Color appBarBackground;

  /// Card / input fill, slightly offset from [background].
  final Color surfaceVariant;

  /// Primary accent for buttons, FAB, selection controls.
  final Color accent;

  /// Caret color — chosen per palette for strong contrast against
  /// [background] so the insertion point is always clearly visible.
  final Color cursor;

  /// Translucent selection highlight derived from [cursor].
  Color get selection => cursor.withValues(alpha: 0.28);
}
