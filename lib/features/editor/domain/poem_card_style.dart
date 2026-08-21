import 'package:flutter/material.dart';

/// A background option for a Poem Card: either a solid color (one entry in
/// [colors]) or a top-left→bottom-right gradient (two entries), paired with
/// legible text/title colors.
class CardBackground {
  const CardBackground({
    required this.name,
    required this.colors,
    required this.textColor,
    Color? titleColor,
  }) : titleColor = titleColor ?? textColor;

  final String name;
  final List<Color> colors;
  final Color textColor;
  final Color titleColor;

  bool get isGradient => colors.length > 1;

  /// The swatch/preview color (first stop).
  Color get seed => colors.first;

  /// Paints this background onto a [BoxDecoration].
  BoxDecoration get decoration => isGradient
      ? BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        )
      : BoxDecoration(color: colors.first);
}

/// Curated, poem-friendly backgrounds (tuned for sharing, not for reading).
const List<CardBackground> kCardBackgrounds = [
  CardBackground(
    name: 'Crema',
    colors: [Color(0xFFF6EFE1)],
    textColor: Color(0xFF2E2A22),
    titleColor: Color(0xFF4A3B27),
  ),
  CardBackground(
    name: 'Carbón',
    colors: [Color(0xFF141319)],
    textColor: Color(0xFFE9E7DF),
    titleColor: Color(0xFFFFFFFF),
  ),
  CardBackground(
    name: 'Salvia',
    colors: [Color(0xFFDCE6DA)],
    textColor: Color(0xFF2B3A2E),
  ),
  CardBackground(
    name: 'Durazno',
    colors: [Color(0xFFF7E0D2)],
    textColor: Color(0xFF4A2E22),
  ),
  CardBackground(
    name: 'Índigo',
    colors: [Color(0xFF4C63C7), Color(0xFF7B96F5)],
    textColor: Color(0xFFFFFFFF),
  ),
  CardBackground(
    name: 'Atardecer',
    colors: [Color(0xFFF6C79B), Color(0xFFE07A9B)],
    textColor: Color(0xFF3A1F2E),
  ),
  CardBackground(
    name: 'Noche',
    colors: [Color(0xFF1A2B4A), Color(0xFF0D1117)],
    textColor: Color(0xFFC9D6EA),
    titleColor: Color(0xFFFFFFFF),
  ),
  CardBackground(
    name: 'Bosque',
    colors: [Color(0xFF1F3520)],
    textColor: Color(0xFFCEE5C8),
  ),
];

/// Output aspect ratios for a Poem Card (width / height).
enum CardAspect {
  portrait45('4:5', 4 / 5),
  square11('1:1', 1),
  story916('9:16', 9 / 16);

  const CardAspect(this.label, this.ratio);

  final String label;
  final double ratio;
}
