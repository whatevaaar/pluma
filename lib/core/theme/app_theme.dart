import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pluma/core/theme/app_colors.dart';
import 'package:pluma/core/theme/app_text_styles.dart';
import 'package:pluma/features/settings/domain/app_settings.dart';

/// Builds Material 3 ThemeData for light and dark modes.
///
/// All surfaces reference AppColors tokens — no raw Color literals here.
abstract final class AppTheme {
  static ThemeData light(AppSettings settings) => _build(
        brightness: Brightness.light,
        surface: AppColors.surfaceLight,
        surfaceVariant: AppColors.surfaceVariantLight,
        onSurface: AppColors.onSurfaceLight,
        onSurfaceVariant: AppColors.onSurfaceVariantLight,
        accent: AppColors.accent,
        error: AppColors.error,
        settings: settings,
      );

  static ThemeData dark(AppSettings settings) => _build(
        brightness: Brightness.dark,
        surface: AppColors.surfaceDark,
        surfaceVariant: AppColors.surfaceVariantDark,
        onSurface: AppColors.onSurfaceDark,
        onSurfaceVariant: AppColors.onSurfaceVariantDark,
        accent: AppColors.accentDark,
        error: AppColors.errorDark,
        settings: settings,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color surface,
    required Color surfaceVariant,
    required Color onSurface,
    required Color onSurfaceVariant,
    required Color accent,
    required Color error,
    required AppSettings settings,
  }) {
    final isDark = brightness == Brightness.dark;
    final systemUiOverlayStyle = isDark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: accent,
        onPrimary: Colors.white,
        primaryContainer: accent.withAlpha(30),
        onPrimaryContainer: onSurface,
        secondary: accent,
        onSecondary: Colors.white,
        secondaryContainer: surfaceVariant,
        onSecondaryContainer: onSurface,
        error: error,
        onError: Colors.white,
        surface: surface,
        onSurface: onSurface,
        surfaceContainerHighest: surfaceVariant,
        onSurfaceVariant: onSurfaceVariant,
        outline: onSurfaceVariant.withAlpha(80),
        outlineVariant: onSurfaceVariant.withAlpha(40),
        shadow: Colors.black.withAlpha(20),
        scrim: Colors.black.withAlpha(80),
        inverseSurface: onSurface,
        onInverseSurface: surface,
        inversePrimary: accent,
      ),
      scaffoldBackgroundColor: surface,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        systemOverlayStyle: systemUiOverlayStyle,
        titleTextStyle: AppTextStyles.uiTitle.copyWith(color: onSurface),
      ),
      textTheme: _buildTextTheme(onSurface, onSurfaceVariant, settings),
      cardTheme: CardThemeData(
        color: surfaceVariant,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(
        color: onSurfaceVariant.withAlpha(40),
        thickness: 0.5,
        space: 0,
      ),
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        selectedTileColor: accent.withAlpha(15),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  static TextTheme _buildTextTheme(
    Color onSurface,
    Color onSurfaceVariant,
    AppSettings settings,
  ) {
    // UI chrome always uses Inter; editor font is per-user in settings
    return TextTheme(
      headlineLarge: AppTextStyles.uiHeadline.copyWith(color: onSurface),
      headlineMedium: AppTextStyles.uiHeadline.copyWith(
        color: onSurface,
        fontSize: 20,
      ),
      titleLarge: AppTextStyles.uiTitle.copyWith(color: onSurface),
      titleMedium: AppTextStyles.uiTitle.copyWith(
        color: onSurface,
        fontSize: 15,
      ),
      bodyLarge: AppTextStyles.uiBody.copyWith(color: onSurface),
      bodyMedium: AppTextStyles.uiBody.copyWith(color: onSurfaceVariant),
      bodySmall: AppTextStyles.uiCaption.copyWith(color: onSurfaceVariant),
      labelLarge: AppTextStyles.uiLabel.copyWith(color: onSurface),
      labelMedium: AppTextStyles.uiLabel.copyWith(color: onSurfaceVariant),
      labelSmall: AppTextStyles.wordCountBadge.copyWith(
        color: onSurfaceVariant,
      ),
    );
  }
}
