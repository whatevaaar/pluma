import 'package:flutter/material.dart';

/// Typography tokens.
///
/// Merriweather (serif) for the writing surface — optimized for long-form
/// reading. Inter (sans-serif) for all UI chrome (labels, buttons, nav).
abstract final class AppTextStyles {
  // --- Editor / reading surface (Merriweather) ---

  static const TextStyle editorBody = TextStyle(
    fontFamily: 'Merriweather',
    fontSize: 17,
    height: 1.75,
    letterSpacing: 0.1,
  );

  static const TextStyle editorBodySmall = TextStyle(
    fontFamily: 'Merriweather',
    fontSize: 15,
    height: 1.7,
  );

  static const TextStyle editorBodyLarge = TextStyle(
    fontFamily: 'Merriweather',
    fontSize: 20,
    height: 1.8,
  );

  // --- UI chrome (Inter) ---

  static const TextStyle uiHeadline = TextStyle(
    fontFamily: 'Inter',
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
  );

  static const TextStyle uiTitle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );

  static const TextStyle uiBody = TextStyle(
    fontFamily: 'Inter',
    fontSize: 15,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle uiCaption = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
  );

  static const TextStyle uiLabel = TextStyle(
    fontFamily: 'Inter',
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );

  static const TextStyle uiButton = TextStyle(
    fontFamily: 'Inter',
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  // --- Document list tile ---

  static const TextStyle documentTitle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
  );

  static const TextStyle documentSubtitle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle wordCountBadge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
  );
}
