import 'package:flutter/material.dart';

/// Semantic color tokens for Pluma.
///
/// Warm neutrals in light mode; near-black (not pure grey) in dark mode.
/// All UI components reference these tokens — never raw Color literals.
abstract final class AppColors {
  // --- Brand ---
  static const ink = Color(0xFF1A1A2E);
  static const inkLight = Color(0xFF2D2D44);

  // --- Light mode surfaces ---
  static const surfaceLight = Color(0xFFFAF9F7);   // warm white
  static const surfaceVariantLight = Color(0xFFF0EDE8);
  static const onSurfaceLight = Color(0xFF1C1B1A);
  static const onSurfaceVariantLight = Color(0xFF4A4743);

  // --- Dark mode surfaces ---
  // Near-black with a warm undertone — avoids the coldness of #000000
  static const surfaceDark = Color(0xFF0F0F0F);
  static const surfaceVariantDark = Color(0xFF1C1C1C);
  static const onSurfaceDark = Color(0xFFECE9E4);
  static const onSurfaceVariantDark = Color(0xFFA09C97);

  // --- Accent ---
  static const accent = Color(0xFF5C7AEA);
  static const accentDark = Color(0xFF7B96F5);

  // --- Semantic ---
  static const error = Color(0xFFB3261E);
  static const errorDark = Color(0xFFF2B8B5);
  static const success = Color(0xFF2E7D32);
  static const successDark = Color(0xFF81C784);

  // --- Heatmap (GitHub-style contribution graph) ---
  static const heatmap0 = Color(0xFFE8E4DF);   // no activity
  static const heatmap1 = Color(0xFFC6E48B);   // 1–99 words
  static const heatmap2 = Color(0xFF7BC96F);   // 100–499 words
  static const heatmap3 = Color(0xFF239A3B);   // 500+ words

  static const heatmap0Dark = Color(0xFF2D2D2D);
  static const heatmap1Dark = Color(0xFF0E4429);
  static const heatmap2Dark = Color(0xFF006D32);
  static const heatmap3Dark = Color(0xFF26A641);
}
